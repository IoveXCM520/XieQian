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

    anchors.fill: parent

    // 空字符串表示默认名单转盘，其余为持久化的自定义转盘名
    property string wheelKey: ""
    property var rosterOptions: []
    property var rosterWeights: []
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
    // 默认转盘按名单权重分配扇区；自定义转盘的选项没有权重，均分
    readonly property var wheelWeights: customWheel ? [] : rosterWeights

    property bool busy: false
    // 抽奖期间名单刷新要延后：动态权重会在开奖瞬间改写扇区宽度，
    // 旋转中重绘盘面会让指针落点与中奖者错位
    property bool rosterRefreshPending: false
    // 抽奖全程锁：点击开始到结果弹窗关闭之间为 true，供 Main 禁用导航与重复点击
    property bool drawLock: false
    readonly property bool isDrawing: drawLock
    // 抽取结果由 startDraw() 同步获取，期间忽略后端信号，避免动画未开始就弹出结果
    property bool capturingWinners: false
    property var lastWinners: []
    property var pendingWinners: []

    readonly property bool isEmpty: customWheel ? wheelOptions.length === 0
                                                : rosterOptions.length === 0
    readonly property string wheelHint: (customWheel
                                        ? "转动专属签盘，把选择交给一点点运气"
                                        : "转动签盘，把选择交给一点点运气")
                                        + " · "
                                        + (customWheel
                                           ? "选项 " + wheelOptions.length + " 个"
                                           : "名单 " + rosterOptions.length + " 人")
    readonly property bool animationEnabled: backendBridge.motionEnabled

    signal importRosterRequested()

    function refreshRosterOptions() {
        var list = []
        var weights = []
        var participants = backendBridge.getParticipantsWithStatus()
        for (var i = 0; i < participants.length; ++i) {
            if (participants[i].enabled) {
                list.push(String(participants[i].name))
                var weight = Number(participants[i].weight)
                weights.push(isFinite(weight) && weight > 0 ? weight : 1)
            }
        }
        rosterOptions = list
        rosterWeights = weights
    }

    function selectWheel(index) {
        if (index <= 0 || index >= wheelChoices.length) {
            wheelKey = ""
            backendBridge.setLastSelectedWheel("")
            return
        }
        wheelKey = wheelChoices[index].name
        backendBridge.setLastSelectedWheel(wheelKey)
    }

    function activateWheel(name) {
        // 名字先记下，列表刷新后 selectedWheel 会自动命中；已删除的名字则回落到默认转盘
        wheelKey = String(name)
        backendBridge.setLastSelectedWheel(wheelKey)
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

        if (backendBridge.removeCustomWheel(name) && wheelKey === name) {
            wheelKey = ""
            backendBridge.setLastSelectedWheel("")
        }
    }

    function startDraw() {
        if (busy || isEmpty)
            return

        busy = true
        drawLock = true
        lastWinners = []
        pendingWinners = []
        pendingIndex = -1

        if (customWheel) {
            if (wheelOptions.length === 0) {
                busy = false
                drawLock = false
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
                drawLock = false
                return
            }

            pendingWinners = winners
            pendingIndex = optionIndexOf(winners[0])
            if (pendingIndex < 0)
                pendingIndex = Math.floor(Math.random() * wheelOptions.length)
        }

        wheelItem.startSpin(pendingIndex)
        if (!animationEnabled) {
            page.finishDraw()
            return
        }
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

        if (rosterRefreshPending) {
            rosterRefreshPending = false
            refreshRosterOptions()
        }

        // 自定义转盘在前端随机，后端不知道结果，这里补齐历史记录
        if (customWheel) {
            for (var i = 0; i < lastWinners.length; ++i)
                backendBridge.appendHistory(lastWinners[i])
        }

        if (lastWinners.length > 0 && Window.window
                && typeof Window.window.showResult === "function") {
            Window.window.showResult(lastWinners)
        } else {
            drawLock = false
        }
    }

    function requestPip() {
        if (Window.window && typeof Window.window.enterPip === "function")
            Window.window.enterPip()
    }

    function endDrawLock() {
        drawLock = false
    }

    function goToImport() {
        importRosterRequested()
        if (Window.window && typeof Window.window.navigate === "function")
            Window.window.navigate(1)
    }

    onIsEmptyChanged: {
        if (isEmpty) {
            busy = false
            drawLock = false
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

        var saved = backendBridge.lastSelectedWheel()
        if (saved !== undefined && saved !== null && String(saved).length > 0)
            activateWheel(String(saved))
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
                            onClicked: page.goToImport()
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

            // 标题、标签组与盘面统一由 ColumnLayout 排布：
            // 标题永远落在转盘正上方居中，不再依赖固定高度导致文字被卡片裁掉
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 4

                ColumnLayout {
                    id: stageHeaderColumn

                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 8
                    Layout.maximumWidth: Math.min(stageCard.width * 0.8, 660)
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: page.wheelName
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontDisplay
                        font.weight: Font.Bold
                        font.letterSpacing: 1
                        elide: Text.ElideRight
                    }

                    // 横向滚动标签：内容少时整体居中，内容多时在本区域内滑动
                    Flickable {
                        id: wheelTabs

                        visible: page.wheelChoices.length > 1
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: Math.min(wheelTabRow.width, 640)
                        Layout.preferredHeight: 26
                        contentWidth: wheelTabRow.width
                        contentHeight: height
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Row {
                            id: wheelTabRow

                            height: 26
                            spacing: 6

                            Repeater {
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
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: page.wheelHint
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontCaption
                        elide: Text.ElideRight
                    }
                }

                Item {
                    id: stageBody
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    WheelItem {
                        id: wheelItem
                        anchors.centerIn: parent
                        width: Math.max(0, Math.min(parent.width, parent.height) * 0.96)
                        height: width
                        options: page.wheelOptions
                        weights: page.wheelWeights
                        showPointer: true
                        motionEnabled: page.animationEnabled
                        onFinished: page.finishDraw()
                    }

                    // 画中画按钮紧贴转盘左右两侧，不再贴在卡片边缘
                    PipButton {
                        anchors.left: wheelItem.left
                        anchors.leftMargin: -40
                        anchors.verticalCenter: wheelItem.verticalCenter
                        hint: "缩小为悬浮窗"
                        onClicked: page.requestPip()
                    }

                    PipButton {
                        anchors.right: wheelItem.right
                        anchors.rightMargin: -40
                        anchors.verticalCenter: wheelItem.verticalCenter
                        hint: "缩小为悬浮窗"
                        onClicked: page.requestPip()
                    }
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
        enabled: page.visible && !page.isDrawing && !page.isEmpty
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
            if (page.busy) {
                page.rosterRefreshPending = true
                return
            }
            page.refreshRosterOptions()
        }

        function onCustomWheelsChanged() {
            // 直接按名字校验：转盘列表刚变化时 selectedWheel 可能还是旧值，
            // 用下标判断会把刚切过去的新转盘误判为已删除
            if (page.wheelKey.length === 0)
                return

            var wheels = backendBridge.customWheels
            for (var i = 0; i < wheels.length; ++i) {
                if (wheels[i].name === page.wheelKey)
                    return
            }

            page.wheelKey = ""
            backendBridge.setLastSelectedWheel("")
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 画中画按钮
    // ─────────────────────────────────────────────────────────────
    component PipButton: Item {
        id: pipButton

        property string hint: ""
        signal clicked()

        width: 34
        height: 34
        z: 20

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: pipMouse.containsMouse
                   ? Theme.primarySoft
                   : Theme.withAlpha(Theme.surface, 0.94)
            border.width: 1
            border.color: pipMouse.containsMouse
                          ? Theme.withAlpha(Theme.primary, 0.35)
                          : Theme.withAlpha(Theme.textPrimary, 0.08)

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: "—"
            color: pipMouse.containsMouse ? Theme.primary : Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: pipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pipButton.clicked()
        }

        ToolTip.visible: pipMouse.containsMouse
        ToolTip.text: pipButton.hint
        ToolTip.delay: 400
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
