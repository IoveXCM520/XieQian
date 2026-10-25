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

public:
    explicit BackendBridge(QObject *parent = nullptr);

    Q_INVOKABLE QString drawWinner();
    Q_INVOKABLE QVariantList drawWinners(int count);
    Q_INVOKABLE bool loadRosterFromCsv(const QString &filePath);
    Q_INVOKABLE void mockImportCsv();
    Q_INVOKABLE QVariantList getParticipants();
    Q_INVOKABLE void toggleParticipantStatus(int index);
    Q_INVOKABLE QVariantList getHistory();

    int rosterCount() const;

signals:
    void rosterUpdated();
    void historyUpdated();

private:
    struct HistoryEntry {
        QString name;
        QString time;
    };

    void recordDraw(const QString &name);

    std::unique_ptr<xieqian::core::Roster> roster_;
    std::unique_ptr<xieqian::core::DrawEngine> drawEngine_;
    std::vector<HistoryEntry> history_;
};
