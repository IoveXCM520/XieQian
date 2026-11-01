import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import ".."
import "../components"

/*!
    名单管理页。
    - 只保留头像、姓名（附带学号/分组）、启用开关与删除
    - 姓名按字数插入空格，让纵向列表看起来整齐
*/
Item {
    id: page

    anchors.fill: parent

    property var participants: []
    property string removeTargetId: ""
    property string removeTargetName: ""

    readonly property int totalCount: backendBridge.rosterCount

    function refresh() {
        participants = backendBridge.getParticipantsWithStatus()
    }

    function initialOf(name) {
        if (!name || name.length === 0)
            return "?"
        return name.charAt(0)
    }

    // 两字名中间补全角空格，三字名在姓与名之间补半角空格
    function displayName(name) {
        if (!name || name.length === 0)
            return ""
        if (name.length === 2)
            return name.charAt(0) + "\u3000" + name.charAt(1)
        if (name.length === 3)
            return name.charAt(0) + " " + name.substring(1)
        return name
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
    }

    // 每次进入页面重新取一次，避免后台改动后看到旧数据
    onVisibleChanged: {
        if (visible)
            refresh()
    }

    Item {
        id: pageContent
        anchors.fill: parent
        anchors.margins: Theme.pagePadding

        // ─────────────────────────────────────────────────────────
        // iOS 大标题
        // ─────────────────────────────────────────────────────────
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
                    text: "名单"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLargeTitle
                    font.weight: Font.Bold
                }

                Text {
                    text: "左侧开关决定谁参与这一轮"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 30
                width: countRow.implicitWidth + 22
                radius: 15
                color: Theme.surface

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
        // 名单列表
        // ─────────────────────────────────────────────────────────
        ListView {
            id: listView

            anchors.top: header.bottom
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
                opacity: modelData.enabled ? 1.0 : 0.55
                scale: cardMouse.containsMouse ? 1.002 : 1.0

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

                MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    hoverEnabled: true
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
                            text: page.displayName(modelData.name)
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

                    IosSwitch {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 46
                        Layout.preferredHeight: 28
                        checked: modelData.enabled
                        onToggled: function(value) {
                            if (value !== modelData.enabled)
                                backendBridge.toggleParticipantStatus(modelData.index)
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
                visible: listView.count === 0

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
                        text: "还没有任何人"
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: "去添加页导入一份数据，就能开始抽了"
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
                text: "把「" + page.removeTargetName + "」移出名单？"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontH2
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: "移出后不再参与抽签，抽过的记录还会留着。"
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
        implicitHeight: 44
        width: 130
        height: 44
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
