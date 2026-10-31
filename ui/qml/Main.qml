import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "."
import "pages"
import "components"

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
    property bool resultOpen: false

    function showResult(names) {
        resultCard.open(names)
    }

    function closeResult() {
        if (resultCard.opened)
            resultCard.close()
    }

    function navigate(page) {
        var target = Math.max(0, Math.min(6, page))
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

                Image {
                    width: 32
                    height: 32
                    source: "qrc:/ui/assets/app-icon-512.png"
                    sourceSize.width: 96
                    sourceSize.height: 96
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
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
                anchors.topMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                NavItem {
                    iconKind: 6
                    label: "主页"
                    selected: window.currentPage === 0
                    onTriggered: window.navigate(0)
                }

                NavItem {
                    iconKind: 5
                    label: "添加"
                    selected: window.currentPage === 1
                    onTriggered: window.navigate(1)
                }

                NavItem {
                    iconKind: 1
                    label: "名单"
                    selected: window.currentPage === 2
                    onTriggered: window.navigate(2)
                }

                NavItem {
                    iconKind: 2
                    label: "历史"
                    selected: window.currentPage === 3
                    onTriggered: window.navigate(3)
                }

                NavItem {
                    iconKind: 3
                    label: "工具"
                    selected: window.currentPage === 4
                    onTriggered: window.navigate(4)
                }
            }

            Column {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                NavItem {
                    iconKind: 7
                    label: "关于"
                    selected: window.currentPage === 5
                    onTriggered: window.navigate(5)
                }

                NavItem {
                    iconKind: 4
                    label: "设置"
                    selected: window.currentPage === 6
                    onTriggered: window.navigate(6)
                }
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

                    HomePage {
                        id: homePage
                    }

                    AddPage {
                        id: addPage

                        onWheelCreated: function(name, options) {
                            if (backendBridge.saveCustomWheel(name, options))
                                homePage.activateWheel(name)
                        }
                    }

                    RosterPage {}
                    HistoryPage {}
                    ToolsPage {}
                    AboutPage {}
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
    // 中奖贺卡：挂载在窗口顶层，遮罩覆盖侧边栏与标题栏
    // ═════════════════════════════════════════════════════════════
    ResultCard {
        id: resultCard
        anchors.fill: parent
        z: 95000

        onOpenedChanged: window.resultOpen = opened

        onCloseRequested: homePage.lastWinners = []

        onContinueRequested: {
            homePage.lastWinners = []
            homePage.startDraw()
        }
    }

    // ═════════════════════════════════════════════════════════════
    // 启动页：全屏浅色品牌页，2.5 秒后淡出
    // ═════════════════════════════════════════════════════════════
    Item {
        id: splashScreen
        anchors.fill: parent
        z: 100000
        visible: true
        opacity: 1.0

        Rectangle {
            id: splashBackground
            anchors.fill: parent
            radius: window.isMaximized ? 0 : Theme.radiusWindow
            color: "#FAFBFC"
            clip: true

            Canvas {
                id: splashBackdrop
                anchors.fill: parent

                // 固定种子生成，窗口缩放时粒子位置不会抽动
                property var particles: []

                function seedParticles() {
                    // Lehmer LCG：乘数小于 2^16，乘积不超 2^47，不会丢精度
                    var seed = 20260301
                    var list = []
                    for (var i = 0; i < 56; ++i) {
                        seed = (seed * 48271) % 2147483647
                        var x = seed / 2147483647
                        seed = (seed * 48271) % 2147483647
                        var y = seed / 2147483647
                        seed = (seed * 48271) % 2147483647
                        var radius = 0.7 + (seed / 2147483647) * 2.0
                        seed = (seed * 48271) % 2147483647
                        var alpha = 0.02 + (seed / 2147483647) * 0.055
                        list.push({ "x": x, "y": y, "r": radius,
                                    "a": alpha, "green": (i % 4 === 0) })
                    }
                    particles = list
                }

                Component.onCompleted: {
                    seedParticles()
                    requestPaint()
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                onPaint: {
                    if (width <= 0 || height <= 0)
                        return

                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var cx = width / 2
                    var cy = height * 0.44
                    var glow = ctx.createRadialGradient(cx, cy, 0,
                                                        cx, cy,
                                                        Math.max(width, height) * 0.56)
                    glow.addColorStop(0, "rgba(59,139,246,0.075)")
                    glow.addColorStop(0.52, "rgba(46,212,165,0.028)")
                    glow.addColorStop(1, "rgba(59,139,246,0)")
                    ctx.fillStyle = glow
                    ctx.fillRect(0, 0, width, height)

                    for (var i = 0; i < particles.length; ++i) {
                        var p = particles[i]
                        ctx.beginPath()
                        ctx.arc(p.x * width, p.y * height, p.r, 0, Math.PI * 2)
                        ctx.fillStyle = p.green
                                        ? "rgba(46,212,165," + p.a + ")"
                                        : "rgba(59,139,246," + p.a + ")"
                        ctx.fill()
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                width: 400
                spacing: 0

                Item {
                    width: parent.width
                    height: 168

                    Image {
                        id: splashLogo
                        anchors.centerIn: parent
                        width: 152
                        height: 152
                        source: "qrc:/ui/assets/app-icon-512.png"
                        sourceSize.width: 512
                        sourceSize.height: 512
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                        opacity: 0.0
                        scale: 0.96
                    }
                }

                Item { width: 1; height: 20 }

                Text {
                    id: splashTitle
                    width: parent.width
                    text: "撷签"
                    opacity: 0.0
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 36
                    font.weight: Font.Bold
                    font.letterSpacing: 3
                }

                Item { width: 1; height: 6 }

                Text {
                    id: splashSubtitle
                    width: parent.width
                    text: "XIE QIAN"
                    opacity: 0.0
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.letterSpacing: 5
                }

                Item { width: 1; height: 14 }

                Text {
                    id: splashTagline
                    width: parent.width
                    text: "让每一次选择，都值得期待"
                    opacity: 0.0
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                }

                Item { width: 1; height: 34 }

                Item {
                    width: parent.width
                    height: 6

                    Rectangle {
                        id: progressTrack
                        width: 252
                        height: 6
                        radius: 3
                        anchors.centerIn: parent
                        color: "#DDE1E6"

                        Rectangle {
                            id: progressFill
                            width: 0
                            height: parent.height
                            radius: parent.radius
                            gradient: Theme.primaryGradient
                        }
                    }
                }

                Item { width: 1; height: 14 }

                Text {
                    id: splashStatus
                    width: parent.width
                    text: "正在准备签盘"
                    opacity: 0.0
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.letterSpacing: 1
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: false
            onWheel: function(wheel) {
                wheel.accepted = true
            }
        }

        SequentialAnimation {
            id: splashIntro
            running: true

            PauseAnimation { duration: 100 }

            ParallelAnimation {
                NumberAnimation {
                    target: splashLogo
                    property: "opacity"
                    to: 1.0
                    duration: 620
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: splashLogo
                    property: "scale"
                    to: 1.0
                    duration: 760
                    easing.type: Easing.OutCubic
                }
            }

            ParallelAnimation {
                NumberAnimation {
                    target: splashTitle
                    property: "opacity"
                    to: 1.0
                    duration: 300
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: splashSubtitle
                    property: "opacity"
                    to: 1.0
                    duration: 340
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: splashTagline
                    property: "opacity"
                    to: 1.0
                    duration: 380
                    easing.type: Easing.OutCubic
                }
            }

            NumberAnimation {
                target: splashStatus
                property: "opacity"
                to: 1.0
                duration: 240
                easing.type: Easing.OutCubic
            }
        }

        NumberAnimation {
            id: progressAnimation
            target: progressFill
            property: "width"
            from: 0
            to: progressTrack.width
            duration: 2400
            easing.type: Easing.InOutCubic
            running: true
        }

        Timer {
            interval: 2500
            running: true
            repeat: false
            onTriggered: splashFadeOut.start()
        }

        NumberAnimation {
            id: splashFadeOut
            target: splashScreen
            property: "opacity"
            to: 0.0
            duration: 460
            easing.type: Easing.OutCubic
            onFinished: splashScreen.visible = false
        }
    }

    // ═════════════════════════════════════════════════════════════
    // 侧栏图标
    // ═════════════════════════════════════════════════════════════
    component NavIcon: Canvas {
        id: icon

        width: 26
        height: 26

        property int kind: 0
        property color strokeColor: Theme.textSecondary
        property real strokeWidth: 1.6

        onKindChanged: requestPaint()
        onStrokeColorChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            // Canvas 上下文在多次 paint 间复用，先重置变换，避免 scale 累积
            ctx.setTransform(1, 0, 0, 1, 0, 0)
            ctx.clearRect(0, 0, width, height)
            ctx.scale(width / 22, height / 22)
            ctx.strokeStyle = strokeColor
            ctx.fillStyle = strokeColor
            ctx.lineWidth = strokeWidth
            ctx.lineCap = "round"
            ctx.lineJoin = "round"

            var cx = 11
            var cy = 11
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
            } else if (kind === 4) {
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
            } else if (kind === 5) {
                // 极简 “+”，用于「添加」导航项
                ctx.lineWidth = 1.9
                ctx.beginPath()
                ctx.moveTo(cx, 4.6)
                ctx.lineTo(cx, 17.4)
                ctx.moveTo(4.6, cy)
                ctx.lineTo(17.4, cy)
                ctx.stroke()
            } else if (kind === 6) {
                // 房子，用于「主页」导航项
                ctx.beginPath()
                ctx.moveTo(3.6, 10.8)
                ctx.lineTo(11, 4.2)
                ctx.lineTo(18.4, 10.8)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(5.9, 9.8)
                ctx.lineTo(5.9, 17.6)
                ctx.lineTo(16.1, 17.6)
                ctx.lineTo(16.1, 9.8)
                ctx.stroke()
            } else if (kind === 7) {
                // 圆圈 + 圆点 + 竖线，用于「关于」导航项
                ctx.beginPath()
                ctx.arc(cx, cy, 8.1, 0, Math.PI * 2)
                ctx.stroke()

                ctx.beginPath()
                ctx.arc(cx, cy - 4.3, 1.25, 0, Math.PI * 2)
                ctx.fill()

                ctx.beginPath()
                ctx.moveTo(cx, cy - 1.2)
                ctx.lineTo(cx, cy + 4.7)
                ctx.stroke()
            }
        }
    }

    component NavItem: Item {
        id: nav

        width: Theme.sidebarWidth
        height: 68

        property bool selected: false
        property int iconKind: 0
        property string label: ""
        signal triggered()

        Rectangle {
            id: navHalo
            width: 58
            height: 58
            radius: 16
            anchors.centerIn: parent
            color: nav.selected
                   ? Theme.primarySoft
                   : (navMouse.containsMouse ? Theme.surfaceAlt : Theme.transparent)
            scale: navMouse.pressed
                   ? 0.95
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
            spacing: 4

            Item {
                width: parent.width
                height: 26

                NavIcon {
                    anchors.centerIn: parent
                    width: 26
                    height: 26
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
                font.pixelSize: 13
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
            scale: mouse.pressed ? 0.95 : 1.0

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
