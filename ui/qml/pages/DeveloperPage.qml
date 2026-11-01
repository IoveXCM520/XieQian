import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import ".."
import "../components"

/*!
    开发者控制台（隐藏页，不出现在左侧导航）。
    - 权重列表：手动改权重后立刻写回后端并持久化
    - 从成绩单图片识别姓名与分数，按名次重算全员权重
    - 重置抽取状态、切换静态 / 动态权重
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
        statusMessage = "AI 正在读取成绩单…"
        backendBridge.aiManager.ocrScoresFromImage(path)
    }

    function resetDrawState() {
        backendBridge.resetDrawStats()
        statusFailed = false
        statusMessage = "已清空所有人的抽取记录与权重计数"
    }

    // 手动改权重：越界值夹到 0.1 ~ 1000，非法输入由调用方还原原值
    function normalizeWeight(rawValue) {
        var value = Number(String(rawValue).replace(",", "."))
        if (!isFinite(value) || value <= 0)
            return NaN
        return Math.max(0.1, Math.min(1000, value))
    }

    function reportWeightSaved() {
        statusFailed = false
        statusMessage = "权重已保存"
    }

    function reportWeightInvalid() {
        statusFailed = true
        statusMessage = "权重需要是大于 0 的数字"
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
                                 ? "已按成绩重算 " + updated + " 人的权重，其他人落到最低档"
                                 : "成绩单上的名字不在名单里"
            page.refresh()
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
            height: 76

            Column {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                spacing: 2

                Text {
                    text: "开发者控制台"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLargeTitle
                    font.weight: Font.Bold
                }

                Text {
                    text: "权重调校 · 成绩单调权 · 状态重置"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "返回设置"
                color: Theme.primary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.goBack()
                }
            }
        }

        RowLayout {
            id: actionRow

            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 12

            // 权重模式
            Rectangle {
                Layout.preferredWidth: 360
                Layout.preferredHeight: 92
                radius: Theme.radiusCard
                color: Theme.surface

                CardShadow {}

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.cardPadding
                    anchors.rightMargin: Theme.cardPadding
                    spacing: 12

                    Column {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            text: backendBridge.dynamicWeights ? "动态权重" : "静态权重"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                        }

                        Text {
                            width: parent.width
                            text: "被选中越多次，下一次出现得越少"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                            wrapMode: Text.WordWrap
                        }
                    }

                    IosSwitch {
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
                Layout.preferredHeight: 92
                radius: Theme.radiusCard
                color: Theme.surface

                CardShadow {}

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.cardPadding
                    anchors.rightMargin: Theme.cardPadding
                    spacing: 12

                    DevButton {
                        Layout.alignment: Qt.AlignVCenter
                        width: 170
                        height: 42
                        primary: true
                        text: page.ocrBusy ? "识别中…" : "从成绩单调权"
                        enabled: !page.ocrBusy
                        onClicked: page.adjustFromScoreSheet()
                    }

                    DevButton {
                        Layout.alignment: Qt.AlignVCenter
                        width: 124
                        height: 42
                        text: "重置状态"
                        onClicked: page.resetDrawState()
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: page.statusMessage
                        visible: text.length > 0
                        color: page.statusFailed ? Theme.danger : Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontCaption
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
                height: 70
                radius: Theme.radiusListCard
                color: Theme.surface
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
                            text: "被选中 " + modelData.drawCount + " 次 · 连续 "
                                  + modelData.streak + " 次"
                                  + (modelData.enabled ? "" : " · 已停用")
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "权重"
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontCaption
                    }

                    TextField {
                        id: weightField

                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 84
                        Layout.preferredHeight: 38
                        text: Number(modelData.weight).toFixed(2)
                        horizontalAlignment: TextInput.AlignHCenter
                        selectByMouse: true
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        leftPadding: 8
                        rightPadding: 8

                        validator: DoubleValidator {
                            bottom: 0.1
                            top: 1000
                            decimals: 2
                            notation: DoubleValidator.StandardNotation
                            locale: "C"
                        }

                        background: Rectangle {
                            radius: 10
                            color: Theme.fill
                            border.width: weightField.activeFocus ? 1 : 0
                            border.color: Theme.primary
                        }

                        onEditingFinished: {
                            var value = page.normalizeWeight(text)
                            if (isNaN(value)) {
                                text = Number(modelData.weight).toFixed(2)
                                page.reportWeightInvalid()
                                return
                            }

                            text = value.toFixed(2)
                            if (Math.abs(value - Number(modelData.weight)) < 0.0001)
                                return

                            backendBridge.updateParticipantWeight(modelData.id, value)
                            page.reportWeightSaved()
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
                        text: "先去添加页导入一份数据"
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
    // 按钮
    // ─────────────────────────────────────────────────────────────
    component DevButton: Item {
        id: button

        property string text: ""
        property bool primary: false
        signal clicked()

        width: 120
        height: 42
        enabled: true
        opacity: enabled ? 1.0 : 0.45
        scale: mouse.pressed && enabled ? 0.96 : 1.0

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
            radius: Theme.radiusButton
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
            border.color: Theme.separator
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusButton
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
