import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import ".."
import "../components"

/*!
    教学工具页。
    - 随机分组 / 随机排座位
    - 分组结果 Flow 卡片流，座位结果 6 列网格
    - 平滑入场动画
*/
Item {
    id: page

    readonly property bool reducedMotion: !backendBridge.motionEnabled
    readonly property int modeGroups: 0
    readonly property int modeSeats: 1
    readonly property int modeCalculator: 2
    readonly property int seatColumns: 6

    property int mode: modeGroups
    property int groupCount: 4
    property var groups: []
    property var seats: []

    // ── 计算器状态 ──
    property string calcDisplay: "0"
    property string calcExpression: ""
    property real calcAccumulator: 0
    property string calcPendingOp: ""
    property bool calcFresh: true

    readonly property var calcKeys: [
        { "label": "C", "action": "clear", "row": 0, "column": 0, "accent": true },
        { "label": "⌫", "action": "back", "row": 0, "column": 1, "accent": true },
        { "label": "÷", "action": "op:÷", "row": 0, "column": 2, "accent": true },
        { "label": "×", "action": "op:×", "row": 0, "column": 3, "accent": true },
        { "label": "7", "action": "digit:7", "row": 1, "column": 0 },
        { "label": "8", "action": "digit:8", "row": 1, "column": 1 },
        { "label": "9", "action": "digit:9", "row": 1, "column": 2 },
        { "label": "−", "action": "op:−", "row": 1, "column": 3, "accent": true },
        { "label": "4", "action": "digit:4", "row": 2, "column": 0 },
        { "label": "5", "action": "digit:5", "row": 2, "column": 1 },
        { "label": "6", "action": "digit:6", "row": 2, "column": 2 },
        { "label": "+", "action": "op:+", "row": 2, "column": 3, "accent": true },
        { "label": "1", "action": "digit:1", "row": 3, "column": 0 },
        { "label": "2", "action": "digit:2", "row": 3, "column": 1 },
        { "label": "3", "action": "digit:3", "row": 3, "column": 2 },
        { "label": "=", "action": "equals", "row": 3, "column": 3,
          "rowSpan": 2, "accent": true },
        { "label": "0", "action": "digit:0", "row": 4, "column": 0, "columnSpan": 2 },
        { "label": ".", "action": "dot", "row": 4, "column": 2 }
    ]

    readonly property int rosterCount: backendBridge.rosterCount
    readonly property int groupedCount: {
        var count = 0
        for (var i = 0; i < groups.length; ++i)
            count += groups[i].length
        return count
    }

    function startGrouping() {
        if (rosterCount === 0)
            return

        groups = backendBridge.generateGroups(groupCount)
    }

    function startSeating() {
        if (rosterCount === 0)
            return

        seats = backendBridge.generateSeats()
    }

    function generate() {
        if (mode === modeGroups)
            startGrouping()
        else if (mode === modeSeats)
            startSeating()
    }

    function calcClear() {
        calcDisplay = "0"
        calcExpression = ""
        calcAccumulator = 0
        calcPendingOp = ""
        calcFresh = true
    }

    function calcFail() {
        calcDisplay = "错误"
        calcExpression = ""
        calcAccumulator = 0
        calcPendingOp = ""
        calcFresh = true
    }

    function calcFormat(value) {
        if (!isFinite(value))
            return "错误"

        var rounded = Math.round(value * 1e10) / 1e10
        if (Math.abs(rounded) >= 1e12)
            return rounded.toExponential(6)
        return String(rounded)
    }

    function calcInputDigit(digit) {
        if (calcDisplay === "错误")
            calcClear()

        var text = calcFresh ? "" : calcDisplay
        if (text === "0")
            text = ""
        if (text.replace(/[^0-9]/g, "").length >= 12)
            return

        text += digit
        calcDisplay = text.length === 0 ? "0" : text
        calcFresh = false
    }

    function calcInputDot() {
        if (calcDisplay === "错误")
            calcClear()

        if (calcFresh) {
            calcDisplay = "0."
            calcFresh = false
            return
        }

        if (calcDisplay.indexOf(".") === -1)
            calcDisplay += "."
    }

    function calcBackspace() {
        if (calcDisplay === "错误") {
            calcClear()
            return
        }

        if (calcFresh)
            return

        var text = calcDisplay.substring(0, calcDisplay.length - 1)
        if (text.length === 0 || text === "-")
            text = "0"

        calcDisplay = text
        if (text === "0")
            calcFresh = true
    }

    function calcApply(left, op, right) {
        if (op === "+")
            return left + right
        if (op === "−")
            return left - right
        if (op === "×")
            return left * right
        if (op === "÷")
            return right === 0 ? NaN : left / right
        return right
    }

    function calcSetOperator(op) {
        if (calcDisplay === "错误")
            return

        var value = parseFloat(calcDisplay)
        if (isNaN(value))
            value = 0

        if (calcPendingOp !== "" && !calcFresh)
            calcAccumulator = calcApply(calcAccumulator, calcPendingOp, value)
        else if (calcPendingOp === "")
            calcAccumulator = value

        if (!isFinite(calcAccumulator)) {
            calcFail()
            return
        }

        calcPendingOp = op
        calcExpression = calcFormat(calcAccumulator) + " " + op
        calcDisplay = calcFormat(calcAccumulator)
        calcFresh = true
    }

    function calcEquals() {
        if (calcPendingOp === "" || calcDisplay === "错误")
            return

        var operand = calcFresh ? calcAccumulator : parseFloat(calcDisplay)
        if (isNaN(operand))
            operand = 0

        var result = calcApply(calcAccumulator, calcPendingOp, operand)
        if (!isFinite(result)) {
            calcFail()
            return
        }

        calcExpression = calcFormat(calcAccumulator) + " " + calcPendingOp
                         + " " + calcFormat(operand) + " ="
        calcDisplay = calcFormat(result)
        calcAccumulator = result
        calcPendingOp = ""
        calcFresh = true
    }

    function pressCalcKey(action) {
        if (action === "clear") {
            calcClear()
        } else if (action === "back") {
            calcBackspace()
        } else if (action === "dot") {
            calcInputDot()
        } else if (action === "equals") {
            calcEquals()
        } else if (action.indexOf("digit:") === 0) {
            calcInputDigit(action.substring(6))
        } else if (action.indexOf("op:") === 0) {
            calcSetOperator(action.substring(3))
        }
    }

    Connections {
        target: backendBridge

        function onRosterUpdated() {
            page.groups = []
            page.seats = []
        }
    }

    Item {
        id: pageContent
        anchors.fill: parent
        anchors.margins: Theme.pagePadding

        // ─────────────────────────────────────────────────────────
        // 标题
        // ─────────────────────────────────────────────────────────
        Item {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 64

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Text {
                    text: "教学工具"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontH0
                    font.weight: Font.Bold
                }

                Text {
                    text: "随机分组、随机排座，还有随手可用的计算器"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 32
                width: toolCount.implicitWidth + 22
                radius: 16
                color: Theme.surface
                border.width: 1
                border.color: Theme.withAlpha(Theme.primary, 0.10)

                Text {
                    id: toolCount
                    anchors.centerIn: parent
                    text: page.rosterCount + " 人"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.DemiBold
                }
            }
        }

        // ─────────────────────────────────────────────────────────
        // 控制栏
        // ─────────────────────────────────────────────────────────
        RowLayout {
            id: controls
            anchors.top: header.bottom
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 12

            ToolSegment {
                width: 348
                height: 44
                currentIndex: page.mode
                onSelected: function(index) {
                    page.mode = index
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
            }

            Item {
                visible: page.mode === page.modeGroups
                Layout.preferredWidth: 132
                Layout.preferredHeight: 40

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.border
                }

                Row {
                    anchors.fill: parent
                    spacing: 0

                    Item {
                        id: minusStep
                        property bool down: false

                        width: 38
                        height: parent.height
                        scale: down ? 0.95 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: Theme.durationFast
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "−"
                            color: page.groupCount > 1 ? Theme.primary : Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: 20
                        }

                        MouseArea {
                            id: minusStepMouse
                            anchors.fill: parent
                            cursorShape: page.groupCount > 1
                                         ? Qt.PointingHandCursor
                                         : Qt.ArrowCursor
                            onPressedChanged: minusStep.down = pressed
                            onClicked: {
                                if (page.groupCount > 1)
                                    page.groupCount -= 1
                            }
                        }
                    }

                    Text {
                        width: 56
                        height: parent.height
                        text: page.groupCount + " 组"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontCaption
                        font.weight: Font.DemiBold
                    }

                    Item {
                        id: plusStep
                        property bool down: false

                        width: 38
                        height: parent.height
                        scale: down ? 0.95 : 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: Theme.durationFast
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            color: page.groupCount < 20 ? Theme.primary : Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                        }

                        MouseArea {
                            id: plusStepMouse
                            anchors.fill: parent
                            cursorShape: page.groupCount < 20
                                         ? Qt.PointingHandCursor
                                         : Qt.ArrowCursor
                            onPressedChanged: plusStep.down = pressed
                            onClicked: {
                                if (page.groupCount < 20)
                                    page.groupCount += 1
                            }
                        }
                    }
                }
            }

            ToolAction {
                visible: page.mode !== page.modeCalculator
                width: 154
                height: 44
                primary: true
                text: page.mode === page.modeGroups ? "开始分组" : "生成座位表"
                enabled: page.rosterCount > 0
                onClicked: page.generate()
            }
        }

        Text {
            id: statLabel
            anchors.top: controls.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            text: {
                if (page.mode === page.modeCalculator)
                    return ""
                if (page.mode === page.modeGroups) {
                    if (page.groups.length === 0)
                        return ""
                    return "共 " + page.groups.length + " 组 · " + page.groupedCount + " 人"
                }
                if (page.seats.length === 0)
                    return ""
                return page.seatColumns + " 列 × "
                       + Math.ceil(page.seats.length / page.seatColumns) + " 行"
            }
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontCaption
        }

        // ─────────────────────────────────────────────────────────
        // 结果区
        // ─────────────────────────────────────────────────────────
        StackLayout {
            id: resultStack

            anchors.top: statLabel.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            currentIndex: page.mode

            // 随机分组
            Item {
                Flickable {
                    id: groupFlick

                    anchors.fill: parent
                    clip: true
                    contentWidth: width
                    contentHeight: groupFlow.height + 8
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AlwaysOff
                    }

                    Flow {
                        id: groupFlow

                        width: groupFlick.width
                        spacing: 14

                        Repeater {
                            model: page.groups

                            delegate: Rectangle {
                                id: groupCard

                                property bool shown: false

                                CardShadow {}

                                width: Math.max(220, Math.min(300,
                                                             (groupFlow.width - 14) / 2))
                                height: groupColumn.childrenRect.height + 30
                                radius: Theme.radiusListCard
                                color: Theme.surface
                                border.width: 1
                                border.color: Theme.withAlpha(Theme.textPrimary, 0.045)
                                opacity: shown ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: page.reducedMotion ? 0 : 240
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                transform: Translate {
                                    y: groupCard.shown ? 0 : 14

                                    Behavior on y {
                                        NumberAnimation {
                                            duration: page.reducedMotion ? 0 : 260
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                Timer {
                                    interval: page.reducedMotion ? 0 : index * 60
                                    running: true
                                    onTriggered: groupCard.shown = true
                                }

                                Column {
                                    id: groupColumn

                                    x: 16
                                    y: 15
                                    width: parent.width - 32
                                    spacing: 8

                                    Item {
                                        width: parent.width
                                        height: 22

                                        Text {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "第 " + (index + 1) + " 组"
                                            color: Theme.primary
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontBody
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.length + " 人"
                                            color: Theme.textSecondary
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: Theme.withAlpha(Theme.textPrimary, 0.045)
                                    }

                                    Repeater {
                                        model: modelData

                                        delegate: Text {
                                            width: groupColumn.width
                                            height: 22
                                            text: modelData
                                            color: Theme.textPrimary
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontBody
                                            elide: Text.ElideRight
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    width: Math.min(420, parent.width - 40)
                    text: page.rosterCount > 0
                          ? "设置组数后，点击“开始分组”"
                          : "暂无名单，请先在名单页导入"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    horizontalAlignment: Text.AlignHCenter
                    visible: page.groups.length === 0
                }
            }

            // 随机排座位
            Item {
                Flickable {
                    id: seatFlick

                    anchors.fill: parent
                    clip: true
                    contentWidth: width
                    contentHeight: seatGrid.height + 8
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AlwaysOff
                    }

                    Grid {
                        id: seatGrid

                        readonly property real cellWidth: Math.max(1,
                            (seatFlick.width - columnSpacing * (page.seatColumns - 1))
                            / page.seatColumns)
                        readonly property real cellHeight: 52
                        readonly property int rowCount: page.seatColumns > 0
                                                         ? Math.ceil(page.seats.length / page.seatColumns)
                                                         : 0

                        width: seatFlick.width
                        height: rowCount > 0
                                ? rowCount * cellHeight + (rowCount - 1) * rowSpacing
                                : 0
                        columns: page.seatColumns
                        rowSpacing: 12
                        columnSpacing: 12

                        Repeater {
                            model: page.seats

                            delegate: Rectangle {
                                id: seatCell

                                property bool shown: false

                                CardShadow {}

                                width: seatGrid.cellWidth
                                height: seatGrid.cellHeight
                                radius: Theme.radiusListCard
                                color: Theme.surface
                                border.width: 1
                                border.color: Theme.withAlpha(Theme.textPrimary, 0.045)
                                opacity: shown ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: page.reducedMotion ? 0 : 220
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                transform: Translate {
                                    y: seatCell.shown ? 0 : 14

                                    Behavior on y {
                                        NumberAnimation {
                                            duration: page.reducedMotion ? 0 : 240
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                Timer {
                                    interval: page.reducedMotion ? 0 : index * 35
                                    running: true
                                    onTriggered: seatCell.shown = true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    width: parent.width - 12
                                    text: modelData
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    font.weight: Font.DemiBold
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    width: Math.min(420, parent.width - 40)
                    text: page.rosterCount > 0
                          ? "点击“生成座位表”，随机安排课堂座位"
                          : "暂无名单，请先在名单页导入"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    horizontalAlignment: Text.AlignHCenter
                    visible: page.seats.length === 0
                }
            }

            // 计算器
            Item {
                Flickable {
                    id: calcFlick

                    anchors.fill: parent
                    clip: true
                    contentWidth: width
                    contentHeight: calcColumn.height + 16
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        width: 0
                        policy: ScrollBar.AlwaysOff
                    }

                    Column {
                        id: calcColumn

                        width: Math.min(340, calcFlick.width)
                        x: Math.max(0, (calcFlick.width - width) / 2)
                        y: 4
                        spacing: 12

                        // 显示屏
                        Rectangle {
                            width: parent.width
                            height: 104
                            radius: Theme.radiusCard
                            color: Theme.surface
                            border.width: 1
                            border.color: Theme.withAlpha(Theme.textPrimary, 0.05)

                            Column {
                                anchors.fill: parent
                                anchors.margins: 18
                                spacing: 4

                                Text {
                                    width: parent.width
                                    height: 20
                                    text: page.calcExpression
                                    horizontalAlignment: Text.AlignRight
                                    verticalAlignment: Text.AlignVCenter
                                    color: Theme.textTertiary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontCaption
                                    elide: Text.ElideLeft
                                }

                                Text {
                                    width: parent.width
                                    height: parent.height - 24
                                    text: page.calcDisplay
                                    horizontalAlignment: Text.AlignRight
                                    verticalAlignment: Text.AlignVCenter
                                    color: page.calcDisplay === "错误"
                                           ? Theme.danger
                                           : Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: page.calcDisplay.length > 10 ? 24 : 36
                                    font.weight: Font.Bold
                                    elide: Text.ElideLeft
                                }
                            }
                        }

                        // 4 列键盘：数字、四则运算、小数点与清零
                        GridLayout {
                            width: parent.width
                            columns: 4
                            columnSpacing: 8
                            rowSpacing: 8

                            Repeater {
                                model: page.calcKeys

                                delegate: CalcKey {
                                    Layout.row: modelData.row
                                    Layout.column: modelData.column
                                    Layout.rowSpan: modelData.rowSpan ? modelData.rowSpan : 1
                                    Layout.columnSpan: modelData.columnSpan ? modelData.columnSpan : 1
                                    Layout.preferredWidth: 79 * (modelData.columnSpan ? modelData.columnSpan : 1)
                                                          + 8 * ((modelData.columnSpan ? modelData.columnSpan : 1) - 1)
                                    Layout.preferredHeight: 52 * (modelData.rowSpan ? modelData.rowSpan : 1)
                                                           + 8 * ((modelData.rowSpan ? modelData.rowSpan : 1) - 1)
                                    label: modelData.label
                                    accent: modelData.accent === true
                                    onTriggered: page.pressCalcKey(modelData.action)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 顶部模式切换
    // ─────────────────────────────────────────────────────────────
    component ToolSegment: Item {
        id: control

        property int currentIndex: 0
        readonly property real segmentWidth: Math.max(0, (width - 8) / control.labels.length)
        readonly property var labels: ["随机分组", "随机排座位", "计算器"]
        signal selected(int index)

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Theme.surfaceAlt
            border.width: 1
            border.color: Theme.withAlpha(Theme.textPrimary, 0.035)
        }

        Rectangle {
            x: 4 + control.currentIndex * control.segmentWidth
            y: 4
            width: control.segmentWidth
            height: control.height - 8
            radius: height / 2
            color: Theme.surface

            Behavior on x {
                NumberAnimation {
                    duration: 220
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
                    id: tabRoot

                    property bool hovered: false
                    property bool down: false

                    width: control.segmentWidth
                    height: control.height
                    scale: down ? 0.95 : (hovered ? 1.01 : 1.0)

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.durationFast
                            easing.type: Easing.OutCubic
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: control.currentIndex === index
                               ? Theme.primary
                               : (tabRoot.hovered ? Theme.textPrimary : Theme.textSecondary)
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
                        cursorShape: Qt.PointingHandCursor
                        onEntered: tabRoot.hovered = true
                        onExited: tabRoot.hovered = false
                        onPressedChanged: tabRoot.down = pressed
                        onClicked: {
                            if (control.currentIndex !== index)
                                control.selected(index)
                        }
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 计算器按键
    // ─────────────────────────────────────────────────────────────
    component CalcKey: Item {
        id: key

        property string label: ""
        property bool accent: false
        signal triggered()

        implicitWidth: 79
        implicitHeight: 52
        scale: mouse.pressed ? 0.95 : (mouse.containsMouse ? 1.03 : 1.0)

        Behavior on scale {
            NumberAnimation {
                duration: Theme.durationFast
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: key.accent
                   ? (mouse.containsMouse ? Theme.primarySoftGreen : Theme.primarySoft)
                   : (mouse.containsMouse ? Theme.surfaceAlt : Theme.surface)
            border.width: 1
            border.color: key.accent
                          ? Theme.withAlpha(Theme.primary, 0.22)
                          : Theme.withAlpha(Theme.textPrimary, 0.06)

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: key.label
            color: key.accent ? Theme.primary : Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: key.label.length > 1 ? 18 : 20
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: key.triggered()
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 主操作按钮
    // ─────────────────────────────────────────────────────────────
    component ToolAction: Item {
        id: button

        property string text: ""
        property bool primary: false
        signal clicked()

        implicitWidth: 150
        implicitHeight: 44
        width: 150
        height: 44
        enabled: true
        opacity: enabled ? 1.0 : 0.45
        scale: mouse.pressed && enabled
               ? 0.95
               : (mouse.containsMouse && enabled ? 1.02 : 1.0)

        Behavior on opacity {
            NumberAnimation {
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

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: button.primary ? Theme.primary : Theme.surface
                }
                GradientStop {
                    position: 1.0
                    color: button.primary ? Theme.primaryEnd : Theme.surface
                }
            }
            border.width: button.primary ? 0 : 1
            border.color: Theme.border
        }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: button.primary ? Theme.white : Theme.primarySoft
            opacity: mouse.containsMouse && button.enabled
                     ? (button.primary ? 0.10 : 0.55)
                     : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: button.text
            color: button.primary ? Theme.white : Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: button.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (button.enabled)
                    button.clicked()
            }
        }
    }
}
