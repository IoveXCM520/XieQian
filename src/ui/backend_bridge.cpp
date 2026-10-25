#include "backend_bridge.h"

BackendBridge::BackendBridge(QObject *parent) : QObject(parent) {}

QString BackendBridge::testDraw()
{
    return QStringLiteral("测试中奖者");
}
