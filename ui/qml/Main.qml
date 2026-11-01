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

    // 自定义最大化：不使用系统 showMaximized()，避免无边框窗口原生切换时
    // 内容裁切、黑屏与长时间卡顿
    property bool isMaximized: false
    property bool dragging: false
    property bool resizing: false
    property rect normalGeometry: Qt.rect(0, 0, 1200, 800)
    // 创建阶段关闭动画，避免初始 1200x800 被当成一次变更而产生启动缩放
    property bool windowReady: false

    // 手写拖拽 / 缩放期间关闭几何动画，避免与鼠标位移产生黏滞
    readonly property bool geometryAnimationEnabled: windowReady && !dragging && !resizing

    Component.onCompleted: windowReady = true

    Behavior on x {
        enabled: window.geometryAnimationEnabled
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    Behavior on y {
        enabled: window.geometryAnimationEnabled
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    Behavior on width {
        enabled: window.geometryAnimationEnabled
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    Behavior on height {
        enabled: window.geometryAnimationEnabled
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

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
        if (isMaximized) {
            isMaximized = false
            x = normalGeometry.x
            y = normalGeometry.y
            width = normalGeometry.width
            height = normalGeometry.height
            return
        }

        // 记录当前几何，供还原动画使用
        normalGeometry = Qt.rect(x, y, width, height)
        isMaximized = true

        var screenWidth = Screen.desktopAvailableWidth
        var screenHeight = Screen.desktopAvailableHeight
        if (!(screenWidth > 0) || !(screenHeight > 0)) {
            screenWidth = window.screen ? window.screen.width : width
            screenHeight = window.screen ? window.screen.height : height
        }

        x = 0
        y = 0
        width = screenWidth
        height = screenHeight
    }

    Rectangle {
        id: windowPanel

        // 直接跟随窗口尺寸而不是父节点：即使无边框窗口在极短时间内完成尺寸切换，
        // 也不会因为内容层尺寸滞后而出现整页错位
        anchors.top: parent.top
        anchors.left: parent.left
        width: window.width
        height: window.height
        radius: window.isMaximized ? 0 : Theme.radiusWindow
        color: Theme.background
        border.width: window.isMaximized ? 0 : 1
        border.color: Theme.withAlpha(Theme.textPrimary, 0.06)
        clip: true

        // 最大化时立即变直角，不要有过渡动画，避免四角瞬间露出桌面
        Behavior on radius {
            enabled: !window.isMaximized

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
                property point pressWindow
                property point pressGlobal

                onPressed: function(mouse) {
                    pressPoint = Qt.point(mouse.x, mouse.y)
                    pressWindow = Qt.point(window.x, window.y)
                    pressGlobal = Qt.point(window.x + mouse.x, window.y + mouse.y)
                    window.dragging = false
                }

                onPositionChanged: function(mouse) {
                    if (!pressed)
                        return

                    if (!window.dragging
                            && Math.abs(mouse.x - pressPoint.x) <= 2
                            && Math.abs(mouse.y - pressPoint.y) <= 2)
                        return

                    // 最大化窗口不支持拖动，避免与还原动画互相干扰
                    if (window.isMaximized)
                        return

                    window.dragging = true

                    // 用指针的屏幕坐标驱动窗口位置：窗口跟随指针后，
                    // mouse 坐标也会随窗口一起变化，直接累加增量会抖动
                    var globalX = window.x + mouse.x
                    var globalY = window.y + mouse.y
                    window.x = Math.round(pressWindow.x + globalX - pressGlobal.x)
                    window.y = Math.round(pressWindow.y + globalY - pressGlobal.y)
                }

                onReleased: window.dragging = false
                onCanceled: window.dragging = false

                onDoubleClicked: function(mouse) {
                    if (window.dragging)
                        return
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
                    iconKind: 4
                    label: "设置"
                    selected: window.currentPage === 6
                    onTriggered: window.navigate(6)
                }

                NavItem {
                    iconKind: 7
                    label: "关于"
                    selected: window.currentPage === 5
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
        // 八方向缩放热区：手写几何拖拽，不依赖系统 startSystemResize()
        // ─────────────────────────────────────────────────────────
        Item {
            id: resizeBorders

            anchors.fill: parent
            z: 10000
            // 最大化时整个缩放热区失效，避免抢占标题栏与内容区的鼠标事件
            visible: !window.isMaximized

            ResizeHandle {
                width: parent.width - 24
                height: 5
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                edgeTop: true
                cursorShape: Qt.SizeVerCursor
            }

            ResizeHandle {
                width: parent.width - 24
                height: 5
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                edgeBottom: true
                cursorShape: Qt.SizeVerCursor
            }

            ResizeHandle {
                width: 5
                height: parent.height - 24
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                edgeLeft: true
                cursorShape: Qt.SizeHorCursor
            }

            ResizeHandle {
                width: 5
                height: parent.height - 24
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                edgeRight: true
                cursorShape: Qt.SizeHorCursor
            }

            ResizeHandle {
                width: 12
                height: 12
                anchors.left: parent.left
                anchors.top: parent.top
                edgeLeft: true
                edgeTop: true
                cursorShape: Qt.SizeFDiagCursor
            }

            ResizeHandle {
                width: 12
                height: 12
                anchors.right: parent.right
                anchors.top: parent.top
                edgeRight: true
                edgeTop: true
                cursorShape: Qt.SizeBDiagCursor
            }

            ResizeHandle {
                width: 12
                height: 12
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                edgeLeft: true
                edgeBottom: true
                cursorShape: Qt.SizeBDiagCursor
            }

            ResizeHandle {
                width: 12
                height: 12
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                edgeRight: true
                edgeBottom: true
                cursorShape: Qt.SizeFDiagCursor
            }
        }
    }

    // ═════════════════════════════════════════════════════════════
    // 手写缩放：按下时记录窗口几何，拖动时把指针位移换算成四边变化
    // ═════════════════════════════════════════════════════════════
    component ResizeHandle: MouseArea {
        id: handle

        property bool edgeLeft: false
        property bool edgeRight: false
        property bool edgeTop: false
        property bool edgeBottom: false

        property point pressGlobal
        property rect startGeometry

        hoverEnabled: true
        enabled: !window.isMaximized

        onPressed: function(mouse) {
            pressGlobal = Qt.point(window.x + mouse.x, window.y + mouse.y)
            startGeometry = Qt.rect(window.x, window.y, window.width, window.height)
            window.resizing = true
        }

        onPositionChanged: function(mouse) {
            if (!pressed)
                return

            // 指针的屏幕坐标：窗口移动后 mouse 会随之变化，加回窗口坐标才是真实位置
            var dx = (window.x + mouse.x) - pressGlobal.x
            var dy = (window.y + mouse.y) - pressGlobal.y

            var nextX = startGeometry.x
            var nextY = startGeometry.y
            var nextWidth = startGeometry.width
            var nextHeight = startGeometry.height

            if (handle.edgeLeft) {
                nextX = startGeometry.x + dx
                nextWidth = startGeometry.width - dx
            } else if (handle.edgeRight) {
                nextWidth = startGeometry.width + dx
            }

            if (handle.edgeTop) {
                nextY = startGeometry.y + dy
                nextHeight = startGeometry.height - dy
            } else if (handle.edgeBottom) {
                nextHeight = startGeometry.height + dy
            }

            if (nextWidth < window.minimumWidth) {
                nextWidth = window.minimumWidth
                if (handle.edgeLeft)
                    nextX = startGeometry.x + startGeometry.width - nextWidth
            }
            if (nextHeight < window.minimumHeight) {
                nextHeight = window.minimumHeight
                if (handle.edgeTop)
                    nextY = startGeometry.y + startGeometry.height - nextHeight
            }

            window.x = Math.round(nextX)
            window.y = Math.round(nextY)
            window.width = Math.round(nextWidth)
            window.height = Math.round(nextHeight)
        }

        onReleased: window.resizing = false
        onCanceled: window.resizing = false
    }

    // ═════════════════════════════════════════════════════════════
    // 中奖贺卡：挂载在窗口顶层，遮罩覆盖侧边栏与标题栏
    // ═════════════════════════════════════════════════════════════
    ResultCard {
        id: resultCard

        x: 0
        y: 0
        width: window.width
        height: window.height
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

        x: 0
        y: 0
        width: window.width
        height: window.height
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
                z: 1

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
                        var radius = 1.2 + (seed / 2147483647) * 2.4
                        seed = (seed * 48271) % 2147483647
                        var alpha = 0.08 + (seed / 2147483647) * 0.14
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
                onVisibleChanged: if (visible) requestPaint()

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
            width: 3
            height: nav.selected ? 26 : 0
            radius: 1.5
            anchors.left: parent.left
            anchors.leftMargin: 10
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
