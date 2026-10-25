#pragma once

#include <memory>
#include <vector>

#include <QObject>
#include <QString>
#include <QVariantList>

#include "xieqian/core/draw/draw_engine.h"
#include "xieqian/core/roster/roster.h"

class BackendBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int rosterCount READ rosterCount NOTIFY rosterUpdated)
    Q_PROPERTY(bool soundEnabled READ soundEnabled WRITE setSoundEnabled NOTIFY soundEnabledChanged)
    Q_PROPERTY(bool highMotion READ highMotion WRITE setHighMotion NOTIFY highMotionChanged)

public:
    explicit BackendBridge(QObject *parent = nullptr);

    Q_INVOKABLE QString drawWinner();
    Q_INVOKABLE QVariantList drawWinners(int count);
    Q_INVOKABLE bool loadRosterFromCsv(const QString &filePath);
    Q_INVOKABLE void openCsvFileDialog();
    Q_INVOKABLE void mockImportCsv();
    Q_INVOKABLE QVariantList getParticipants();
    Q_INVOKABLE void toggleParticipantStatus(int index);
    Q_INVOKABLE QVariantList getHistory();
    Q_INVOKABLE void clearAllData();

    int rosterCount() const;

    bool soundEnabled() const;
    void setSoundEnabled(bool enabled);

    bool highMotion() const;
    void setHighMotion(bool enabled);

signals:
    void rosterUpdated();
    void historyUpdated();
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
    bool soundEnabled_ = true;
    bool highMotion_ = true;
};
