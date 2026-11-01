#include <QApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QTimer>

#include "backend_bridge.h"

#ifdef Q_OS_WIN
#include <QAbstractNativeEventFilter>
#include <QPointer>

#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <windowsx.h>
#endif

namespace {

#ifdef Q_OS_WIN
// 无边框窗口在 Qt 里默认没有 WS_THICKFRAME，系统既不提供边缘缩放，
// QWindow::startSystemResize() 也会因为缺少系统菜单而直接失败。
// 这里补回厚边框样式，但 Qt 的 WM_NCCALCSIZE 会让客户区仍然铺满整个窗口，
// 所以视觉上只剩 1px 透明系统边框。
void applyNativeThickFrame(QQuickWindow *window)
{
    if (window == nullptr) {
        return;
    }

    const HWND hwnd = reinterpret_cast<HWND>(window->winId());
    if (hwnd == nullptr) {
        return;
    }

    const LONG_PTR style = GetWindowLongPtr(hwnd, GWL_STYLE);
    if ((style & WS_THICKFRAME) != 0) {
        return;
    }

    SetWindowLongPtr(hwnd, GWL_STYLE, style | WS_THICKFRAME);
    SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
}

// 边缘缩放：直接在 WM_NCHITTEST 里返回系统边框命中区域，
// 由 Windows 自己完成缩放与贴边，不再依赖 QML 手算热区与 startSystemResize。
class FramelessResizeFilter : public QAbstractNativeEventFilter
{
public:
    explicit FramelessResizeFilter(QQuickWindow *window) : window_(window) {}

    bool nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result) override
    {
        if (eventType != "windows_generic_MSG" || result == nullptr || window_.isNull()) {
            return false;
        }

        MSG *msg = static_cast<MSG *>(message);
        if (msg->message != WM_NCHITTEST || msg->hwnd != reinterpret_cast<HWND>(window_->winId())) {
            return false;
        }

        // 最大化与画中画状态下彻底关闭边缘缩放：整窗按客户区处理
        if (window_->visibility() == QWindow::Maximized
            || window_->property("pipMode").toBool()) {
            *result = HTCLIENT;
            return true;
        }

        RECT frame{};
        if (!GetWindowRect(msg->hwnd, &frame)) {
            return false;
        }

        // 命中区域按物理像素计算，5px 在 100%~150% 缩放下都够好点
        constexpr int kResizeBorder = 5;
        const int x = GET_X_LPARAM(msg->lParam) - frame.left;
        const int y = GET_Y_LPARAM(msg->lParam) - frame.top;
        const int width = frame.right - frame.left;
        const int height = frame.bottom - frame.top;

        const bool left = x < kResizeBorder;
        const bool right = x >= width - kResizeBorder;
        const bool top = y < kResizeBorder;
        const bool bottom = y >= height - kResizeBorder;

        if (left && top) {
            *result = HTTOPLEFT;
        } else if (right && top) {
            *result = HTTOPRIGHT;
        } else if (left && bottom) {
            *result = HTBOTTOMLEFT;
        } else if (right && bottom) {
            *result = HTBOTTOMRIGHT;
        } else if (left) {
            *result = HTLEFT;
        } else if (right) {
            *result = HTRIGHT;
        } else if (top) {
            *result = HTTOP;
        } else if (bottom) {
            *result = HTBOTTOM;
        } else {
            return false;
        }

        return true;
    }

private:
    QPointer<QQuickWindow> window_;
};
#endif

}  // namespace

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("XieQian"));
    QCoreApplication::setApplicationVersion(QStringLiteral("1.0.9.9"));
    // 任务栏与窗口图标：rc 资源负责 exe 图标，这里保证运行时窗口也用同一枚图标
    app.setWindowIcon(QIcon(QStringLiteral(":/ui/assets/app-icon-512.png")));

    BackendBridge backendBridge;

    QQmlApplicationEngine engine;
    // QML 所有页面都通过 backendBridge 访问后端；缺这条注册会让按钮点击后全部无响应
    engine.rootContext()->setContextProperty(QStringLiteral("backendBridge"), &backendBridge);

#ifdef Q_OS_WIN
    const bool nativeResize = true;
#else
    const bool nativeResize = false;
#endif
    // Windows 下边缘缩放由系统命中测试处理，QML 不再绘制拖拽热区
    engine.rootContext()->setContextProperty(QStringLiteral("nativeWindowResize"), nativeResize);

    engine.load(QUrl(QStringLiteral("qrc:/ui/qml/Main.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

#ifdef Q_OS_WIN
    if (auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst())) {
        applyNativeThickFrame(window);
        app.installNativeEventFilter(new FramelessResizeFilter(window));

        // 画中画会改窗口 flags，Qt 重建原生窗口时会先隐藏再显示，
        // 借 visibilityChanged 重新补一次厚边框样式
        QObject::connect(window, &QWindow::visibilityChanged, window, [window]() {
            QTimer::singleShot(0, window, [window]() { applyNativeThickFrame(window); });
        });

        // 部分平台路径下 flags 变化不会发 visibilityChanged，
        // 低频检查一次（样式已在时直接返回，开销极小）
        auto *frameWatch = new QTimer(window);
        QObject::connect(frameWatch, &QTimer::timeout, window, [window]() {
            applyNativeThickFrame(window);
        });
        frameWatch->start(1000);
    }
#endif

    return app.exec();
}
