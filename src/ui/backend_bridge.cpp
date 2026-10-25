#include "backend_bridge.h"

#include <algorithm>
#include <random>
#include <string>

#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFile>
#include <QFileDialog>
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

QVariantList BackendBridge::getParticipants()
{
    QVariantList participants;
    for (std::size_t index = 0; index < roster_->size(); ++index) {
        const xieqian::core::Participant &participant = roster_->at(index);

        QVariantMap entry;
        entry.insert(QStringLiteral("index"), static_cast<int>(index));
        entry.insert(QStringLiteral("name"), QString::fromStdString(participant.name));
        entry.insert(QStringLiteral("studentId"), QString::fromStdString(participant.studentId));
        entry.insert(QStringLiteral("group"), QString::fromStdString(participant.group));
        entry.insert(QStringLiteral("enabled"), participant.enabled);
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
    qInfo() << "sound enabled:" << enabled;
    emit soundEnabledChanged();
}

bool BackendBridge::highMotion() const
{
    return highMotion_;
}

void BackendBridge::setHighMotion(bool enabled)
{
    if (highMotion_ == enabled) {
        return;
    }

    highMotion_ = enabled;
    qInfo() << "high motion:" << enabled;
    emit highMotionChanged();
}

int BackendBridge::rosterCount() const
{
    return static_cast<int>(roster_->size());
}

void BackendBridge::recordDraw(const QString &name)
{
    const QString time = QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"));
    history_.push_back(HistoryEntry{name, time});
    emit historyUpdated();
}
