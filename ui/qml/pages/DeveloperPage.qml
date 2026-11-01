import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Window

import ".."
import "../components"

/*!
    开发者控制台（隐藏页，不出现在左侧导航）。
    - 权重列表：直接输入修改
    - 从成绩单图片识别姓名与分数，按名次线性分配权重
    - 重置抽奖状态、切换静态 / 动态权重
*/
Item {
    id: page

    anchors.fill: parent

    property var participants: []
    property string statusMessage: ""
    property bool statusFailed: false
    property bool ocrBusy: false

    function refresh() {
        participants = backendBridge.getParticipantsWithStatus()
    }

    function goBack() {
        if (Window.window && typeof Window.window.navigate === "function")
            Window.window.navigate(6)
    }

    function adjustFromScoreSheet() {
        if (ocrBusy)
            return

        var path = backendBridge.chooseRosterImagePath()
        if (!path || path.length === 0)
            return

        ocrBusy = true
        statusFailed = false
        statusMessage = "AI 正在读取成绩单..."
        backendBridge.aiManager.ocrScoresFromImage(path)
    }

    function resetDrawState() {
        backendBridge.resetDrawStats()
        statusFailed = false
        statusMessage = "已重置全部成员的抽取状态与动态权重计数"
    }

    Component.onCompleted: refresh()

    Connections {
        target: backendBridge

        function onRosterUpdated() {
            page.refresh()
        }
    }

    Connections {
        target: backendBridge.aiManager

        function onOcrProgress(message) {
            if (page.ocrBusy)
                page.statusMessage = String(message)
        }

        function onOcrScoresReady(entries) {
            page.ocrBusy = false
            var updated = backendBridge.applyScoreWeights(entries)
            page.statusFailed = updated === 0
            page.statusMessage = updated > 0
                                 ? "已按成绩排名为 " + updated + " 人分配权重（最高 5.0，最低 0.5）"
                                 : "识别到的姓名不在名单里"
        }

        function onOcrFailed(message) {
            if (!page.ocrBusy)
                return
            page.ocrBusy = false
            page.statusFailed = true
            page.statusMessage = String(message)
        }
    }

    Item {
        id: pageContent
        anchors.fill: parent
        anchors.margins: Theme.pagePadding

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
                    text: "开发者控制台"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontH0
                    font.weight: Font.Bold
                }

                Text {
                    text: "权重调校、成绩单调权与抽奖状态重置"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }

            DevButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 104
                height: 38
                text: "返回设置"
                onClicked: page.goBack()
            }
        }

        RowLayout {
            id: actionRow

            anchors.top: header.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 12

            // 权重模式
            Rectangle {
                Layout.preferredWidth: 360
                Layout.preferredHeight: 88
                radius: Theme.radiusListCard
                color: Theme.surface
                border.width: 1
                border.color: Theme.withAlpha(Theme.textPrimary, 0.045)

                CardShadow {}

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 12

                    Column {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: backendBridge.dynamicWeights ? "动态权重 · Dynamic" : "静态权重 · Static"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.DemiBold
                        }

                        Text {
                            width: parent.width
                            text: "base × exp(-drawCount / 3) × max(0.1, 1 - streak × 0.2)"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontMicro
                            wrapMode: Text.WordWrap
                        }
                    }

                    DevSwitch {
                        Layout.alignment: Qt.AlignVCenter
                        checked: backendBridge.dynamicWeights
                        onToggled: function(value) {
                            backendBridge.dynamicWeights = value
                        }
                    }
                }
            }

            // 操作
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 88
                radius: Theme.radiusListCard
                color: Theme.surface
                border.width: 1
                border.color: Theme.withAlpha(Theme.textPrimary, 0.045)

                CardShadow {}

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 12

                    DevButton {
                        Layout.alignment: Qt.AlignVCenter
                        width: 176
                        height: 40
                        primary: true
                        text: page.ocrBusy ? "识别中…" : "从成绩单 AI 调权"
                        enabled: !page.ocrBusy
                        onClicked: page.adjustFromScoreSheet()
                    }

                    DevButton {
                        Layout.alignment: Qt.AlignVCenter
                        width: 132
                        height: 40
                        text: "重置抽奖状态"
                        onClicked: page.resetDrawState()
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: page.statusMessage
                        visible: text.length > 0
                        color: page.statusFailed ? Theme.danger : Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontMicro
                        elide: Text.ElideRight
                    }
                }
            }
        }

        ListView {
            id: listView

            anchors.top: actionRow.bottom
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            spacing: 8
            cacheBuffer: 2000
            boundsBehavior: Flickable.StopAtBounds
            model: page.participants

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOff
            }

            delegate: Rectangle {
                id: card

                CardShadow {}

                width: ListView.view ? ListView.view.width : 0
                height: 72
                radius: Theme.radiusListCard
                color: Theme.surface
                border.width: 1
                border.color: Theme.withAlpha(Theme.textPrimary, 0.045)
                opacity: modelData.enabled ? 1.0 : 0.6

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 14

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 20
                        color: Theme.primarySoft

                        Text {
                            anchors.centerIn: parent
                            text: modelData.name.length > 0 ? modelData.name.charAt(0) : "?"
                            color: Theme.primary
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 3

                        Text {
                            width: parent.width
                            text: modelData.name
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: "中签 " + modelData.drawCount + " 次 · 连中 " + modelData.streak
                                  + " · " + (modelData.enabled ? "已启用" : "已停用")
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontMicro
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "权重"
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontMicro
                    }

                    TextField {
                        id: weightField

                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 82
                        Layout.preferredHeight: 38
                        text: Number(modelData.weight).toFixed(2)
                        horizontalAlignment: TextInput.AlignHCenter
                        selectByMouse: true
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        leftPadding: 8
                        rightPadding: 8

                        validator: DoubleValidator {
                            bottom: 0.1
                            top: 1000
                            decimals: 2
                        }

                        background: Rectangle {
                            radius: Theme.radiusControl
                            color: weightField.activeFocus ? Theme.surface : Theme.surfaceAlt
                            border.width: 1
                            border.color: weightField.activeFocus
                                          ? Theme.primary
                                          : Theme.withAlpha(Theme.textPrimary, 0.06)
                        }

                        onEditingFinished: {
                            if (!acceptableInput || text.length === 0)
                                return
                            backendBridge.updateParticipantWeight(modelData.id, parseFloat(text))
                        }
                    }
                }
            }

            Item {
                anchors.centerIn: parent
                width: Math.min(360, listView.width - 40)
                height: 120
                visible: listView.count === 0

                Column {
                    width: parent.width
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        width: parent.width
                        text: "名单还是空的"
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontH2
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: "先在添加页创建转盘并导入名字"
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 开关
    // ─────────────────────────────────────────────────────────────
    component DevSwitch: Item {
        id: control

        property bool checked: false
        signal toggled(bool value)

        width: 50
        height: 30

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: control.checked ? Theme.success : Theme.switchOff

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationNormal
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            y: 2
            x: control.checked ? control.width - width - 2 : 2
            width: 26
            height: 26
            radius: 13
            color: Theme.white
            border.width: 1
            border.color: Theme.withAlpha(Theme.textPrimary, 0.08)

            Behavior on x {
                NumberAnimation {
                    duration: Theme.durationNormal
                    easing.type: Easing.OutCubic
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: control.toggled(!control.checked)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 按钮
    // ─────────────────────────────────────────────────────────────
    component DevButton: Item {
        id: button

        property string text: ""
        property bool primary: false
        signal clicked()

        width: 120
        height: 40
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
            font.pixelSize: Theme.fontCaption
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
