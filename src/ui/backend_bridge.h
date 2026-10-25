#pragma once

#include <memory>
#include <vector>

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>

#include "xieqian/core/draw/draw_engine.h"
#include "xieqian/core/roster/roster.h"

class BackendBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int rosterCount READ rosterCount NOTIFY rosterUpdated)
    Q_PROPERTY(int currentDrawMode READ currentDrawMode WRITE setCurrentDrawMode NOTIFY drawModeChanged)
    Q_PROPERTY(int drawCount READ drawCount NOTIFY drawSettingsChanged)
    Q_PROPERTY(int drawStrategy READ drawStrategy NOTIFY drawSettingsChanged)
    Q_PROPERTY(bool soundEnabled READ soundEnabled WRITE setSoundEnabled NOTIFY soundEnabledChanged)
    Q_PROPERTY(bool highMotion READ highMotion WRITE setHighMotion NOTIFY highMotionChanged)

public:
    enum class DrawMode { Wheel = 0, FlipCard = 1, BlindBox = 2 };

    explicit BackendBridge(QObject *parent = nullptr);

    Q_INVOKABLE QString drawWinner();
    Q_INVOKABLE QVariantList drawWinners(int count);
    Q_INVOKABLE QVariantList drawMultipleWinners();
    Q_INVOKABLE void updateDrawSettings(int count, int strategy);
    Q_INVOKABLE bool loadRosterFromCsv(const QString &filePath);
    Q_INVOKABLE void openCsvFileDialog();
    Q_INVOKABLE void mockImportCsv();
    Q_INVOKABLE QVariantList getParticipants();
    Q_INVOKABLE void toggleParticipantStatus(int index);
    Q_INVOKABLE QVariantList getHistory();
    Q_INVOKABLE void clearAllData();

    int rosterCount() const;

    int currentDrawMode() const;
    void setCurrentDrawMode(int mode);

    int drawCount() const;
    int drawStrategy() const;

    bool soundEnabled() const;
    void setSoundEnabled(bool enabled);

    bool highMotion() const;
    void setHighMotion(bool enabled);

signals:
    void rosterUpdated();
    void historyUpdated();
    void drawModeChanged();
    void drawSettingsChanged();
    void winnerDrawn(const QString &name, int mode);
    void winnersDrawn(const QStringList &names, int mode);
    void soundEnabledChanged();
    void highMotionChanged();

private:
    struct HistoryEntry {
        QString name;
        QString time;
    };

    void recordDraw(const QString &name);

    std::unique_ptr<xieqian::core::Roster> roster_;
    std::unique_ptr<xieqian::core::DrawEngine> drawEngine_;
    std::vector<HistoryEntry> history_;
    DrawMode currentDrawMode_ = DrawMode::Wheel;
    int drawCount_ = 1;
    xieqian::core::DrawStrategy drawStrategy_ = xieqian::core::DrawStrategy::Random;
    bool soundEnabled_ = true;
    bool highMotion_ = true;
};
