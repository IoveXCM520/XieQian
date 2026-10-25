#pragma once

#include <QObject>
#include <QString>

class BackendBridge : public QObject
{
    Q_OBJECT

public:
    explicit BackendBridge(QObject *parent = nullptr);

    Q_INVOKABLE QString testDraw();
};
