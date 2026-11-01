import QtQuick
import QtQuick.Window
import QtQuick.Controls

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
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowSystemMenuHint
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontBody

    // 原生命中测试读取这两个值：标题栏可拖动高度、右侧窗口按钮预留宽度。
    // 拖拽、吸附、还原、双击最大化全部由系统完成，QML 不再写窗口几何。
    property int captionHeight: Theme.titleBarHeight
    property int captionInset: 152

    readonly property int sidebarWidth: Theme.sidebarWidth
    readonly property int titleBarHeight: Theme.titleBarHeight

    readonly property bool maximized: visibility === Window.Maximized

    // 首次启动欢迎弹窗：启动页淡出后再弹出
    property bool welcomeRequested: false

    Component.onCompleted: welcomeRequested = backendBridge.isFirstRun()

    readonly property bool reducedMotion: {
        if (typeof backendBridge !== "undefined" && backendBridge)
            return !backendBridge.motionEnabled
        return false
    }

    property int currentPage: 0
    property int pendingPage: 0
    property bool resultOpen: false

    // 抽奖进行中（含结果弹窗未关闭）：左侧导航、顶栏按钮与整页点击均被锁住
    readonly property bool uiLocked: homePage.isDrawing

    function showResult(names) {
        resultCard.open(names)
    }

    function closeResult() {
        if (resultCard.opened)
            resultCard.close()
    }

    function navigate(page) {
        var target = Math.max(0, Math.min(7, page))
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
        if (window.maximized)
            window.showNormal()
        else
            window.showMaximized()
    }

    // 首次启动欢迎弹窗：弹出时写入标记文件，之后不再出现
    function openWelcome() {
        welcomeDialog.open()
        backendBridge.markFirstRunSeen()
    }

    Rectangle {
        id: windowPanel

        // 窗口内容层：最大化时铺满屏幕，窗口态时留 1px 边距与圆角
        anchors.fill: parent
        // 非最大化时留 1px 边距：圆角边缘的裁切不会咬掉内容
        anchors.margins: window.maximized ? 0 : 1
        radius: window.maximized ? 0 : Theme.radiusWindow
        color: Theme.background
        border.width: window.maximized ? 0 : 1
        border.color: Theme.withAlpha(Theme.textPrimary, 0.06)
        clip: true

        // 最大化时立即变直角，不要有过渡动画，避免四角瞬间露出桌面
        Behavior on radius {
            enabled: !window.maximized

            NumberAnimation {
                duration: Theme.durationFast
                easing.type: Easing.OutCubic
            }
        }

        // ─────────────────────────────────────────────────────────
        // 48px 自绘标题栏
        // 拖动与双击由 Win32 的 HTCAPTION 接管，这里只保留兜底
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
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onPressed: window.startSystemMove()
                onDoubleClicked: window.toggleMaximize()
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Theme.hairline
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Image {
                    width: 30
                    height: 30
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
                        color: Theme.textTertiary
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
                    enabled: !window.uiLocked
                    onTriggered: window.showMinimized()
                }

                TitleButton {
                    iconKind: 1
                    restore: window.maximized
                    enabled: !window.uiLocked
                    onTriggered: window.toggleMaximize()
                }

                TitleButton {
                    iconKind: 2
                    danger: true
                    enabled: !window.uiLocked
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

            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: 1
                color: Theme.hairline
            }

            Column {
                anchors.top: parent.top
                anchors.topMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                NavItem {
                    iconKind: 6
                    label: "主页"
                    selected: window.currentPage === 0
                    enabled: !window.uiLocked
                    onTriggered: window.navigate(0)
                }

                NavItem {
                    iconKind: 5
                    label: "添加"
                    selected: window.currentPage === 1
                    enabled: !window.uiLocked
                    onTriggered: window.navigate(1)
                }

                NavItem {
                    iconKind: 1
                    label: "名单"
                    selected: window.currentPage === 2
                    enabled: !window.uiLocked
                    onTriggered: window.navigate(2)
                }

                NavItem {
                    iconKind: 2
                    label: "历史"
                    selected: window.currentPage === 3
                    enabled: !window.uiLocked
                    onTriggered: window.navigate(3)
                }

                NavItem {
                    iconKind: 3
                    label: "工具"
                    selected: window.currentPage === 4
                    enabled: !window.uiLocked
                    onTriggered: window.navigate(4)
                }
            }

            Column {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                NavItem {
                    iconKind: 4
                    label: "设置"
                    selected: window.currentPage === 6
                    enabled: !window.uiLocked
                    onTriggered: window.navigate(6)
                }

                NavItem {
                    iconKind: 7
                    label: "关于"
                    selected: window.currentPage === 5
                    enabled: !window.uiLocked
                    onTriggered: window.navigate(5)
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

                Item {
                    id: pageStack
                    width: parent.width
                    height: parent.height
                    // 页面自身保持 anchors.fill: parent，切换时只切换可见性
                    property int currentIndex: 0

                    HomePage {
                        id: homePage
                        visible: pageStack.currentIndex === 0
                    }

                    AddPage {
                        id: addPage
                        visible: pageStack.currentIndex === 1

                        onWheelCreated: function(name, options) {
                            if (backendBridge.saveCustomWheel(name, options))
                                homePage.activateWheel(name)
                        }
                    }

                    RosterPage {
                        visible: pageStack.currentIndex === 2
                    }

                    HistoryPage {
                        visible: pageStack.currentIndex === 3
                    }

                    ToolsPage {
                        visible: pageStack.currentIndex === 4
                    }

                    AboutPage {
                        visible: pageStack.currentIndex === 5
                    }

                    SettingsPage {
                        visible: pageStack.currentIndex === 6
                    }

                    // 开发者控制台：只从设置页的隐藏入口进入，不占导航位
                    DeveloperPage {
                        visible: pageStack.currentIndex === 7
                    }
                }
            }

            // 抽奖期间整页拦截点击，避免连点穿帮
            Item {
                anchors.fill: parent
                z: 60
                visible: window.uiLocked

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    hoverEnabled: true
                    onWheel: function(wheel) { wheel.accepted = true }
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
    }

    // ═════════════════════════════════════════════════════════════
    // 中奖贺卡：挂载在窗口顶层，遮罩覆盖侧边栏与标题栏
    // ═════════════════════════════════════════════════════════════
    ResultCard {
        id: resultCard

        anchors.fill: windowPanel
        z: 95000

        onOpenedChanged: window.resultOpen = opened

        onCloseRequested: {
            homePage.lastWinners = []
            homePage.endDrawLock()
        }

        onContinueRequested: {
            homePage.lastWinners = []
            homePage.endDrawLock()
            homePage.startDraw()
        }
    }

    // ═════════════════════════════════════════════════════════════
    // 启动页：全屏浅色品牌页，2.5 秒后淡出
    // ═════════════════════════════════════════════════════════════
    Item {
        id: splashScreen

        anchors.fill: windowPanel
        z: 100000
        visible: true
        opacity: 1.0

        Rectangle {
            id: splashBackground
            anchors.fill: parent
            radius: window.maximized ? 0 : Theme.radiusWindow
            color: "#FAFBFC"
            clip: true

            Canvas {
                id: splashBackdrop
                anchors.fill: parent
                z: 0

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                Component.onCompleted: requestPaint()

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
                }
            }

            // 轻量光点：纯 Rectangle + NumberAnimation，不依赖 QtQuick.Particles
            Repeater {
                model: 14

                delegate: Rectangle {
                    id: splashDot

                    readonly property real startY: splashBackground.height
                                                      * (0.62 + 0.32 * ((index * 37) % 100) / 100)

                    x: splashBackground.width * ((index * 61) % 100) / 100
                    y: startY
                    width: 3 + index % 4
                    height: width
                    radius: width / 2
                    color: index % 3 === 0 ? "#8FC4FF" : "#A9E6D3"
                    opacity: 0.0
                    z: 1

                    NumberAnimation on y {
                        running: splashScreen.visible
                        loops: Animation.Infinite
                        from: splashDot.startY
                        to: splashDot.startY - splashBackground.height * 0.42
                        duration: 7000 + (index % 6) * 1100
                        easing.type: Easing.Linear
                    }

                    SequentialAnimation on opacity {
                        running: splashScreen.visible
                        loops: Animation.Infinite

                        NumberAnimation {
                            from: 0.0
                            to: 0.55
                            duration: 1800 + (index % 4) * 320
                            easing.type: Easing.InOutSine
                        }

                        NumberAnimation {
                            from: 0.55
                            to: 0.0
                            duration: 2600 + (index % 3) * 420
                            easing.type: Easing.InOutSine
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                width: 400
                spacing: 0
                z: 2

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
                        scale: 1.0

                        NumberAnimation on scale {
                            from: 0.94
                            to: 1.0
                            duration: 760
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Item { width: 1; height: 20 }

                Text {
                    id: splashTitle
                    width: parent.width
                    text: "撷签"
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

        NumberAnimation {
            id: progressAnimation
            target: progressFill
            property: "width"
            from: 0
            to: progressTrack.width
            duration: 1200
            easing.type: Easing.InOutCubic
            running: true
        }

        Timer {
            interval: 1400
            running: true
            repeat: false
            onTriggered: splashFadeOut.start()
        }

        NumberAnimation {
            id: splashFadeOut
            target: splashScreen
            property: "opacity"
            to: 0.0
            duration: 420
            easing.type: Easing.OutCubic

            onFinished: {
                splashScreen.visible = false
                if (window.welcomeRequested)
                    window.openWelcome()
            }
        }
    }

    // ═════════════════════════════════════════════════════════════
    // 首次启动欢迎弹窗：显示后写入 first_run.flag，此后不再出现
    // ═════════════════════════════════════════════════════════════
    WelcomeDialog {
        id: welcomeDialog

        anchors.fill: windowPanel
        z: 99000
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

        opacity: enabled ? 1.0 : 0.42

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durationFast
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: navHalo
            width: 58
            height: 58
            radius: Theme.radiusCard
            anchors.centerIn: parent
            color: nav.selected
                   ? Theme.primarySoft
                   : (navMouse.containsMouse ? Theme.fill : Theme.transparent)
            scale: navMouse.pressed
                   ? 0.94
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

        opacity: enabled ? 1.0 : 0.4

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durationFast
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: controlBackground
            anchors.fill: parent
            radius: 10
            color: mouse.containsMouse
                   ? (control.danger ? Theme.dangerHover : Theme.fill)
                   : Theme.transparent
            scale: mouse.pressed ? 0.94 : 1.0

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
