#include <QApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QScreen>

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
// 这里补回厚边框样式，客户区由下面的 WM_NCCALCSIZE 铺满整个窗口，
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

// 窗口几何完全交给系统：客户区覆盖整窗、边缘缩放走原生命中测试、
// 标题栏走 HTCAPTION（拖动/吸附/还原/双击最大化都是 Win32 原生行为）。
// QML 不再写 x/y/width/height，也不会出现动画中间态与合成表面错位。
class FramelessWindowFilter : public QAbstractNativeEventFilter
{
public:
    explicit FramelessWindowFilter(QQuickWindow *window) : window_(window) {}

    bool nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result) override
    {
        if ((eventType != "windows_generic_MSG" && eventType != "windows_dispatcher_MSG")
            || result == nullptr || window_.isNull()) {
            return false;
        }

        MSG *msg = static_cast<MSG *>(message);
        if (msg->hwnd != reinterpret_cast<HWND>(window_->winId())) {
            return false;
        }

        if (msg->message == WM_NCCALCSIZE) {
            return handleNcCalcSize(msg, result);
        }
        if (msg->message == WM_NCHITTEST) {
            return handleNcHitTest(msg, result);
        }
        return false;
    }

private:
    // 客户区铺满窗口：普通状态去掉系统边框内缩，最大化时对齐显示器工作区。
    // 两处都返回 0，系统不会再给客户区留黑边。
    bool handleNcCalcSize(MSG *msg, qintptr *result)
    {
        if (msg->wParam == FALSE) {
            return false;
        }

        auto *params = reinterpret_cast<NCCALCSIZE_PARAMS *>(msg->lParam);
        if (params == nullptr) {
            return false;
        }

        if (IsZoomed(msg->hwnd) == TRUE) {
            MONITORINFO monitor{};
            monitor.cbSize = sizeof(monitor);
            if (GetMonitorInfo(MonitorFromWindow(msg->hwnd, MONITOR_DEFAULTTONEAREST),
                               &monitor) != 0) {
                params->rgrc[0] = monitor.rcWork;
            }
        }

        *result = 0;
        return true;
    }

    // 命中测试：
    // - 非最大化时边缘 6px 返回 HTLEFT/HTTOP 等，缩放与贴边都交给系统；
    // - 最大化时边缘一律 HTCLIENT，避免拉出黑边或错位；
    // - 标题栏区域返回 HTCAPTION，拖动最大化窗口即原生“扯下来”还原。
    bool handleNcHitTest(MSG *msg, qintptr *result)
    {
        POINT cursor{GET_X_LPARAM(msg->lParam), GET_Y_LPARAM(msg->lParam)};
        if (ScreenToClient(msg->hwnd, &cursor) == 0) {
            return false;
        }

        RECT client{};
        if (GetClientRect(msg->hwnd, &client) == 0) {
            return false;
        }

        const int width = client.right - client.left;
        const int height = client.bottom - client.top;
        if (width <= 0 || height <= 0) {
            return false;
        }

        const bool maximized = IsZoomed(msg->hwnd) == TRUE;
        const int captionHeight = captionHeightPx();
        const int captionInset = captionInsetPx();

        const bool inCaption = cursor.y < captionHeight && cursor.x < width - captionInset;
        if (inCaption) {
            *result = HTCAPTION;
            return true;
        }

        if (maximized) {
            *result = HTCLIENT;
            return true;
        }

        const int border = resizeBorderPx();
        const bool left = cursor.x < border;
        const bool right = cursor.x >= width - border;
        const bool top = cursor.y < border;
        const bool bottom = cursor.y >= height - border;

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

    // 命中区域按物理像素计算，需要跟着 DPI 缩放走，否则高缩放下边角很难点中
    [[nodiscard]] int resizeBorderPx() const
    {
        const qreal ratio = devicePixelRatio();
        return qMax(4, qRound(5.0 * ratio));
    }

    [[nodiscard]] int captionHeightPx() const
    {
        const int value = window_->property("captionHeight").toInt();
        return value > 0 ? qRound(value * devicePixelRatio()) : 60;
    }

    [[nodiscard]] int captionInsetPx() const
    {
        const int value = window_->property("captionInset").toInt();
        return value > 0 ? qRound(value * devicePixelRatio()) : 152;
    }

    [[nodiscard]] qreal devicePixelRatio() const
    {
        if (QScreen *screen = window_->screen()) {
            return qMax<qreal>(1.0, screen->devicePixelRatio());
        }
        return 1.0;
    }

    QPointer<QQuickWindow> window_;
};
#endif

}  // namespace

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("XieQian"));
    QCoreApplication::setApplicationVersion(QStringLiteral("1.1.1"));
    // 任务栏与窗口图标：rc 资源负责 exe 图标，这里保证运行时窗口也用同一枚图标
    app.setWindowIcon(QIcon(QStringLiteral(":/ui/assets/app-icon-512.png")));

    BackendBridge backendBridge;

    QQmlApplicationEngine engine;
    // QML 所有页面都通过 backendBridge 访问后端；缺这条注册会让按钮点击后全部无响应
    engine.rootContext()->setContextProperty(QStringLiteral("backendBridge"), &backendBridge);

    engine.load(QUrl(QStringLiteral("qrc:/ui/qml/Main.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

#ifdef Q_OS_WIN
    if (auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().constFirst())) {
        applyNativeThickFrame(window);
        app.installNativeEventFilter(new FramelessWindowFilter(window));
    }
#endif

    return app.exec();
}
