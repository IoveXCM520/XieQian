#include <QApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "backend_bridge.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("XieQian"));
    // 任务栏与窗口图标：rc 资源负责 exe 图标，这里保证运行时窗口也用同一枚图标
    app.setWindowIcon(QIcon(QStringLiteral(":/ui/assets/app-icon-512.png")));

    BackendBridge backendBridge;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("backendBridge"), &backendBridge);
    engine.load(QUrl(QStringLiteral("qrc:/ui/qml/Main.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
