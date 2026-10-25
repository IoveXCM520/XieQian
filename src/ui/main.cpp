#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "backend_bridge.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    BackendBridge backendBridge;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("backendBridge"), &backendBridge);
    engine.load(QUrl(QStringLiteral("qrc:/ui/qml/Main.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
