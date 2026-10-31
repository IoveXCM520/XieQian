import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "."
import "pages"

ApplicationWindow {
    id: window

    width: 1200
    height: 800
    minimumWidth: 1000
    minimumHeight: 680
    visible: true
    title: qsTr("撷签 · 课堂抽签")
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontBody

    background: Rectangle {
        color: "transparent"
    }

    readonly property int sidebarWidth: Theme.sidebarWidth
    readonly property int titleBarHeight: Theme.titleBarHeight
    readonly property bool isMaximized: visibility === Window.Maximized
                                             || visibility === Window.FullScreen
    readonly property bool reducedMotion: {
        if (typeof backendBridge !== "undefined" && backendBridge)
            return !backendBridge.motionEnabled
        return false
    }

    property int currentPage: 0
    property int pendingPage: 0

    function navigate(page) {
        var target = Math.max(0, Math.min(4, page))
        if (target === currentPage && pageStack.currentIndex === target
                && !pageSwitch.running)
            return

        currentPage = target
        pendingPage = target

        if (reducedMotion) {
            pageSwitch.stop()
            pageStack.currentIndex = target
            pageViewport.opacity = 1.0
            pageStack.y = 0
            return
        }

        pageSwitch.restart()
    }

    function toggleMaximize() {
        if (isMaximized)
            showNormal()
        else
            showMaximized()
    }

    Rectangle {
        id: windowPanel
        anchors.fill: parent
        radius: window.isMaximized ? 0 : Theme.radiusWindow
        color: Theme.background
        border.width: window.isMaximized ? 0 : 1
        border.color: Theme.withAlpha(Theme.textPrimary, 0.06)
        clip: true

        Behavior on radius {
            NumberAnimation {
                duration: Theme.durationFast
                easing.type: Easing.OutCubic
            }
        }

        // ─────────────────────────────────────────────────────────
        // 48px 自绘标题栏 / 透明拖拽区
        // ─────────────────────────────────────────────────────────
        Rectangle {
            id: titleBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: window.titleBarHeight
            color: Theme.surface
            z: 20

            MouseArea {
                id: titleDragArea
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton

                property point pressPoint
                property bool moving: false

                onPressed: function(mouse) {
                    pressPoint = Qt.point(mouse.x, mouse.y)
                    moving = false
                }

                onPositionChanged: function(mouse) {
                    if (!pressed || moving)
                        return

                    if (Math.abs(mouse.x - pressPoint.x) > 4
                            || Math.abs(mouse.y - pressPoint.y) > 4) {
                        moving = true
                        window.startSystemMove()
                    }
                }

                onReleased: function(mouse) {
                    moving = false
                }

                onDoubleClicked: function(mouse) {
                    window.toggleMaximize()
                }
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Rectangle {
                    width: 30
                    height: 30
                    radius: 9
                    gradient: Theme.primaryGradient

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.width: 1
                        border.color: Theme.withAlpha(Theme.white, 0.20)
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "签"
                        color: Theme.white
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }
                }

                Column {
                    spacing: -1

                    Text {
                        text: "撷签"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 17
                        font.weight: Font.Bold
                    }

                    Text {
                        text: "XIE QIAN"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 8
                        font.letterSpacing: 1.7
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                TitleButton {
                    iconKind: 0
                    onTriggered: window.showMinimized()
                }

                TitleButton {
                    iconKind: 1
                    restore: window.isMaximized
                    onTriggered: window.toggleMaximize()
                }

                TitleButton {
                    iconKind: 2
                    danger: true
                    onTriggered: window.close()
                }
            }
        }

        // ─────────────────────────────────────────────────────────
        // 72px 纯白侧边栏
        // ─────────────────────────────────────────────────────────
        Rectangle {
            id: sidebar
            anchors.top: titleBar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: window.sidebarWidth
            color: Theme.surface
            z: 10

            Column {
                anchors.top: parent.top
                anchors.topMargin: 14
                width: parent.width
                spacing: 4

                NavItem {
                    iconKind: 0
                    label: "转盘"
                    selected: window.currentPage === 0
                    onTriggered: window.navigate(0)
                }

                NavItem {
                    iconKind: 1
                    label: "名单"
                    selected: window.currentPage === 1
                    onTriggered: window.navigate(1)
                }

                NavItem {
                    iconKind: 2
                    label: "历史"
                    selected: window.currentPage === 2
                    onTriggered: window.navigate(2)
                }

                NavItem {
                    iconKind: 3
                    label: "工具"
                    selected: window.currentPage === 3
                    onTriggered: window.navigate(3)
                }
            }

            NavItem {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                iconKind: 4
                label: "设置"
                selected: window.currentPage === 4
                onTriggered: window.navigate(4)
            }
        }

        // ─────────────────────────────────────────────────────────
        // 内容区
        // ─────────────────────────────────────────────────────────
        Item {
            id: contentArea
            anchors.top: titleBar.bottom
            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true

            Rectangle {
                anchors.fill: parent
                color: Theme.background
            }

            Item {
                id: pageViewport
                anchors.fill: parent

                StackLayout {
                    id: pageStack
                    width: parent.width
                    height: parent.height
                    currentIndex: 0

                    HomePage {}
                    RosterPage {}
                    HistoryPage {}
                    ToolsPage {}
                    SettingsPage {}
                }
            }
        }

        SequentialAnimation {
            id: pageSwitch

            PropertyAnimation {
                target: pageViewport
                property: "opacity"
                to: 0.0
                duration: 90
                easing.type: Easing.OutCubic
            }

            ScriptAction {
                script: {
                    pageStack.currentIndex = window.pendingPage
                    pageStack.y = 8
                }
            }

            ParallelAnimation {
                PropertyAnimation {
                    target: pageViewport
                    property: "opacity"
                    to: 1.0
                    duration: 180
                    easing.type: Easing.OutCubic
                }

                PropertyAnimation {
                    target: pageStack
                    property: "y"
                    to: 0
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }
        }

        // ─────────────────────────────────────────────────────────
        // 八方向缩放热区
        // ─────────────────────────────────────────────────────────
        Item {
            anchors.fill: parent
            z: 10000

            MouseArea {
                width: parent.width - 24
                height: 4
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                enabled: !window.isMaximized
                cursorShape: Qt.SizeVerCursor
                onPressed: window.startSystemResize(Qt.TopEdge)
            }

            MouseArea {
                width: parent.width - 24
                height: 4
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                enabled: !window.isMaximized
                cursorShape: Qt.SizeVerCursor
                onPressed: window.startSystemResize(Qt.BottomEdge)
            }

            MouseArea {
                width: 4
                height: parent.height - 24
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                enabled: !window.isMaximized
                cursorShape: Qt.SizeHorCursor
                onPressed: window.startSystemResize(Qt.LeftEdge)
            }

            MouseArea {
                width: 4
                height: parent.height - 24
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                enabled: !window.isMaximized
                cursorShape: Qt.SizeHorCursor
                onPressed: window.startSystemResize(Qt.RightEdge)
            }

            MouseArea {
                width: 12
                height: 12
                anchors.left: parent.left
                anchors.top: parent.top
                enabled: !window.isMaximized
                cursorShape: Qt.SizeFDiagCursor
                onPressed: window.startSystemResize(Qt.LeftEdge | Qt.TopEdge)
            }

            MouseArea {
                width: 12
                height: 12
                anchors.right: parent.right
                anchors.top: parent.top
                enabled: !window.isMaximized
                cursorShape: Qt.SizeBDiagCursor
                onPressed: window.startSystemResize(Qt.RightEdge | Qt.TopEdge)
            }

            MouseArea {
                width: 12
                height: 12
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                enabled: !window.isMaximized
                cursorShape: Qt.SizeBDiagCursor
                onPressed: window.startSystemResize(Qt.LeftEdge | Qt.BottomEdge)
            }

            MouseArea {
                width: 12
                height: 12
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                enabled: !window.isMaximized
                cursorShape: Qt.SizeFDiagCursor
                onPressed: window.startSystemResize(Qt.RightEdge | Qt.BottomEdge)
            }
        }
    }

    // ═════════════════════════════════════════════════════════════
    // 侧栏图标
    // ═════════════════════════════════════════════════════════════
    component NavIcon: Canvas {
        id: icon

        width: 22
        height: 22

        property int kind: 0
        property color strokeColor: Theme.textSecondary
        property real strokeWidth: 1.6

        onKindChanged: requestPaint()
        onStrokeColorChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = strokeColor
            ctx.fillStyle = strokeColor
            ctx.lineWidth = strokeWidth
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            var cx = width / 2
            var cy = height / 2
            var i
            var angle

            if (kind === 0) {
                ctx.beginPath()
                ctx.arc(cx, cy, 7.8, 0, Math.PI * 2)
                ctx.stroke()

                for (i = 0; i < 6; ++i) {
                    angle = -Math.PI / 2 + i * Math.PI / 3
                    ctx.beginPath()
                    ctx.moveTo(cx, cy)
                    ctx.lineTo(cx + Math.cos(angle) * 7.8,
                               cy + Math.sin(angle) * 7.8)
                    ctx.stroke()
                }

                ctx.beginPath()
                ctx.arc(cx, cy, 1.7, 0, Math.PI * 2)
                ctx.fill()

                ctx.beginPath()
                ctx.moveTo(cx, cy - 10.4)
                ctx.lineTo(cx - 2.7, cy - 7.2)
                ctx.lineTo(cx + 2.7, cy - 7.2)
                ctx.closePath()
                ctx.fill()
            } else if (kind === 1) {
                var rows = [6, 11, 16]
                for (i = 0; i < 3; ++i) {
                    ctx.beginPath()
                    ctx.arc(5.2, rows[i], 1.5, 0, Math.PI * 2)
                    ctx.fill()

                    ctx.beginPath()
                    ctx.moveTo(9.6, rows[i])
                    ctx.lineTo(i === 2 ? 14.5 : 18.2, rows[i])
                    ctx.stroke()
                }
            } else if (kind === 2) {
                ctx.beginPath()
                ctx.arc(cx, cy, 8.1, 0, Math.PI * 2)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(cx, cy)
                ctx.lineTo(cx, cy - 4.6)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(cx, cy)
                ctx.lineTo(cx + 3.3, cy + 2.1)
                ctx.stroke()

                ctx.beginPath()
                ctx.arc(cx, cy, 1.4, 0, Math.PI * 2)
                ctx.fill()
            } else if (kind === 3) {
                var ys = [5.8, 11, 16.2]
                var knobs = [8.4, 14.3, 10.4]
                for (i = 0; i < 3; ++i) {
                    ctx.beginPath()
                    ctx.moveTo(3.8, ys[i])
                    ctx.lineTo(knobs[i] - 3.2, ys[i])
                    ctx.moveTo(knobs[i] + 3.2, ys[i])
                    ctx.lineTo(18.2, ys[i])
                    ctx.stroke()

                    ctx.beginPath()
                    ctx.arc(knobs[i], ys[i], 2.4, 0, Math.PI * 2)
                    ctx.stroke()
                }
            } else {
                ctx.beginPath()
                ctx.arc(cx, cy, 6.3, 0, Math.PI * 2)
                ctx.stroke()

                for (i = 0; i < 8; ++i) {
                    angle = i * Math.PI / 4
                    ctx.beginPath()
                    ctx.moveTo(cx + Math.cos(angle) * 6.3,
                               cy + Math.sin(angle) * 6.3)
                    ctx.lineTo(cx + Math.cos(angle) * 8.4,
                               cy + Math.sin(angle) * 8.4)
                    ctx.stroke()
                }

                ctx.beginPath()
                ctx.arc(cx, cy, 2.6, 0, Math.PI * 2)
                ctx.stroke()
            }
        }
    }

    component NavItem: Item {
        id: nav

        width: 72
        height: 64

        property bool selected: false
        property int iconKind: 0
        property string label: ""
        signal triggered()

        Rectangle {
            id: navHalo
            width: 52
            height: 54
            radius: 14
            anchors.centerIn: parent
            color: nav.selected
                   ? Theme.primarySoft
                   : (navMouse.containsMouse ? Theme.surfaceAlt : Theme.transparent)
            scale: navMouse.pressed
                   ? 0.92
                   : (navMouse.containsMouse ? 1.02 : 1.0)

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }
        }

        Column {
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Item {
                width: parent.width
                height: 22

                NavIcon {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    kind: nav.iconKind
                    strokeColor: nav.selected
                                 ? Theme.primary
                                 : (navMouse.containsMouse
                                    ? Theme.textPrimary
                                    : Theme.textSecondary)
                }
            }

            Text {
                width: parent.width
                text: nav.label
                horizontalAlignment: Text.AlignHCenter
                color: nav.selected ? Theme.primary : Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontMicro
                font.weight: nav.selected ? Font.DemiBold : Font.Normal

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durationFast
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Rectangle {
            width: 4
            height: nav.selected ? 28 : 0
            radius: 2
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            opacity: nav.selected ? 1.0 : 0.0

            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Theme.primary }
                GradientStop { position: 1.0; color: Theme.primaryEnd }
            }

            Behavior on height {
                NumberAnimation {
                    duration: Theme.durationNormal
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }
        }

        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: nav.triggered()
        }
    }

    component TitleButton: Item {
        id: control

        width: 40
        height: 32

        property int iconKind: 0
        property bool restore: false
        property bool danger: false
        signal triggered()

        Rectangle {
            id: controlBackground
            anchors.fill: parent
            radius: Theme.radiusControl
            color: mouse.containsMouse
                   ? (control.danger ? Theme.dangerHover : Theme.surfaceAlt)
                   : Theme.transparent
            scale: mouse.pressed ? 0.92 : 1.0

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }

            Canvas {
                id: glyph
                width: 18
                height: 18
                anchors.centerIn: parent

                property int kind: control.iconKind
                property bool showRestore: control.restore
                property color iconColor: (control.danger && mouse.containsMouse)
                                          ? Theme.white
                                          : Theme.textPrimary

                onKindChanged: requestPaint()
                onShowRestoreChanged: requestPaint()
                onIconColorChanged: requestPaint()
                Component.onCompleted: requestPaint()

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = iconColor
                    ctx.lineWidth = 1.25
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"

                    if (kind === 0) {
                        ctx.beginPath()
                        ctx.moveTo(4, 9)
                        ctx.lineTo(14, 9)
                        ctx.stroke()
                    } else if (kind === 1) {
                        if (!showRestore) {
                            ctx.strokeRect(4.5, 4.5, 9, 9)
                        } else {
                            ctx.beginPath()
                            ctx.moveTo(6.5, 3.5)
                            ctx.lineTo(14, 3.5)
                            ctx.lineTo(14, 11)
                            ctx.stroke()

                            ctx.beginPath()
                            ctx.moveTo(3.5, 6.5)
                            ctx.lineTo(3.5, 14)
                            ctx.lineTo(11, 14)
                            ctx.lineTo(11, 6.5)
                            ctx.closePath()
                            ctx.stroke()
                        }
                    } else {
                        ctx.beginPath()
                        ctx.moveTo(4.5, 4.5)
                        ctx.lineTo(13.5, 13.5)
                        ctx.moveTo(13.5, 4.5)
                        ctx.lineTo(4.5, 13.5)
                        ctx.stroke()
                    }
                }
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.ArrowCursor
            onClicked: control.triggered()
        }
    }
}
