#pragma once

#include <memory>
#include <vector>

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>

#include "ai_manager.h"
#include "xieqian/core/draw/draw_engine.h"
#include "xieqian/core/roster/roster.h"

class QJsonObject;

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

public:
    enum class DrawMode { Wheel = 0, FlipCard = 1, BlindBox = 2 };

    explicit BackendBridge(QObject *parent = nullptr);

    Q_INVOKABLE QString drawWinner();
    Q_INVOKABLE QVariantList drawWinners(int count);
    Q_INVOKABLE QVariantList drawMultipleWinners();
    Q_INVOKABLE QVariantList generateGroups(int groupCount);
    Q_INVOKABLE QVariantList generateSeats();
    Q_INVOKABLE void applyMockRoster(const QVariantList &roster);
    Q_INVOKABLE void updateDrawSettings(int count, int strategy);
    Q_INVOKABLE bool loadRosterFromCsv(const QString &filePath);
    Q_INVOKABLE void openCsvFileDialog();
    Q_INVOKABLE void mockImportCsv();
    Q_INVOKABLE QVariantList getParticipantsWithStatus();
    Q_INVOKABLE void toggleParticipantStatus(int index);
    Q_INVOKABLE void updateParticipantWeight(const QString &id, double weight);
    Q_INVOKABLE void resetDrawnHistory();
    Q_INVOKABLE QVariantList getHistory();
    Q_INVOKABLE void clearAllData();
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

signals:
    void rosterUpdated();
    void historyUpdated();
    void drawModeChanged();
    void drawSettingsChanged();
    void winnerDrawn(const QString &name, int mode);
    void winnersDrawn(const QStringList &names, int mode);
    void soundEnabledChanged();
    void motionEnabledChanged();

private:
    struct HistoryEntry {
        QString name;
        QString time;
    };

    void recordDraw(const QString &name);
    void applyData(const QJsonObject &root);
    [[nodiscard]] QJsonObject stateToJson() const;
    void saveState() const;
    void loadState();
    [[nodiscard]] static QString dataFilePath();

    std::unique_ptr<xieqian::core::Roster> roster_;
    std::unique_ptr<xieqian::core::DrawEngine> drawEngine_;
    std::unique_ptr<AiManager> aiManager_;
    std::vector<HistoryEntry> history_;
    DrawMode currentDrawMode_ = DrawMode::Wheel;
    int drawCount_ = 1;
    xieqian::core::DrawStrategy drawStrategy_ = xieqian::core::DrawStrategy::Random;
    bool soundEnabled_ = true;
    bool motionEnabled_ = true;
};
