#pragma once

#include <memory>
#include <vector>

#include <QObject>
#include <QString>
#include <QStringList>
#include <QThreadPool>
#include <QVariantList>
#include <QVariantMap>

#include "ai_manager.h"
#include "xieqian/core/draw/draw_engine.h"
#include "xieqian/core/roster/roster.h"

class QJsonObject;
class QTimer;

class BackendBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int rosterCount READ rosterCount NOTIFY rosterUpdated)
    Q_PROPERTY(int currentDrawMode READ currentDrawMode WRITE setCurrentDrawMode NOTIFY drawModeChanged)
    Q_PROPERTY(int drawCount READ drawCount NOTIFY drawSettingsChanged)
    Q_PROPERTY(int drawStrategy READ drawStrategy NOTIFY drawSettingsChanged)
    Q_PROPERTY(bool soundEnabled READ soundEnabled WRITE setSoundEnabled NOTIFY soundEnabledChanged)
    Q_PROPERTY(bool motionEnabled READ motionEnabled WRITE setMotionEnabled NOTIFY motionEnabledChanged)
    Q_PROPERTY(AiManager *aiManager READ aiManager CONSTANT)
    Q_PROPERTY(QVariantList customWheels READ customWheels NOTIFY customWheelsChanged)
    Q_PROPERTY(bool dynamicWeights READ dynamicWeights WRITE setDynamicWeights NOTIFY dynamicWeightsChanged)

public:
    enum class DrawMode { Wheel = 0, FlipCard = 1, BlindBox = 2 };

    explicit BackendBridge(QObject *parent = nullptr);
    ~BackendBridge() override;

    Q_INVOKABLE QString drawWinner();
    Q_INVOKABLE QVariantList drawWinners(int count);
    Q_INVOKABLE QVariantList drawMultipleWinners();
    Q_INVOKABLE void applyMockRoster(const QVariantList &roster);
    Q_INVOKABLE void updateDrawSettings(int count, int strategy);
    Q_INVOKABLE QString chooseRosterFilePath();
    Q_INVOKABLE QStringList readNamesFromFile(const QString &filePath);
    Q_INVOKABLE int appendNamesToRoster(const QStringList &names);
    Q_INVOKABLE int applyScoreWeights(const QVariantList &entries);
    Q_INVOKABLE void resetDrawStats();
    Q_INVOKABLE void appendHistory(const QString &name);
    Q_INVOKABLE QVariantList getParticipantsWithStatus();
    Q_INVOKABLE void toggleParticipantStatus(int index);
    Q_INVOKABLE void updateParticipantWeight(const QString &id, double weight);
    Q_INVOKABLE bool removeParticipant(const QString &id);
    Q_INVOKABLE bool saveCustomWheel(const QString &name, const QVariantList &options);
    Q_INVOKABLE bool removeCustomWheel(const QString &name);
    Q_INVOKABLE QVariantMap getCustomWheel();
    Q_INVOKABLE QString lastSelectedWheel() const;
    Q_INVOKABLE void setLastSelectedWheel(const QString &name);
    Q_INVOKABLE QVariantList getHistory();
    Q_INVOKABLE void clearHistory();
    Q_INVOKABLE void clearAllData();
    Q_INVOKABLE void saveAIConfig(const QString &apiKey, const QString &baseUrl, const QString &model);
    Q_INVOKABLE QVariantMap getAIConfig();
    Q_INVOKABLE bool isFirstRun() const;
    Q_INVOKABLE void markFirstRunSeen();
    Q_INVOKABLE QString chooseRosterImagePath();
    Q_INVOKABLE QString chooseBackupPath();
    Q_INVOKABLE QString chooseRestorePath();
    Q_INVOKABLE void exportData(const QString &filePath);
    Q_INVOKABLE void importData(const QString &filePath);

    int rosterCount() const;

    int currentDrawMode() const;
    void setCurrentDrawMode(int mode);

    int drawCount() const;
    int drawStrategy() const;

    bool soundEnabled() const;
    void setSoundEnabled(bool enabled);

    bool motionEnabled() const;
    void setMotionEnabled(bool enabled);

    AiManager *aiManager() const;

    QVariantList customWheels() const;

    bool dynamicWeights() const;
    void setDynamicWeights(bool enabled);

signals:
    void rosterUpdated();
    void historyUpdated();
    void drawModeChanged();
    void drawSettingsChanged();
    void winnerDrawn(const QString &name, int mode);
    void winnersDrawn(const QStringList &names, int mode);
    void soundEnabledChanged();
    void motionEnabledChanged();
    void customWheelsChanged();
    void dynamicWeightsChanged();
    void aiConfigChanged();

private:
    struct HistoryEntry {
        QString name;
        QString time;
    };

    struct CustomWheel {
        QString name;
        QStringList options;
    };

    void recordDraw(const QString &name);
    void recordWinners(const std::vector<xieqian::core::Participant> &winners);
    [[nodiscard]] xieqian::core::DrawStrategy strategyFor(
        const std::vector<xieqian::core::Participant> &pool) const;
    void applyData(const QJsonObject &root);
    [[nodiscard]] QJsonObject stateToJson() const;
    // 合并短时间内的多次改动后异步落盘，退出与导出时走同步 flush
    void saveState();
    void writeStateAsync();
    void flushState();
    void loadState();
    [[nodiscard]] static QString dataFilePath();
    [[nodiscard]] static QString firstRunFlagPath();

    std::shared_ptr<xieqian::core::Roster> roster_;
    std::unique_ptr<xieqian::core::DrawEngine> drawEngine_;
    std::unique_ptr<AiManager> aiManager_;
    // 单线程池保证写盘顺序与调用顺序一致
    QThreadPool savePool_;
    QTimer *saveTimer_ = nullptr;
    std::vector<HistoryEntry> history_;
    std::vector<CustomWheel> customWheels_;
    QString activeWheelName_;
    QString lastSelectedWheel_;
    QString aiApiKey_;
    QString aiBaseUrl_;
    QString aiModel_;
    DrawMode currentDrawMode_ = DrawMode::Wheel;
    int drawCount_ = 1;
    xieqian::core::DrawStrategy drawStrategy_ = xieqian::core::DrawStrategy::Random;
    bool soundEnabled_ = true;
    bool motionEnabled_ = true;
    bool dynamicWeights_ = false;
};
