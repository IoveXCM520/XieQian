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
    - 点击“开始抽奖”后先确定中奖者，再旋转到对应扇区，动画结束后弹出 ResultCard
*/
Item {
    id: page

    // 空字符串表示默认名单转盘，其余为持久化的自定义转盘名
    property string wheelKey: ""
    property var rosterOptions: []
    property int pendingIndex: -1
    property string deleteTargetName: ""

    // 第 0 项固定为名单转盘，其余为持久化的自定义转盘
    readonly property var wheelChoices: {
        var list = [{ "name": "默认转盘", "options": [], "custom": false }]
        var wheels = backendBridge.customWheels
        for (var i = 0; i < wheels.length; ++i) {
            list.push({ "name": wheels[i].name,
                        "options": wheels[i].options,
                        "custom": true })
        }
        return list
    }

    // 选择以名称而不是下标记录：转盘列表增删后下标会错位，名字始终能对上
    readonly property int selectedWheel: {
        if (wheelKey.length === 0)
            return 0
        for (var i = 1; i < wheelChoices.length; ++i) {
            if (wheelChoices[i].name === wheelKey)
                return i
        }
        return 0
    }

    readonly property bool customWheel: selectedWheel > 0
    readonly property string wheelName: customWheel
                                        ? wheelChoices[selectedWheel].name
                                        : "默认转盘"
    readonly property var wheelOptions: customWheel
                                        ? wheelChoices[selectedWheel].options
                                        : rosterOptions

    property bool busy: false
    // 抽取结果由 startDraw() 同步获取，期间忽略后端信号，避免动画未开始就弹出结果
    property bool capturingWinners: false
    property var lastWinners: []
    property var pendingWinners: []

    readonly property bool isEmpty: customWheel ? wheelOptions.length === 0
                                                : rosterOptions.length === 0
    readonly property string wheelHint: customWheel
                                        ? "转动专属签盘，把选择交给一点点运气"
                                        : "转动签盘，把选择交给一点点运气"

    signal importRosterRequested()

    function refreshRosterOptions() {
        var list = []
        var participants = backendBridge.getParticipantsWithStatus()
        for (var i = 0; i < participants.length; ++i) {
            if (participants[i].enabled)
                list.push(String(participants[i].name))
        }
        rosterOptions = list
    }

    function selectWheel(index) {
        if (index <= 0 || index >= wheelChoices.length) {
            wheelKey = ""
            return
        }
        wheelKey = wheelChoices[index].name
    }

    function activateWheel(name) {
        // 名字先记下，列表刷新后 selectedWheel 会自动命中；已删除的名字则回落到默认转盘
        wheelKey = String(name)
    }

    function optionIndexOf(name) {
        for (var i = 0; i < wheelOptions.length; ++i) {
            if (String(wheelOptions[i]) === name)
                return i
        }
        return -1
    }

    function requestDeleteWheel(name) {
        if (!name || String(name).length === 0)
            return
        deleteTargetName = String(name)
        deleteWheelDialog.open()
    }

    function confirmDeleteWheel() {
        var name = deleteTargetName
        deleteTargetName = ""
        if (name.length === 0)
            return

        if (backendBridge.removeCustomWheel(name) && wheelKey === name)
            wheelKey = ""
    }

    function startDraw() {
        if (busy || isEmpty)
            return

        busy = true
        lastWinners = []
        pendingWinners = []
        pendingIndex = -1

        if (customWheel) {
            if (wheelOptions.length === 0) {
                busy = false
                return
            }

            // 自定义转盘：先定下选项，再让指针停到对应扇区
            var customIndex = Math.floor(Math.random() * wheelOptions.length)
            pendingIndex = customIndex
            pendingWinners = [String(wheelOptions[customIndex])]
        } else {
            // 名单转盘：先取中奖者，再按中奖者在当前选项中的位置计算落点
            capturingWinners = true
            var winners
            if (backendBridge.drawCount > 1)
                winners = normalizeWinners(backendBridge.drawMultipleWinners())
            else
                winners = normalizeWinners(backendBridge.drawWinner())
            capturingWinners = false

            if (winners.length === 0) {
                busy = false
                return
            }

            pendingWinners = winners
            pendingIndex = optionIndexOf(winners[0])
            if (pendingIndex < 0)
                pendingIndex = Math.floor(Math.random() * wheelOptions.length)
        }

        wheelItem.startSpin(pendingIndex)
        safetyTimer.restart()
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
        if (capturingWinners)
            return

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
        pendingIndex = -1
        safetyTimer.stop()

        if (lastWinners.length > 0 && Window.window
                && typeof Window.window.showResult === "function")
            Window.window.showResult(lastWinners)
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
            if (Window.window && typeof Window.window.closeResult === "function")
                Window.window.closeResult()
        }
    }

    Component.onCompleted: {
        refreshRosterOptions()

        var saved = backendBridge.getCustomWheel()
        if (saved && saved.name !== undefined && String(saved.name).length > 0)
            activateWheel(String(saved.name))
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
                                 ? (page.customWheel ? "添加选项后即可开始" : "导入名单后即可开始")
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
                        visible: page.isEmpty && !page.customWheel
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
                height: page.wheelChoices.length > 1 ? 128 : 100

                Column {
                    anchors.centerIn: parent
                    width: Math.min(stageCard.width - 280, 640)
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

                    // 横向滚动标签：转盘再多也不会撑破标题区
                    ListView {
                        id: wheelTabs

                        visible: page.wheelChoices.length > 1
                        width: Math.min(contentWidth > 0 ? contentWidth : parent.width,
                                        parent.width)
                        height: 26
                        anchors.horizontalCenter: parent.horizontalCenter
                        orientation: ListView.Horizontal
                        spacing: 6
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: page.wheelChoices

                        delegate: Rectangle {
                            id: wheelChip

                            property bool holdHandled: false

                            width: Math.min(wheelChipText.implicitWidth + 22, 180)
                            height: 24
                            radius: 12
                            color: index === page.selectedWheel
                                   ? Theme.primary
                                   : Theme.surfaceAlt
                            border.width: 1
                            border.color: index === page.selectedWheel
                                          ? Theme.primary
                                          : Theme.border

                            Text {
                                id: wheelChipText
                                width: Math.min(implicitWidth, 158)
                                anchors.centerIn: parent
                                text: modelData.name
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                color: index === page.selectedWheel
                                       ? Theme.white
                                       : Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onPressed: wheelChip.holdHandled = false

                                onPressAndHold: {
                                    wheelChip.holdHandled = true
                                    if (modelData.custom)
                                        page.requestDeleteWheel(modelData.name)
                                }

                                onClicked: function(mouse) {
                                    if (wheelChip.holdHandled)
                                        return

                                    if (mouse.button === Qt.RightButton) {
                                        if (modelData.custom)
                                            page.requestDeleteWheel(modelData.name)
                                    } else {
                                        page.selectWheel(index)
                                    }
                                }
                            }
                        }
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
                                  : (page.customWheel
                                     ? "选项 " + page.wheelOptions.length + " 个"
                                     : "名单 " + page.rosterOptions.length + " 人")
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
                    onFinished: page.finishDraw()
                }
            }
        }
    }

    // 右键 / 长按自定义标签触发的删除确认
    Dialog {
        id: deleteWheelDialog

        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: 380
        padding: 24

        background: Rectangle {
            radius: Theme.radiusCard
            color: Theme.surface

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.withAlpha(Theme.textPrimary, 0.18)
                shadowBlur: 0.65
                shadowVerticalOffset: 12
                shadowHorizontalOffset: 0
                autoPaddingEnabled: true
            }
        }

        contentItem: Column {
            width: 380 - 48
            spacing: 14

            Text {
                width: parent.width
                text: "删除转盘「" + page.deleteTargetName + "」？"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontH2
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: "删除后无法恢复，已产生的抽取历史不受影响。"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                wrapMode: Text.WordWrap
            }

            Item {
                width: parent.width
                height: 40

                Row {
                    anchors.right: parent.right
                    height: parent.height
                    spacing: 10

                    DialogButton {
                        width: 92
                        height: 40
                        label: "取消"
                        onClicked: deleteWheelDialog.reject()
                    }

                    DialogButton {
                        width: 92
                        height: 40
                        label: "删除"
                        danger: true
                        onClicked: deleteWheelDialog.accept()
                    }
                }
            }
        }

        onAccepted: page.confirmDeleteWheel()
        onRejected: page.deleteTargetName = ""
    }

    Timer {
        id: safetyTimer
        interval: 7000
        repeat: false
        // 动画异常中断时也要把已经抽出的结果交给用户
        onTriggered: page.finishDraw()
    }

    Shortcut {
        sequence: "Space"
        context: Qt.WindowShortcut
        enabled: page.visible && !page.busy && !page.isEmpty
                 && !(Window.window && Window.window.resultOpen)
        onActivated: page.startDraw()
    }

    Shortcut {
        sequence: "Esc"
        context: Qt.WindowShortcut
        enabled: page.visible && Window.window && Window.window.resultOpen
        onActivated: {
            if (Window.window)
                Window.window.closeResult()
        }
    }

    Connections {
        target: backendBridge

        function onWinnerDrawn(name, mode) {
            page.handleWinners([name])
        }

        function onWinnersDrawn(names) {
            page.handleWinners(names)
        }

        function onRosterUpdated() {
            page.refreshRosterOptions()
        }

        function onCustomWheelsChanged() {
            if (page.wheelKey.length > 0 && page.selectedWheel === 0)
                page.wheelKey = ""
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 对话框按钮
    // ─────────────────────────────────────────────────────────────
    component DialogButton: Item {
        id: button

        property string label: ""
        property bool danger: false
        signal clicked()

        width: 92
        height: 40
        scale: mouse.pressed ? 0.95 : (mouse.containsMouse ? 1.02 : 1.0)

        Behavior on scale {
            NumberAnimation {
                duration: Theme.durationFast
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: button.danger
                   ? (mouse.containsMouse ? Theme.dangerSoft : Theme.surface)
                   : (mouse.containsMouse ? Theme.surfaceAlt : Theme.surface)
            border.width: 1
            border.color: button.danger
                          ? Theme.withAlpha(Theme.danger, 0.45)
                          : Theme.border

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: button.label
            color: button.danger ? Theme.danger : Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontCaption
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
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
