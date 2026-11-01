#include "backend_bridge.h"

#include <algorithm>
#include <cmath>
#include <random>
#include <string>
#include <utility>

#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileDialog>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QSettings>
#include <QStandardPaths>
#include <QVariantMap>

#include "xieqian/core/io/file_parser.h"

namespace {

constexpr int kMinDrawCount = 1;
constexpr int kMaxDrawCount = 10;

std::mt19937_64 seededGenerator()
{
    std::random_device device;
    std::seed_seq seed{device(), device(), device(), device()};
    return std::mt19937_64(seed);
}

bool hasStateArrays(const QJsonObject &root)
{
    return root.value(QStringLiteral("roster")).isArray() &&
           root.value(QStringLiteral("history")).isArray();
}

bool writeJsonFile(const QString &path, const QJsonObject &state)
{
    QDir().mkpath(QFileInfo(path).absolutePath());

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qWarning() << "cannot write JSON file:" << path;
        return false;
    }

    return file.write(QJsonDocument(state).toJson(QJsonDocument::Indented)) >= 0;
}

}  // namespace

BackendBridge::BackendBridge(QObject *parent)
    : QObject(parent),
      roster_(std::make_shared<xieqian::core::Roster>()),
      drawEngine_(std::make_unique<xieqian::core::DrawEngine>(seededGenerator())),
      aiManager_(std::make_unique<AiManager>())
{
    loadState();
    aiManager_->setApiConfig(aiApiKey_, aiBaseUrl_, aiModel_);
}

void BackendBridge::loadState()
{
    const QString path = dataFilePath();
    QFile file(path);
    if (!file.exists()) {
        return;
    }

    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "cannot read state file:" << path;
        return;
    }

    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    file.close();

    if (document.isNull() || !document.isObject() || !hasStateArrays(document.object())) {
        qWarning() << "state file is corrupted or malformed:" << path;

        const QString backupPath =
            QFileInfo(path).absoluteDir().filePath(QStringLiteral("data_corrupted.json"));
        if (QFile::exists(backupPath) && !QFile::remove(backupPath)) {
            qWarning() << "cannot replace previous corrupted backup:" << backupPath;
            return;
        }
        if (!QFile::rename(path, backupPath)) {
            qWarning() << "cannot back up corrupted state file to:" << backupPath;
            return;
        }

        qWarning() << "corrupted state file backed up to:" << backupPath;
        return;
    }

    applyData(document.object());
}

QString BackendBridge::drawWinner()
{
    const std::vector<xieqian::core::Participant> winners =
        drawEngine_->draw(roster_->enabledParticipants(), 1, effectiveStrategy());
    if (winners.empty()) {
        return QStringLiteral("无可用名单");
    }

    recordWinners(winners);
    const QString name = QString::fromStdString(winners.front().name);
    recordDraw(name);
    emit winnerDrawn(name, static_cast<int>(currentDrawMode_));
    return name;
}

QVariantList BackendBridge::drawWinners(int count)
{
    QVariantList winners;
    if (count <= 0) {
        return winners;
    }

    const std::vector<xieqian::core::Participant> picked =
        drawEngine_->draw(roster_->enabledParticipants(), count, effectiveStrategy());
    recordWinners(picked);
    for (const xieqian::core::Participant &participant : picked) {
        const QString winner = QString::fromStdString(participant.name);
        recordDraw(winner);
        winners.append(winner);
    }
    return winners;
}

QVariantList BackendBridge::drawMultipleWinners()
{
    QVariantList winners;
    QStringList names;

    const std::vector<xieqian::core::Participant> picked =
        drawEngine_->draw(roster_->enabledParticipants(), drawCount_, effectiveStrategy());
    recordWinners(picked);
    for (const xieqian::core::Participant &participant : picked) {
        const QString name = QString::fromStdString(participant.name);
        recordDraw(name);
        names.append(name);
        winners.append(name);
    }

    if (!names.isEmpty()) {
        emit winnersDrawn(names, static_cast<int>(currentDrawMode_));
    }
    return winners;
}

void BackendBridge::applyMockRoster(const QVariantList &roster)
{
    if (roster.isEmpty()) {
        return;
    }

    roster_->clear();
    for (const QVariant &value : roster) {
        const QVariantMap entry = value.toMap();
        const QString name = entry.value(QStringLiteral("name")).toString().trimmed();
        if (name.isEmpty()) {
            continue;
        }

        xieqian::core::Participant participant;
        participant.name = name.toStdString();
        participant.studentId = entry.value(QStringLiteral("id")).toString().trimmed().toStdString();
        roster_->add(std::move(participant));
    }

    drawEngine_->clearDrawnHistory();
    saveState();
    emit rosterUpdated();
}

void BackendBridge::updateDrawSettings(int count, int strategy)
{
    if (strategy < static_cast<int>(xieqian::core::DrawStrategy::Random) ||
        strategy > static_cast<int>(xieqian::core::DrawStrategy::Weighted)) {
        return;
    }

    const int nextCount = std::clamp(count, kMinDrawCount, kMaxDrawCount);
    const auto nextStrategy = static_cast<xieqian::core::DrawStrategy>(strategy);

    if (drawCount_ == nextCount && drawStrategy_ == nextStrategy) {
        return;
    }

    drawCount_ = nextCount;
    drawStrategy_ = nextStrategy;
    emit drawSettingsChanged();
}

QString BackendBridge::chooseRosterFilePath()
{
    return QFileDialog::getOpenFileName(
        nullptr, QStringLiteral("选择名单文件"), QString(),
        QStringLiteral("名单文件 (*.csv *.txt);;CSV 文件 (*.csv);;文本文件 (*.txt)"));
}

QStringList BackendBridge::readNamesFromFile(const QString &filePath)
{
    QStringList names;
    if (filePath.isEmpty()) {
        return names;
    }

    xieqian::core::Roster parsed;
    xieqian::core::FileParser parser;
    if (!parser.parseFile(QFile::encodeName(filePath).toStdString(), parsed)) {
        qWarning() << "cannot parse roster file:" << filePath;
        return names;
    }

    for (std::size_t index = 0; index < parsed.size(); ++index) {
        const QString name = QString::fromStdString(parsed.at(index).name).trimmed();
        if (!name.isEmpty() && !names.contains(name)) {
            names.append(name);
        }
    }
    return names;
}

QString BackendBridge::chooseRosterImagePath()
{
    return QFileDialog::getOpenFileName(nullptr, QStringLiteral("选择名单图片"), QString(),
                                        QStringLiteral("图片文件 (*.png *.jpg *.jpeg)"));
}

int BackendBridge::appendNamesToRoster(const QStringList &names)
{
    int added = 0;
    for (const QString &raw : names) {
        const QString name = raw.trimmed();
        if (name.isEmpty()) {
            continue;
        }

        // 名单内按姓名去重：同一个名字重复参与只会让权重失真
        bool exists = false;
        for (std::size_t index = 0; index < roster_->size(); ++index) {
            if (QString::fromStdString(roster_->at(index).name) == name) {
                exists = true;
                break;
            }
        }
        if (exists) {
            continue;
        }

        xieqian::core::Participant participant;
        participant.name = name.toStdString();
        roster_->add(std::move(participant));
        ++added;
    }

    if (added > 0) {
        saveState();
        emit rosterUpdated();
    }
    return added;
}

int BackendBridge::applyScoreWeights(const QVariantList &entries)
{
    struct ScoreEntry {
        QString name;
        double score = 0.0;
    };

    std::vector<ScoreEntry> scored;
    for (const QVariant &value : entries) {
        const QVariantMap entry = value.toMap();
        const QString name = entry.value(QStringLiteral("name")).toString().trimmed();
        const double score = entry.value(QStringLiteral("score")).toDouble();
        if (name.isEmpty() || !std::isfinite(score)) {
            continue;
        }
        scored.push_back(ScoreEntry{name, score});
    }

    if (scored.empty()) {
        return 0;
    }

    std::sort(scored.begin(), scored.end(), [](const ScoreEntry &left, const ScoreEntry &right) {
        return left.score > right.score;
    });

    int updated = 0;
    for (std::size_t rank = 0; rank < scored.size(); ++rank) {
        // 按名次线性分配：最高分 5.0，最低分 0.5；只有一人时直接给满权重
        const double ratio = scored.size() > 1
                                 ? static_cast<double>(rank) /
                                       static_cast<double>(scored.size() - 1)
                                 : 0.0;
        const double weight = 5.0 - 4.5 * ratio;

        for (std::size_t index = 0; index < roster_->size(); ++index) {
            if (QString::fromStdString(roster_->at(index).name) == scored[rank].name) {
                roster_->setWeight(index, weight);
                ++updated;
                break;
            }
        }
    }

    if (updated > 0) {
        saveState();
        emit rosterUpdated();
    }
    return updated;
}

QVariantList BackendBridge::getParticipantsWithStatus()
{
    QVariantList participants;
    for (std::size_t index = 0; index < roster_->size(); ++index) {
        const xieqian::core::Participant &participant = roster_->at(index);

        QVariantMap entry;
        entry.insert(QStringLiteral("index"), static_cast<int>(index));
        entry.insert(QStringLiteral("id"),
                     QString::fromStdString(xieqian::core::participantId(participant)));
        entry.insert(QStringLiteral("name"), QString::fromStdString(participant.name));
        entry.insert(QStringLiteral("studentId"), QString::fromStdString(participant.studentId));
        entry.insert(QStringLiteral("group"), QString::fromStdString(participant.group));
        entry.insert(QStringLiteral("enabled"), participant.enabled);
        entry.insert(QStringLiteral("weight"), participant.weight);
        entry.insert(QStringLiteral("drawCount"), participant.drawCount);
        entry.insert(QStringLiteral("streak"), participant.streak);
        entry.insert(QStringLiteral("isDrawn"), drawEngine_->isDrawn(participant));
        participants.append(entry);
    }
    return participants;
}

void BackendBridge::toggleParticipantStatus(int index)
{
    if (index < 0 || static_cast<std::size_t>(index) >= roster_->size()) {
        return;
    }

    const auto position = static_cast<std::size_t>(index);
    roster_->setEnabled(position, !roster_->at(position).enabled);
    saveState();
    emit rosterUpdated();
}

void BackendBridge::updateParticipantWeight(const QString &id, double weight)
{
    if (id.isEmpty() || !std::isfinite(weight) || weight <= 0.0) {
        return;
    }

    const std::string key = id.toStdString();
    for (std::size_t index = 0; index < roster_->size(); ++index) {
        if (xieqian::core::participantId(roster_->at(index)) == key) {
            roster_->setWeight(index, weight);
            saveState();
            emit rosterUpdated();
            return;
        }
    }
}

bool BackendBridge::removeParticipant(const QString &id)
{
    if (id.isEmpty()) {
        return false;
    }

    const std::string key = id.toStdString();
    for (std::size_t index = 0; index < roster_->size(); ++index) {
        if (xieqian::core::participantId(roster_->at(index)) == key) {
            roster_->removeAt(index);
            saveState();
            emit rosterUpdated();
            return true;
        }
    }
    return false;
}

bool BackendBridge::saveCustomWheel(const QString &name, const QVariantList &options)
{
    const QString wheelName = name.trimmed();
    if (wheelName.isEmpty()) {
        return false;
    }

    QStringList wheelOptions;
    for (const QVariant &value : options) {
        const QString option = value.toString().trimmed();
        if (!option.isEmpty() && !wheelOptions.contains(option)) {
            wheelOptions.append(option);
        }
    }

    if (wheelOptions.size() < 2) {
        return false;
    }

    const auto existing = std::find_if(customWheels_.begin(), customWheels_.end(),
                                       [&wheelName](const CustomWheel &wheel) {
                                           return wheel.name == wheelName;
                                       });
    if (existing != customWheels_.end()) {
        existing->options = wheelOptions;
    } else {
        customWheels_.push_back(CustomWheel{wheelName, wheelOptions});
    }

    activeWheelName_ = wheelName;
    saveState();
    emit customWheelsChanged();
    return true;
}

bool BackendBridge::removeCustomWheel(const QString &name)
{
    const QString wheelName = name.trimmed();
    if (wheelName.isEmpty()) {
        return false;
    }

    const auto wheel = std::find_if(customWheels_.begin(), customWheels_.end(),
                                    [&wheelName](const CustomWheel &entry) {
                                        return entry.name == wheelName;
                                    });
    if (wheel == customWheels_.end()) {
        return false;
    }

    customWheels_.erase(wheel);
    if (activeWheelName_ == wheelName) {
        activeWheelName_ = customWheels_.empty() ? QString() : customWheels_.back().name;
    }

    saveState();
    emit customWheelsChanged();
    return true;
}

QVariantMap BackendBridge::getCustomWheel()
{
    for (const CustomWheel &wheel : customWheels_) {
        if (wheel.name != activeWheelName_) {
            continue;
        }

        QVariantMap entry;
        entry.insert(QStringLiteral("name"), wheel.name);
        entry.insert(QStringLiteral("options"), wheel.options);
        return entry;
    }

    return {};
}

QVariantList BackendBridge::customWheels() const
{
    QVariantList wheels;
    for (const CustomWheel &wheel : customWheels_) {
        QVariantList options;
        for (const QString &option : wheel.options) {
            options.append(option);
        }

        QVariantMap entry;
        entry.insert(QStringLiteral("name"), wheel.name);
        entry.insert(QStringLiteral("options"), options);
        wheels.append(entry);
    }
    return wheels;
}

void BackendBridge::resetDrawStats()
{
    drawEngine_->clearDrawnHistory();
    roster_->resetDrawStats();
    saveState();
    emit rosterUpdated();
}

void BackendBridge::recordWinners(const std::vector<xieqian::core::Participant> &winners)
{
    if (winners.empty() || !dynamicWeights_) {
        return;
    }

    std::vector<std::string> ids;
    ids.reserve(winners.size());
    for (const xieqian::core::Participant &winner : winners) {
        ids.push_back(xieqian::core::participantId(winner));
    }

    roster_->recordWins(ids);
    saveState();
    emit rosterUpdated();
}

xieqian::core::DrawStrategy BackendBridge::effectiveStrategy() const
{
    // 动态权重只在加权抽签下有意义，开启后自动接管抽签策略
    return dynamicWeights_ ? xieqian::core::DrawStrategy::Weighted : drawStrategy_;
}

bool BackendBridge::dynamicWeights() const
{
    return dynamicWeights_;
}

void BackendBridge::setDynamicWeights(bool enabled)
{
    if (dynamicWeights_ == enabled) {
        return;
    }

    dynamicWeights_ = enabled;
    drawEngine_->setDynamicWeights(enabled);
    saveState();
    emit dynamicWeightsChanged();
}

QVariantList BackendBridge::getHistory()
{
    QVariantList history;
    for (auto entry = history_.rbegin(); entry != history_.rend(); ++entry) {
        QVariantMap record;
        record.insert(QStringLiteral("name"), entry->name);
        record.insert(QStringLiteral("time"), entry->time);
        history.append(record);
    }
    return history;
}

void BackendBridge::clearHistory()
{
    if (history_.empty()) {
        return;
    }

    history_.clear();
    saveState();
    emit historyUpdated();
}

void BackendBridge::clearAllData()
{
    roster_->clear();
    history_.clear();
    customWheels_.clear();
    activeWheelName_.clear();
    lastSelectedWheel_.clear();
    aiApiKey_.clear();
    aiBaseUrl_.clear();
    aiModel_.clear();
    aiManager_->setApiConfig(aiApiKey_, aiBaseUrl_, aiModel_);
    drawEngine_->clearDrawnHistory();

    saveState();
    emit rosterUpdated();
    emit historyUpdated();
    emit customWheelsChanged();
    emit aiConfigChanged();
}

void BackendBridge::saveAIConfig(const QString &apiKey, const QString &baseUrl, const QString &model)
{
    aiApiKey_ = apiKey.trimmed();
    aiBaseUrl_ = baseUrl.trimmed();
    aiModel_ = model.trimmed();
    aiManager_->setApiConfig(aiApiKey_, aiBaseUrl_, aiModel_);
    saveState();
    emit aiConfigChanged();
}

QVariantMap BackendBridge::getAIConfig()
{
    QVariantMap config;
    config.insert(QStringLiteral("apiKey"), aiApiKey_);
    config.insert(QStringLiteral("baseUrl"), aiBaseUrl_);
    config.insert(QStringLiteral("model"), aiModel_);
    return config;
}

QString BackendBridge::lastSelectedWheel() const
{
    return lastSelectedWheel_;
}

void BackendBridge::setLastSelectedWheel(const QString &name)
{
    const QString key = name.trimmed();
    if (lastSelectedWheel_ == key) {
        return;
    }

    lastSelectedWheel_ = key;
    saveState();
}

bool BackendBridge::isFirstRun() const
{
    return !QFile::exists(firstRunFlagPath());
}

void BackendBridge::markFirstRunSeen()
{
    const QString path = firstRunFlagPath();
    QDir().mkpath(QFileInfo(path).absolutePath());

    QFile file(path);
    if (file.open(QIODevice::WriteOnly)) {
        file.close();
        return;
    }

    qWarning() << "cannot create first run flag:" << path;
}

int BackendBridge::currentDrawMode() const
{
    return static_cast<int>(currentDrawMode_);
}

int BackendBridge::drawCount() const
{
    return drawCount_;
}

int BackendBridge::drawStrategy() const
{
    return static_cast<int>(drawStrategy_);
}

void BackendBridge::setCurrentDrawMode(int mode)
{
    if (mode < static_cast<int>(DrawMode::Wheel) || mode > static_cast<int>(DrawMode::BlindBox)) {
        return;
    }

    const auto next = static_cast<DrawMode>(mode);
    if (currentDrawMode_ == next) {
        return;
    }

    currentDrawMode_ = next;
    emit drawModeChanged();
}

bool BackendBridge::soundEnabled() const
{
    return soundEnabled_;
}

void BackendBridge::setSoundEnabled(bool enabled)
{
    if (soundEnabled_ == enabled) {
        return;
    }

    soundEnabled_ = enabled;
    saveState();
    qInfo() << "sound enabled:" << enabled;
    emit soundEnabledChanged();
}

bool BackendBridge::motionEnabled() const
{
    return motionEnabled_;
}

AiManager *BackendBridge::aiManager() const
{
    return aiManager_.get();
}

void BackendBridge::setMotionEnabled(bool enabled)
{
    if (motionEnabled_ == enabled) {
        return;
    }

    motionEnabled_ = enabled;
    saveState();
    qInfo() << "motion enabled:" << enabled;
    emit motionEnabledChanged();
}

int BackendBridge::rosterCount() const
{
    return static_cast<int>(roster_->size());
}

void BackendBridge::recordDraw(const QString &name)
{
    const QString time = QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"));
    history_.push_back(HistoryEntry{name, time});
    saveState();
    emit historyUpdated();
}

QString BackendBridge::dataFilePath()
{
    QSettings settings(QStringLiteral("HKEY_CURRENT_USER\\Software\\XieQian"), QSettings::NativeFormat);
    const QString customPath = settings.value(QStringLiteral("DataPath")).toString().trimmed();

    if (!customPath.isEmpty()) {
        if (!QDir().mkpath(customPath)) {
            qWarning() << "cannot create data directory:" << customPath;
        }
        return QDir(customPath).filePath(QStringLiteral("data.json"));
    }

    return QDir(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation))
        .filePath(QStringLiteral("data.json"));
}

QString BackendBridge::firstRunFlagPath()
{
    return QDir(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation))
        .filePath(QStringLiteral("first_run.flag"));
}

QJsonObject BackendBridge::stateToJson() const
{
    QJsonArray roster;
    for (std::size_t index = 0; index < roster_->size(); ++index) {
        const xieqian::core::Participant &participant = roster_->at(index);

        QJsonObject entry;
        entry.insert(QStringLiteral("name"), QString::fromStdString(participant.name));
        entry.insert(QStringLiteral("studentId"), QString::fromStdString(participant.studentId));
        entry.insert(QStringLiteral("group"), QString::fromStdString(participant.group));
        entry.insert(QStringLiteral("enabled"), participant.enabled);
        entry.insert(QStringLiteral("weight"), participant.weight);
        entry.insert(QStringLiteral("drawCount"), participant.drawCount);
        entry.insert(QStringLiteral("streak"), participant.streak);
        roster.append(entry);
    }

    QJsonArray history;
    for (const HistoryEntry &record : history_) {
        QJsonObject entry;
        entry.insert(QStringLiteral("name"), record.name);
        entry.insert(QStringLiteral("time"), record.time);
        history.append(entry);
    }

    QJsonArray customWheels;
    for (const CustomWheel &wheel : customWheels_) {
        QJsonObject entry;
        entry.insert(QStringLiteral("name"), wheel.name);
        entry.insert(QStringLiteral("options"), QJsonArray::fromStringList(wheel.options));
        customWheels.append(entry);
    }

    QJsonObject aiConfig;
    aiConfig.insert(QStringLiteral("apiKey"), aiApiKey_);
    aiConfig.insert(QStringLiteral("baseUrl"), aiBaseUrl_);
    aiConfig.insert(QStringLiteral("model"), aiModel_);

    QJsonObject root;
    root.insert(QStringLiteral("roster"), roster);
    root.insert(QStringLiteral("history"), history);
    root.insert(QStringLiteral("customWheels"), customWheels);
    root.insert(QStringLiteral("activeWheel"), activeWheelName_);
    root.insert(QStringLiteral("lastSelectedWheel"), lastSelectedWheel_);
    root.insert(QStringLiteral("aiConfig"), aiConfig);
    root.insert(QStringLiteral("soundEnabled"), soundEnabled_);
    root.insert(QStringLiteral("motionEnabled"), motionEnabled_);
    root.insert(QStringLiteral("dynamicWeights"), dynamicWeights_);
    return root;
}

void BackendBridge::applyData(const QJsonObject &root)
{
    roster_->clear();
    for (const QJsonValue &value : root.value(QStringLiteral("roster")).toArray()) {
        const QJsonObject entry = value.toObject();

        xieqian::core::Participant participant;
        participant.name = entry.value(QStringLiteral("name")).toString().toStdString();
        participant.studentId = entry.value(QStringLiteral("studentId")).toString().toStdString();
        participant.group = entry.value(QStringLiteral("group")).toString().toStdString();
        participant.enabled = entry.value(QStringLiteral("enabled")).toBool(true);
        participant.weight = entry.value(QStringLiteral("weight")).toDouble(1.0);
        participant.drawCount = entry.value(QStringLiteral("drawCount")).toInt(0);
        participant.streak = entry.value(QStringLiteral("streak")).toInt(0);

        if (!participant.name.empty()) {
            roster_->add(std::move(participant));
        }
    }

    history_.clear();
    for (const QJsonValue &value : root.value(QStringLiteral("history")).toArray()) {
        const QJsonObject entry = value.toObject();
        const QString name = entry.value(QStringLiteral("name")).toString();
        if (name.isEmpty()) {
            continue;
        }

        history_.push_back(HistoryEntry{name, entry.value(QStringLiteral("time")).toString()});
    }

    customWheels_.clear();
    for (const QJsonValue &value : root.value(QStringLiteral("customWheels")).toArray()) {
        const QJsonObject entry = value.toObject();
        const QString name = entry.value(QStringLiteral("name")).toString().trimmed();
        if (name.isEmpty()) {
            continue;
        }

        QStringList options;
        for (const QJsonValue &option : entry.value(QStringLiteral("options")).toArray()) {
            const QString text = option.toString().trimmed();
            if (!text.isEmpty() && !options.contains(text)) {
                options.append(text);
            }
        }

        if (options.size() >= 2) {
            customWheels_.push_back(CustomWheel{name, options});
        }
    }

    activeWheelName_ = root.value(QStringLiteral("activeWheel")).toString().trimmed();
    const auto active = std::find_if(customWheels_.begin(), customWheels_.end(),
                                     [this](const CustomWheel &wheel) {
                                         return wheel.name == activeWheelName_;
                                     });
    if (active == customWheels_.end()) {
        activeWheelName_ = customWheels_.empty() ? QString() : customWheels_.back().name;
    }

    aiApiKey_ = root.value(QStringLiteral("aiConfig")).toObject()
                    .value(QStringLiteral("apiKey")).toString().trimmed();
    aiBaseUrl_ = root.value(QStringLiteral("aiConfig")).toObject()
                     .value(QStringLiteral("baseUrl")).toString().trimmed();
    aiModel_ = root.value(QStringLiteral("aiConfig")).toObject()
                   .value(QStringLiteral("model")).toString().trimmed();

    // 1.0.7.9 及更早把 AI 配置平铺在根节点，升级后仍能读回已保存的密钥
    if (aiApiKey_.isEmpty() && aiBaseUrl_.isEmpty()) {
        aiApiKey_ = root.value(QStringLiteral("aiApiKey")).toString().trimmed();
        aiBaseUrl_ = root.value(QStringLiteral("aiBaseUrl")).toString().trimmed();
    }
    aiManager_->setApiConfig(aiApiKey_, aiBaseUrl_, aiModel_);

    lastSelectedWheel_ = root.value(QStringLiteral("lastSelectedWheel")).toString().trimmed();

    soundEnabled_ = root.value(QStringLiteral("soundEnabled")).toBool(true);
    motionEnabled_ = root.value(QStringLiteral("motionEnabled")).toBool(true);
    dynamicWeights_ = root.value(QStringLiteral("dynamicWeights")).toBool(false);
    drawEngine_->setDynamicWeights(dynamicWeights_);
    drawEngine_->clearDrawnHistory();
}

void BackendBridge::saveState() const
{
    writeJsonFile(dataFilePath(), stateToJson());
}

QString BackendBridge::chooseBackupPath()
{
    return QFileDialog::getSaveFileName(nullptr, QStringLiteral("备份数据"),
                                        QStringLiteral("xieqian-backup.json"),
                                        QStringLiteral("JSON Files (*.json)"));
}

QString BackendBridge::chooseRestorePath()
{
    return QFileDialog::getOpenFileName(nullptr, QStringLiteral("恢复数据"), QString(),
                                        QStringLiteral("JSON Files (*.json)"));
}

void BackendBridge::exportData(const QString &filePath)
{
    if (filePath.isEmpty()) {
        return;
    }

    QString path = filePath;
    if (!path.endsWith(QStringLiteral(".json"), Qt::CaseInsensitive)) {
        path += QStringLiteral(".json");
    }

    writeJsonFile(path, stateToJson());
}

void BackendBridge::importData(const QString &filePath)
{
    if (filePath.isEmpty()) {
        return;
    }

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "cannot read import file:" << filePath;
        return;
    }

    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    if (document.isNull() || !document.isObject() || !hasStateArrays(document.object())) {
        qWarning() << "invalid import file:" << filePath;
        return;
    }

    const bool soundWasEnabled = soundEnabled_;
    const bool motionWasEnabled = motionEnabled_;

    applyData(document.object());
    saveState();

    emit rosterUpdated();
    emit historyUpdated();
    if (soundEnabled_ != soundWasEnabled) {
        emit soundEnabledChanged();
    }
    if (motionEnabled_ != motionWasEnabled) {
        emit motionEnabledChanged();
    }
    emit customWheelsChanged();
    emit aiConfigChanged();
}
