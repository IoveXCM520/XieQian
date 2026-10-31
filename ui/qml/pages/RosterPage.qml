import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import ".."
import "../components"

/*!
    名单管理页。
    - CSV / TXT 导入 / 重置抽取状态
    - 白色圆角卡片列表，隐藏滚动条
    - 首字母头像、姓名学号、权重胶囊、状态胶囊
*/
Item {
    id: page

    property var participants: []
    property string removeTargetId: ""
    property string removeTargetName: ""

    readonly property bool loading: backendBridge.rosterLoading
    readonly property int totalCount: backendBridge.rosterCount

    function refresh() {
        participants = backendBridge.getParticipantsWithStatus()
    }

    function initialOf(name) {
        if (!name || name.length === 0)
            return "?"
        return name.charAt(0)
    }

    function weightLabel(value) {
        return "x" + Number(value).toFixed(1)
    }

    function statusText(item) {
        if (!item.enabled)
            return "已停用"
        if (item.isDrawn)
            return "已抽中"
        return "可抽取"
    }

    function statusColor(item) {
        if (!item.enabled)
            return Theme.textTertiary
        if (item.isDrawn)
            return Theme.primary
        return Theme.success
    }

    function statusBackground(item) {
        if (!item.enabled)
            return Theme.surfaceAlt
        if (item.isDrawn)
            return Theme.primarySoft
        return Theme.successSoft
    }

    function openWeightDialog(item) {
        weightDialog.targetId = item.id
        weightDialog.targetName = item.name
        weightField.text = item.weight.toString()
        weightDialog.open()
    }

    function requestRemove(item) {
        removeTargetId = item.id
        removeTargetName = item.name
        removeDialog.open()
    }

    Component.onCompleted: refresh()

    Connections {
        target: backendBridge

        function onRosterUpdated() {
            page.refresh()
        }

        function onHistoryUpdated() {
            page.refresh()
        }

        function onRosterLoadingChanged() {
            if (!backendBridge.rosterLoading)
                page.refresh()
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
                    text: "名单管理"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontH0
                    font.weight: Font.Bold
                }

                Text {
                    text: "导入班级名单，CSV 与 TXT 都支持"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 32
                width: countRow.implicitWidth + 22
                radius: 16
                color: Theme.surface
                border.width: 1
                border.color: Theme.withAlpha(Theme.primary, 0.10)

                RowLayout {
                    id: countRow
                    anchors.centerIn: parent
                    spacing: 7

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 7
                        Layout.preferredHeight: 7
                        radius: 3.5
                        color: page.totalCount > 0 ? Theme.success : Theme.textTertiary
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: page.totalCount + " 人"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontCaption
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        // ─────────────────────────────────────────────────────────
        // 工具栏
        // ─────────────────────────────────────────────────────────
        Row {
            id: toolbar
            anchors.top: header.bottom
            anchors.topMargin: 14
            anchors.right: parent.right
            spacing: 10

            RosterButton {
                width: 124
                height: 40
                text: "重置抽取状态"
                enabled: page.totalCount > 0 && !page.loading
                onClicked: backendBridge.resetDrawnHistory()
            }

            RosterButton {
                width: 130
                height: 40
                text: page.loading ? "正在解析…" : "导入名单"
                primary: true
                enabled: !page.loading
                onClicked: backendBridge.openRosterFileDialog()
            }
        }

        // ─────────────────────────────────────────────────────────
        // 名单列表
        // ─────────────────────────────────────────────────────────
        ListView {
            id: listView

            anchors.top: toolbar.bottom
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
                border.color: cardMouse.containsMouse
                              ? Theme.withAlpha(Theme.primary, 0.22)
                              : Theme.withAlpha(Theme.textPrimary, 0.045)
                opacity: !modelData.enabled ? 0.55 : (modelData.isDrawn ? 0.78 : 1.0)
                scale: cardMouse.pressed ? 0.995 : (cardMouse.containsMouse ? 1.002 : 1.0)

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

                Behavior on border.color {
                    ColorAnimation {
                        duration: Theme.durationFast
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: backendBridge.toggleParticipantStatus(modelData.index)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 14

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        radius: 21
                        color: Theme.primarySoft

                        Text {
                            anchors.centerIn: parent
                            text: page.initialOf(modelData.name)
                            color: Theme.primary
                            font.family: Theme.fontFamily
                            font.pixelSize: 17
                            font.weight: Font.Bold
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

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
                            text: modelData.studentId + (modelData.group.length > 0 ? " · " + modelData.group : "")
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        id: weightPill
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 68
                        Layout.preferredHeight: 28
                        radius: 14
                        color: weightMouse.containsMouse
                               ? Theme.primarySoft
                               : Theme.surfaceAlt
                        scale: weightMouse.pressed
                               ? 0.95
                               : (weightMouse.containsMouse ? 1.02 : 1.0)

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

                        Text {
                            anchors.centerIn: parent
                            text: page.weightLabel(modelData.weight)
                            color: Theme.primary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: weightMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.openWeightDialog(modelData)
                        }
                    }

                    Rectangle {
                        id: statusPill
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: statusLabel.implicitWidth + 20
                        Layout.preferredHeight: 24
                        radius: 12
                        color: page.statusBackground(modelData)

                        Text {
                            id: statusLabel
                            anchors.centerIn: parent
                            text: page.statusText(modelData)
                            color: page.statusColor(modelData)
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                    }

                    // 移除该成员：点击后需要确认，避免误触
                    Item {
                        id: removeAction

                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32

                        Rectangle {
                            anchors.fill: parent
                            radius: 9
                            color: removeMouse.containsMouse
                                   ? Theme.dangerSoft
                                   : Theme.transparent

                            Behavior on color {
                                ColorAnimation {
                                    duration: Theme.durationFast
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Canvas {
                            id: removeIcon

                            width: 14
                            height: 14
                            anchors.centerIn: parent
                            opacity: removeMouse.containsMouse ? 1.0 : 0.6

                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                            Component.onCompleted: requestPaint()

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                ctx.strokeStyle = removeMouse.containsMouse
                                                 ? String(Theme.danger)
                                                 : String(Theme.textSecondary)
                                ctx.lineWidth = 1.5
                                ctx.lineCap = "round"
                                ctx.beginPath()
                                ctx.moveTo(2.5, 2.5)
                                ctx.lineTo(11.5, 11.5)
                                ctx.moveTo(11.5, 2.5)
                                ctx.lineTo(2.5, 11.5)
                                ctx.stroke()
                            }
                        }

                        MouseArea {
                            id: removeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onContainsMouseChanged: removeIcon.requestPaint()
                            onClicked: page.requestRemove(modelData)
                        }
                    }
                }
            }

            // 空状态
            Item {
                anchors.centerIn: parent
                width: Math.min(360, listView.width - 40)
                height: 150
                visible: listView.count === 0 && !page.loading

                Column {
                    width: parent.width
                    anchors.centerIn: parent
                    spacing: 12

                    Item {
                        width: parent.width
                        height: 64

                        Rectangle {
                            width: 64
                            height: 64
                            radius: 32
                            anchors.centerIn: parent
                            color: Theme.primarySoft

                            Text {
                                anchors.centerIn: parent
                                text: "名"
                                color: Theme.primary
                                font.family: Theme.fontFamily
                                font.pixelSize: 24
                                font.weight: Font.Bold
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: "名单还是空的"
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: "导入 CSV 或 TXT 名单，开始抽取"
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
    // 权重编辑
    // ─────────────────────────────────────────────────────────────
    Dialog {
        id: weightDialog

        property string targetId: ""
        property string targetName: ""

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
                text: weightDialog.targetName + " · 中签权重"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontH2
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: "权重越高，被抽中的概率越大。"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
            }

            TextField {
                id: weightField
                width: parent.width
                height: 44
                placeholderText: "大于 0 的数字"
                placeholderTextColor: Theme.textTertiary
                selectByMouse: true
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                leftPadding: 14

                validator: DoubleValidator {
                    bottom: 0.1
                    top: 1000
                    decimals: 2
                }

                background: Rectangle {
                    radius: Theme.radiusControl
                    color: Theme.surfaceAlt
                    border.width: 1
                    border.color: weightField.activeFocus
                                  ? Theme.primary
                                  : Theme.withAlpha(Theme.textPrimary, 0.06)
                }

                onAccepted: weightDialog.accept()
            }

            Item {
                width: parent.width
                height: 40

                Row {
                    anchors.right: parent.right
                    height: parent.height
                    spacing: 10

                    RosterButton {
                        width: 92
                        height: 40
                        text: "取消"
                        onClicked: weightDialog.reject()
                    }

                    RosterButton {
                        width: 100
                        height: 40
                        text: "确认"
                        primary: true
                        enabled: weightField.acceptableInput
                                 && weightField.text.length > 0
                        onClicked: weightDialog.accept()
                    }
                }
            }
        }

        onAccepted: {
            backendBridge.updateParticipantWeight(weightDialog.targetId,
                                                  parseFloat(weightField.text))
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 移除成员确认
    // ─────────────────────────────────────────────────────────────
    Dialog {
        id: removeDialog

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
                text: "从名单中移除「" + page.removeTargetName + "」？"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontH2
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: "移除后该成员不再参与抽签，已产生的抽取历史会保留。"
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

                    RosterButton {
                        width: 92
                        height: 40
                        text: "取消"
                        onClicked: removeDialog.reject()
                    }

                    RosterButton {
                        width: 100
                        height: 40
                        text: "移除"
                        primary: true
                        onClicked: removeDialog.accept()
                    }
                }
            }
        }

        onAccepted: backendBridge.removeParticipant(page.removeTargetId)
    }

    // ─────────────────────────────────────────────────────────────
    // 通用按钮
    // ─────────────────────────────────────────────────────────────
    component RosterButton: Item {
        id: button

        property string text: ""
        property bool primary: false
        signal clicked()

        implicitWidth: 130
        implicitHeight: 40
        width: 130
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
