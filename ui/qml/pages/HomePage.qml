import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects

import ".."
import "../components"

// 放置路径：ui/qml/pages/HomePage.qml
// 集成：Main.qml 增加 import "pages"；qml.qrc 增加本文件及 components 下的三个组件。

/*!
    抽签主页面。
    舞台分别由 WheelItem / FlipCardItem / BlindBoxItem 承载，
    大转盘、翻牌、盲盒的 startSpin()/startFlip()/startOpen() 与 finished() 回调在此统一编排。
*/
Item {
    id: page

    // ─────────────────────────────────────────────────────────────
    // 页面状态
    // ─────────────────────────────────────────────────────────────
    property bool busy: false
    property var lastWinners: []
    property var pendingWinners: []

    readonly property bool isEmpty: backendBridge.rosterCount === 0
    readonly property int drawMode: {
        var mode = Number(backendBridge.currentDrawMode)
        return (mode === 1 || mode === 2) ? mode : 0
    }
    readonly property string modeTitle: {
        if (drawMode === 1)
            return "翻牌抽签"
        if (drawMode === 2)
            return "盲盒开箱"
        return "大转盘"
    }
    readonly property string modeHint: {
        if (drawMode === 1)
            return "翻开一张，看看今天是谁的幸运时刻"
        if (drawMode === 2)
            return "挑一个盲盒，揭晓课堂里的小惊喜"
        return "转动签盘，把选择交给一点点运气"
    }

    signal importRosterRequested()

    // ─────────────────────────────────────────────────────────────
    // 抽签逻辑
    // ─────────────────────────────────────────────────────────────
    function selectMode(index) {
        if (busy)
            return
        if (index < 0 || index > 2)
            return
        if (backendBridge.currentDrawMode === index)
            return
        backendBridge.currentDrawMode = index
    }

    function startDraw() {
        if (busy || isEmpty)
            return

        busy = true
        lastWinners = []
        pendingWinners = []

        if (drawMode === 0) {
            wheelItem.startSpin()
        } else if (drawMode === 1) {
            flipCard.winnerName = ""
            flipCard.startFlip()
        } else {
            blindBox.winnerName = ""
            blindBox.startOpen()
        }

        safetyTimer.restart()
    }

    function drawAndReveal() {
        if (!busy)
            return

        if (backendBridge.drawCount > 1)
            backendBridge.drawMultipleWinners()
        else
            backendBridge.drawWinner()
    }

    function normalizeWinners(names) {
        var list = []
        if (names !== undefined && names !== null) {
            if (typeof names === "string") {
                if (names.length > 0)
                    list.push(names)
            } else {
                for (var i = 0; i < names.length; ++i) {
                    var name = String(names[i])
                    if (name.length > 0)
                        list.push(name)
                }
            }
        }
        return list
    }

    function handleWinners(names) {
        var list = normalizeWinners(names)
        pendingWinners = list

        if (drawMode === 1 && flipCard)
            flipCard.winnerName = list.length > 0 ? list[0] : ""
        else if (drawMode === 2 && blindBox)
            blindBox.winnerName = list.length > 0 ? list[0] : ""

        if (!busy) {
            lastWinners = list
            return
        }

        if (drawMode === 0)
            finishDraw()
    }

    function finishDraw() {
        if (!busy)
            return

        busy = false
        lastWinners = pendingWinners
        pendingWinners = []
        safetyTimer.stop()

        if (lastWinners.length > 0)
            resultCard.open(lastWinners)
    }

    function winnerSummary() {
        if (lastWinners.length === 0)
            return ""

        var head = lastWinners.slice(0, 3).join("、")
        if (lastWinners.length > 3)
            head += " 等 " + lastWinners.length + " 人"
        return head
    }

    function goToRoster() {
        importRosterRequested()
        if (Window.window && typeof Window.window.navigate === "function")
            Window.window.navigate(1)
    }

    onDrawModeChanged: {
        if (!isEmpty && modeReveal)
            modeReveal.restart()
    }

    onIsEmptyChanged: {
        if (isEmpty) {
            busy = false
            lastWinners = []
            pendingWinners = []
            if (safetyTimer)
                safetyTimer.stop()
            if (flipCard)
                flipCard.reset()
            if (blindBox)
                blindBox.reset()
            if (resultCard && resultCard.opened)
                resultCard.close()
        } else if (modeReveal) {
            modeReveal.restart()
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 顶层布局
    // ─────────────────────────────────────────────────────────────
    Item {
        id: pageContent
        anchors.fill: parent
        anchors.margins: Theme.pagePadding

        ModeSwitcher {
            id: modeSwitcher
            width: Math.min(360, pageContent.width)
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            currentIndex: page.drawMode
            interactive: !page.busy
            opacity: page.busy ? 0.65 : 1.0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durationNormal
                    easing.type: Easing.OutCubic
                }
            }

            onSelected: function(index) {
                page.selectMode(index)
            }
        }

        Column {
            id: footer
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            spacing: 14

            Item {
                width: parent.width
                height: 20

                RowLayout {
                    id: shortcutHint
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Rectangle {
                        id: statusDot
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 6
                        Layout.preferredHeight: 6
                        radius: 3
                        color: page.busy
                               ? Theme.primary
                               : (page.isEmpty ? Theme.textTertiary : Theme.success)

                        SequentialAnimation on opacity {
                            running: page.busy
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.25; duration: 480; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 480; easing.type: Easing.InOutSine }
                            onStopped: statusDot.opacity = 1.0
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.durationFast
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Rectangle {
                        visible: !page.busy && !page.isEmpty
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 20
                        radius: 6
                        color: Theme.surface
                        border.width: 1
                        border.color: Theme.border

                        Text {
                            anchors.centerIn: parent
                            text: "Space"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.letterSpacing: 0.6
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: page.busy
                              ? "签运流转中，请稍候…"
                              : (page.isEmpty ? "导入名单后即可开始" : "快速抽取")
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontCaption

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.durationFast
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: 56

                PrimaryDrawButton {
                    anchors.centerIn: parent
                    active: !page.isEmpty && !page.busy
                    label: page.isEmpty ? "暂无数据" : "开始抽取"
                    onClicked: page.startDraw()
                }
            }
        }

        // ─────────────────────────────────────────────────────────
        // 中央舞台
        // ─────────────────────────────────────────────────────────
        Rectangle {
            id: stageCard
            anchors.top: modeSwitcher.bottom
            anchors.topMargin: 20
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: footer.top
            anchors.bottomMargin: 20
            radius: Theme.radiusCard
            color: Theme.surface
            border.width: 1
            border.color: Theme.withAlpha(Theme.textPrimary, 0.045)
            clip: true

            // 舞台右上角的柔和光晕，避免纯白大面积显得空
            Canvas {
                anchors.fill: parent
                opacity: 0.9
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                onPaint: {
                    if (width <= 0 || height <= 0)
                        return

                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var glow = ctx.createRadialGradient(width * 0.82, height * 0.08,
                                                        0, width * 0.82, height * 0.08,
                                                        Math.max(width, height) * 0.58)
                    glow.addColorStop(0, "rgba(59,139,246,0.055)")
                    glow.addColorStop(0.50, "rgba(46,212,165,0.025)")
                    glow.addColorStop(1, "rgba(59,139,246,0)")
                    ctx.fillStyle = glow
                    ctx.fillRect(0, 0, width, height)
                }
            }

            // 舞台标题
            Item {
                id: stageHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 68

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        text: page.modeTitle
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontH2
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: page.modeHint
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontCaption
                        elide: Text.ElideRight
                        width: Math.max(0, Math.min(implicitWidth, stageCard.width - 260))
                    }
                }

                Rectangle {
                    id: countPill
                    anchors.right: parent.right
                    anchors.rightMargin: 24
                    anchors.verticalCenter: parent.verticalCenter
                    height: 28
                    width: countPillRow.implicitWidth + 20
                    radius: 14
                    color: Theme.surfaceAlt

                    RowLayout {
                        id: countPillRow
                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 6
                            Layout.preferredHeight: 6
                            radius: 3
                            color: page.busy
                                   ? Theme.primary
                                   : (page.isEmpty ? Theme.textTertiary : Theme.success)

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.durationFast
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: page.busy
                                  ? "抽取中"
                                  : "名单 " + backendBridge.rosterCount + " 人"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontMicro
                        }
                    }
                }
            }

            Item {
                id: stageBody
                anchors.top: stageHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 16
                clip: true

                // 三种模式舞台
                Item {
                    id: modeViewport
                    anchors.fill: parent
                    visible: !page.isEmpty
                    opacity: 1.0
                    transformOrigin: Item.Center

                    StackLayout {
                        id: modeStack
                        anchors.fill: parent
                        currentIndex: page.drawMode

                        // ── 大转盘 ──
                        Item {
                            id: wheelSlot

                            WheelItem {
                                id: wheelItem
                                anchors.centerIn: parent
                                width: Math.max(0, Math.min(parent.width, parent.height) * 0.92)
                                height: width
                                showPointer: true
                                onFinished: page.drawAndReveal()
                            }
                        }

                        // ── 翻牌抽签 ──
                        Item {
                            id: flipSlot

                            FlipCardItem {
                                id: flipCard
                                anchors.fill: parent
                                onShuffleFinished: page.drawAndReveal()
                                onFinished: page.finishDraw()
                            }
                        }

                        // ── 盲盒开箱 ──
                        Item {
                            id: blindBoxSlot

                            BlindBoxItem {
                                id: blindBox
                                anchors.fill: parent
                                onBoxSelected: page.drawAndReveal()
                                onFinished: page.finishDraw()
                            }
                        }
                    }
                }

                // 空状态
                Item {
                    id: emptyState
                    anchors.fill: parent
                    anchors.margins: 8
                    opacity: page.isEmpty ? 1.0 : 0.0
                    scale: page.isEmpty ? 1.0 : 0.98
                    visible: opacity > 0.01

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.durationNormal
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.durationNormal
                            easing.type: Easing.OutCubic
                        }
                    }

                    Column {
                        width: Math.min(300, parent.width)
                        anchors.centerIn: parent
                        spacing: 10

                        Item {
                            width: parent.width
                            height: 150

                            Canvas {
                                width: 200
                                height: 150
                                anchors.centerIn: parent
                                onWidthChanged: requestPaint()
                                onHeightChanged: requestPaint()

                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)

                                    var cx = width / 2
                                    var cy = height / 2
                                    var pi2 = Math.PI * 2

                                    // 柔和光晕
                                    var halo = ctx.createRadialGradient(cx, cy - 8, 4,
                                                                        cx, cy - 8, width * 0.46)
                                    halo.addColorStop(0, "rgba(59,139,246,0.075)")
                                    halo.addColorStop(0.55, "rgba(46,212,165,0.035)")
                                    halo.addColorStop(1, "rgba(59,139,246,0)")
                                    ctx.fillStyle = halo
                                    ctx.beginPath()
                                    ctx.arc(cx, cy - 8, width * 0.46, 0, pi2)
                                    ctx.fill()

                                    // 地面投影
                                    ctx.save()
                                    ctx.translate(cx, cy + 58)
                                    ctx.scale(1, 0.22)
                                    ctx.beginPath()
                                    ctx.arc(0, 0, 42, 0, pi2)
                                    ctx.fillStyle = "rgba(31,35,41,0.055)"
                                    ctx.fill()
                                    ctx.restore()

                                    var jarTop = cy - 4
                                    var jarBottom = cy + 56
                                    var halfW = 36

                                    // 签筒筒身
                                    ctx.beginPath()
                                    ctx.moveTo(cx - halfW, jarTop)
                                    ctx.lineTo(cx - halfW + 5, jarBottom - 10)
                                    ctx.quadraticCurveTo(cx, jarBottom + 3, cx + halfW - 5, jarBottom - 10)
                                    ctx.lineTo(cx + halfW, jarTop)
                                    ctx.closePath()
                                    var bodyFill = ctx.createLinearGradient(cx - halfW, 0, cx + halfW, 0)
                                    bodyFill.addColorStop(0, "#FFFFFF")
                                    bodyFill.addColorStop(0.55, "#FBFCFE")
                                    bodyFill.addColorStop(1, "#F2F6FB")
                                    ctx.fillStyle = bodyFill
                                    ctx.fill()
                                    ctx.strokeStyle = "#DDE2E8"
                                    ctx.lineWidth = 1.4
                                    ctx.stroke()

                                    // 签条
                                    ctx.lineCap = "round"
                                    ctx.lineWidth = 3

                                    ctx.strokeStyle = "#D5DCE5"
                                    ctx.beginPath()
                                    ctx.moveTo(cx - 15, jarTop + 10)
                                    ctx.lineTo(cx - 21, cy - 52)
                                    ctx.stroke()

                                    ctx.strokeStyle = "#9CC3F5"
                                    ctx.beginPath()
                                    ctx.moveTo(cx + 1, jarTop + 10)
                                    ctx.lineTo(cx + 5, cy - 62)
                                    ctx.stroke()

                                    ctx.strokeStyle = "#C7D2DF"
                                    ctx.beginPath()
                                    ctx.moveTo(cx + 16, jarTop + 10)
                                    ctx.lineTo(cx + 22, cy - 48)
                                    ctx.stroke()

                                    // 筒口
                                    ctx.save()
                                    ctx.translate(cx, jarTop)
                                    ctx.scale(1, 0.30)
                                    ctx.beginPath()
                                    ctx.arc(0, 0, halfW, 0, pi2)
                                    ctx.restore()
                                    ctx.fillStyle = "#FFFFFF"
                                    ctx.fill()
                                    ctx.strokeStyle = "#DDE2E8"
                                    ctx.lineWidth = 1.4
                                    ctx.stroke()

                                    // 筒口内侧
                                    ctx.save()
                                    ctx.translate(cx, jarTop + 1)
                                    ctx.scale(1, 0.24)
                                    ctx.beginPath()
                                    ctx.arc(0, 0, halfW - 6, 0, pi2)
                                    ctx.restore()
                                    ctx.strokeStyle = "rgba(31,35,41,0.06)"
                                    ctx.lineWidth = 1
                                    ctx.stroke()

                                    // 左侧高光
                                    ctx.beginPath()
                                    ctx.moveTo(cx - halfW + 10, jarTop + 14)
                                    ctx.lineTo(cx - halfW + 14, jarBottom - 22)
                                    ctx.strokeStyle = "rgba(255,255,255,0.85)"
                                    ctx.lineWidth = 2
                                    ctx.stroke()

                                    // 签筒上的淡淡字印
                                    ctx.fillStyle = "rgba(143,149,158,0.55)"
                                    ctx.font = "bold 15px 'Microsoft YaHei UI'"
                                    ctx.textAlign = "center"
                                    ctx.textBaseline = "middle"
                                    ctx.fillText("签", cx, cy + 24)
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: "当前名单为空，请前往导入"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: "支持 CSV 名单，导入后即可开始抽取"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                        }

                        Item {
                            width: parent.width
                            height: 40

                            Rectangle {
                                id: importButtonBody
                                width: 112
                                height: 40
                                anchors.centerIn: parent
                                radius: height / 2
                                gradient: Theme.primaryGradient
                                border.width: 1
                                border.color: Theme.withAlpha(Theme.white, 0.18)
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowColor: Theme.withAlpha(Theme.primary, 0.25)
                                    shadowBlur: 0.55
                                    shadowVerticalOffset: 6
                                    shadowHorizontalOffset: 0
                                    autoPaddingEnabled: true
                                }
                            }

                            Rectangle {
                                anchors.fill: importButtonBody
                                radius: importButtonBody.radius
                                color: Theme.white
                                opacity: importMouse.containsMouse ? 0.10 : 0.0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Theme.durationFast
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: importButtonBody
                                text: "去导入"
                                color: Theme.white
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                id: importMouse
                                anchors.fill: importButtonBody
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.goToRoster()
                            }

                            scale: importMouse.pressed
                                   ? 0.96
                                   : (importMouse.containsMouse ? 1.03 : 1.0)

                            Behavior on scale {
                                NumberAnimation {
                                    duration: Theme.durationFast
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }

        }
    }

    ResultCard {
        id: resultCard
        anchors.fill: parent

        onCloseRequested: page.lastWinners = []

        onContinueRequested: {
            page.lastWinners = []
            page.startDraw()
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 动效
    // ─────────────────────────────────────────────────────────────
    Timer {
        id: safetyTimer
        interval: 7000
        repeat: false
        onTriggered: {
            if (page.busy)
                page.busy = false
        }
    }

    ParallelAnimation {
        id: modeReveal

        NumberAnimation {
            target: modeViewport
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 220
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: modeViewport
            property: "scale"
            from: 0.97
            to: 1.0
            duration: 280
            easing.type: Easing.OutCubic
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 快捷键
    // ─────────────────────────────────────────────────────────────
    Shortcut {
        sequence: "Space"
        context: Qt.WindowShortcut
        enabled: page.visible && !page.busy && !page.isEmpty
                 && (!resultCard || !resultCard.opened)
        onActivated: page.startDraw()
    }

    Shortcut {
        sequence: "Esc"
        context: Qt.WindowShortcut
        enabled: page.visible && resultCard && resultCard.opened
        onActivated: resultCard.close()
    }

    // ─────────────────────────────────────────────────────────────
    // 数据绑定
    // ─────────────────────────────────────────────────────────────
    Connections {
        target: backendBridge

        function onWinnerDrawn(name, mode) {
            page.handleWinners([name])
        }

        function onWinnersDrawn(names) {
            page.handleWinners(names)
        }
    }

    // ═════════════════════════════════════════════════════════════
    // 模式切换胶囊
    // ═════════════════════════════════════════════════════════════
    component ModeSwitcher: Item {
        id: control

        implicitWidth: 360
        implicitHeight: 46

        property int currentIndex: 0
        property bool interactive: true
        readonly property real segmentWidth: Math.max(0, (width - 8) / 3)
        readonly property var labels: ["大转盘", "翻牌抽签", "盲盒开箱"]

        signal selected(int index)

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Theme.surfaceAlt
            border.width: 1
            border.color: Theme.withAlpha(Theme.textPrimary, 0.035)
        }

        Rectangle {
            id: selection
            x: 4 + control.currentIndex * control.segmentWidth
            y: 4
            width: control.segmentWidth
            height: control.height - 8
            radius: height / 2
            color: Theme.surface
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.withAlpha(Theme.textPrimary, 0.12)
                shadowBlur: 0.45
                shadowVerticalOffset: 2
                shadowHorizontalOffset: 0
                autoPaddingEnabled: true
            }

            Behavior on x {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }
        }

        Row {
            x: 4
            width: Math.max(0, control.width - 8)
            height: control.height

            Repeater {
                model: control.labels

                delegate: Item {
                    id: tab

                    width: control.segmentWidth
                    height: control.height
                    scale: tabMouse.pressed ? 0.97 : 1.0

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.durationFast
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: height / 2
                        color: tabMouse.containsMouse
                               && control.currentIndex !== index
                               ? Theme.withAlpha(Theme.surface, 0.72)
                               : Theme.transparent

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.durationFast
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: control.currentIndex === index
                               ? Theme.primary
                               : (tabMouse.containsMouse
                                  ? Theme.textPrimary
                                  : Theme.textSecondary)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        font.weight: control.currentIndex === index
                                     ? Font.DemiBold
                                     : Font.Normal

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.durationFast
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: control.interactive
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (control.currentIndex !== index)
                                control.selected(index)
                        }
                    }
                }
            }
        }
    }

    // ═════════════════════════════════════════════════════════════
    // 主操作按钮
    // ═════════════════════════════════════════════════════════════
    component PrimaryDrawButton: Item {
        id: button

        implicitWidth: 220
        implicitHeight: 56
        width: 220
        height: 56

        property string label: "开始抽取"
        property bool active: true
        signal clicked()

        enabled: active
        opacity: active ? 1.0 : 0.45
        scale: mouse.pressed && active
               ? 0.95
               : (mouse.containsMouse && active ? 1.015 : 1.0)

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durationNormal
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Theme.durationFast
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: buttonBody
            anchors.fill: parent
            radius: height / 2
            gradient: Theme.primaryGradient
            border.width: 1
            border.color: Theme.withAlpha(Theme.white, 0.18)
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.withAlpha(Theme.primary, 0.32)
                shadowBlur: 0.65
                shadowVerticalOffset: 8
                shadowHorizontalOffset: 0
                autoPaddingEnabled: true
            }
        }

        Rectangle {
            anchors.fill: buttonBody
            radius: buttonBody.radius
            color: Theme.white
            opacity: mouse.containsMouse && active ? 0.10 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            anchors.fill: buttonBody
            radius: buttonBody.radius
            color: Theme.black
            opacity: mouse.pressed && active ? 0.06 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: button.label
            color: Theme.white
            font.family: Theme.fontFamily
            font.pixelSize: 16
            font.weight: Font.DemiBold
            font.letterSpacing: 2
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: active ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (button.active)
                    button.clicked()
            }
        }
    }
}
