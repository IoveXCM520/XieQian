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
#include <QStandardPaths>
#include <QTemporaryFile>
#include <QVariantMap>

#include "xieqian/core/io/csv_parser.h"

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

QString mockCsvContent()
{
    return QStringLiteral("姓名,学号,分组\n"
                          "苏婉宁,2023001,一组\n"
                          "林砚舟,2023002,一组\n"
                          "顾南乔,2023003,二组\n"
                          "白清让,2023004,二组\n"
                          "沈亦初,2023005,三组\n"
                          "温言澈,2023006,三组\n"
                          "陆时衍,2023007,四组\n"
                          "许南枝,2023008,四组\n"
                          "程砚秋,2023009,五组\n"
                          "江晚吟,2023010,五组\n");
}

}  // namespace

BackendBridge::BackendBridge(QObject *parent)
    : QObject(parent),
      roster_(std::make_unique<xieqian::core::Roster>()),
      drawEngine_(std::make_unique<xieqian::core::DrawEngine>(seededGenerator()))
{
    loadState();
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
        drawEngine_->draw(roster_->enabledParticipants(), 1, drawStrategy_);
    if (winners.empty()) {
        return QStringLiteral("无可用名单");
    }

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

    for (const xieqian::core::Participant &participant :
         drawEngine_->draw(roster_->enabledParticipants(), count, drawStrategy_)) {
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

    for (const xieqian::core::Participant &participant :
         drawEngine_->draw(roster_->enabledParticipants(), drawCount_, drawStrategy_)) {
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

QVariantList BackendBridge::generateGroups(int groupCount)
{
    QVariantList groups;
    if (groupCount <= 0) {
        return groups;
    }

    for (const std::vector<xieqian::core::Participant> &group :
         drawEngine_->randomGroup(roster_->enabledParticipants(), groupCount)) {
        QVariantList members;
        for (const xieqian::core::Participant &participant : group) {
            members.append(QString::fromStdString(participant.name));
        }
        groups.append(members);
    }
    return groups;
}

QVariantList BackendBridge::generateSeats()
{
    QVariantList seats;
    for (const xieqian::core::Participant &participant :
         drawEngine_->randomSeat(roster_->enabledParticipants())) {
        seats.append(QString::fromStdString(participant.name));
    }
    return seats;
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

bool BackendBridge::loadRosterFromCsv(const QString &filePath)
{
    xieqian::core::CsvParser parser;
    if (!parser.parseFile(QFile::encodeName(filePath).toStdString(), *roster_)) {
        return false;
    }

    drawEngine_->clearDrawnHistory();
    saveState();
    emit rosterUpdated();
    return true;
}

void BackendBridge::openCsvFileDialog()
{
    const QString filePath = QFileDialog::getOpenFileName(nullptr, QStringLiteral("选择名单文件"), QString(),
                                                          QStringLiteral("CSV Files (*.csv)"));
    if (filePath.isEmpty()) {
        return;
    }

    // 导入成功时 loadRosterFromCsv 已经发出 rosterUpdated
    loadRosterFromCsv(filePath);
}

void BackendBridge::mockImportCsv()
{
    QTemporaryFile file(QDir::tempPath() + QStringLiteral("/xieqian-roster-XXXXXX.csv"));
    if (!file.open()) {
        return;
    }

    file.write(mockCsvContent().toUtf8());
    file.close();

    loadRosterFromCsv(file.fileName());
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

void BackendBridge::resetDrawnHistory()
{
    drawEngine_->clearDrawnHistory();
    emit rosterUpdated();
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

void BackendBridge::clearAllData()
{
    roster_->clear();
    history_.clear();
    drawEngine_->clearDrawnHistory();

    saveState();
    emit rosterUpdated();
    emit historyUpdated();
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
    return QDir(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation))
        .filePath(QStringLiteral("data.json"));
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
        roster.append(entry);
    }

    QJsonArray history;
    for (const HistoryEntry &record : history_) {
        QJsonObject entry;
        entry.insert(QStringLiteral("name"), record.name);
        entry.insert(QStringLiteral("time"), record.time);
        history.append(entry);
    }

    QJsonObject root;
    root.insert(QStringLiteral("roster"), roster);
    root.insert(QStringLiteral("history"), history);
    root.insert(QStringLiteral("soundEnabled"), soundEnabled_);
    root.insert(QStringLiteral("motionEnabled"), motionEnabled_);
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

    soundEnabled_ = root.value(QStringLiteral("soundEnabled")).toBool(true);
    motionEnabled_ = root.value(QStringLiteral("motionEnabled")).toBool(true);
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
}
