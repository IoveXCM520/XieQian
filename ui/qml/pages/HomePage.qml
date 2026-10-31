import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects

import ".."
import "../components"

/*!
    抽奖主页面。
    - 只保留大转盘，不再有模式切换
    - 顶部显示当前转盘名称，中心轮盘约占页面 60%
    - 点击“开始抽奖”后旋转，结束后调用后端抽签并弹出 ResultCard
*/
Item {
    id: page

    // 自定义转盘由 Main.qml 在 AddPage 保存后注入；这里给出默认示例
    property string wheelName: "默认转盘"
    property var wheelOptions: ["上上签", "好运", "如愿", "惊喜", "欢喜", "顺遂"]

    property bool busy: false
    property var lastWinners: []
    property var pendingWinners: []

    readonly property bool isEmpty: backendBridge.rosterCount === 0
    readonly property string wheelHint: "转动签盘，把选择交给一点点运气"

    signal importRosterRequested()

    function startDraw() {
        if (busy || isEmpty)
            return

        busy = true
        lastWinners = []
        pendingWinners = []

        wheelItem.startSpin()
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

        if (!busy) {
            lastWinners = list
            return
        }

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

    function goToRoster() {
        importRosterRequested()
        if (Window.window && typeof Window.window.navigate === "function")
            Window.window.navigate(2)
    }

    onIsEmptyChanged: {
        if (isEmpty) {
            busy = false
            lastWinners = []
            pendingWinners = []
            if (safetyTimer)
                safetyTimer.stop()
            if (resultCard && resultCard.opened)
                resultCard.close()
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 页面布局
    // ─────────────────────────────────────────────────────────────
    Item {
        id: pageContent
        anchors.fill: parent
        anchors.margins: Theme.pagePadding

        // 底部操作区
        Column {
            id: footer
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            spacing: 14

            Item {
                width: parent.width
                height: 22

                RowLayout {
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
                              : (page.isEmpty
                                 ? "导入名单后即可开始"
                                 : "快速抽取")
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.durationFast
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    Text {
                        id: importLink
                        visible: page.isEmpty
                        Layout.alignment: Qt.AlignVCenter
                        text: "去导入"
                        color: Theme.primary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        font.weight: Font.DemiBold
                        scale: importLinkMouse.pressed
                               ? 0.95
                               : (importLinkMouse.containsMouse ? 1.02 : 1.0)

                        Behavior on scale {
                            NumberAnimation {
                                duration: Theme.durationFast
                                easing.type: Easing.OutCubic
                            }
                        }

                        MouseArea {
                            id: importLinkMouse
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.goToRoster()
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: 56

                PrimaryDrawButton {
                    width: 240
                    height: 56
                    anchors.centerIn: parent
                    active: !page.isEmpty && !page.busy
                    label: "开始抽奖"
                    onClicked: page.startDraw()
                }
            }
        }

        // 舞台投影（放在卡片后方，避免被 clip: true 裁掉）
        CardShadowBehind {
            target: stageCard
        }

        Rectangle {
            id: stageCard
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: footer.top
            anchors.bottomMargin: 20
            radius: Theme.radiusCard
            color: Theme.surface
            border.width: 1
            border.color: Theme.withAlpha(Theme.textPrimary, 0.045)
            clip: true

            // 右上角柔和品牌光晕
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

            // 转盘名称 + 当前名单
            Item {
                id: stageHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 92

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        width: Math.min(implicitWidth, stageCard.width - 280)
                        horizontalAlignment: Text.AlignHCenter
                        text: page.wheelName
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontH0
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: Math.min(implicitWidth, stageCard.width - 280)
                        horizontalAlignment: Text.AlignHCenter
                        text: page.wheelHint
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
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
                anchors.margins: 8

                WheelItem {
                    id: wheelItem
                    anchors.centerIn: parent
                    width: Math.max(0, Math.min(parent.width, parent.height) * 0.96)
                    height: width
                    options: page.wheelOptions
                    showPointer: true
                    onFinished: page.drawAndReveal()
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

    Timer {
        id: safetyTimer
        interval: 7000
        repeat: false
        onTriggered: {
            if (page.busy)
                page.busy = false
        }
    }

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

    Connections {
        target: backendBridge

        function onWinnerDrawn(name, mode) {
            page.handleWinners([name])
        }

        function onWinnersDrawn(names) {
            page.handleWinners(names)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 主操作按钮
    // ─────────────────────────────────────────────────────────────
    component PrimaryDrawButton: Item {
        id: button

        implicitWidth: 240
        implicitHeight: 56
        width: 240
        height: 56

        property string label: "开始抽奖"
        property bool active: true
        signal clicked()

        enabled: active
        opacity: active ? 1.0 : 0.45
        scale: mouse.pressed && active
               ? 0.95
               : (mouse.containsMouse && active ? 1.02 : 1.0)

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
            id: buttonShadow
            anchors.fill: parent
            radius: height / 2
            gradient: Theme.primaryGradient
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
            id: buttonBody
            anchors.fill: parent
            radius: height / 2
            gradient: Theme.primaryGradient
            border.width: 1
            border.color: Theme.withAlpha(Theme.white, 0.18)
        }

        Rectangle {
            anchors.fill: buttonBody
            radius: buttonBody.radius
            color: Theme.white
            opacity: mouse.containsMouse && active ? 0.12 : 0.0

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
