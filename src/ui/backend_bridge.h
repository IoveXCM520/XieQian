#pragma once

#include <memory>

#include <QObject>
#include <QString>
#include <QVariantList>

#include "xieqian/core/draw/draw_engine.h"
#include "xieqian/core/roster/roster.h"

class BackendBridge : public QObject
{
    Q_OBJECT

public:
    explicit BackendBridge(QObject *parent = nullptr);

    Q_INVOKABLE QString drawWinner();
    Q_INVOKABLE QVariantList drawWinners(int count);

private:
    std::unique_ptr<xieqian::core::Roster> roster_;
    std::unique_ptr<xieqian::core::DrawEngine> drawEngine_;
};
