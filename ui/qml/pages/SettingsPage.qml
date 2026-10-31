import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import ".."

/*!
    全局设置页。
    - 音效、动效 iOS 风格滑动开关
    - 备份 / 恢复 / 清空数据
*/
Item {
    id: page

    property string pendingRestorePath: ""

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
                    text: "设置"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontH0
                    font.weight: Font.Bold
                }

                Text {
                    text: "让撷签更符合你的课堂习惯"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                }
            }
        }

        Flickable {
            id: flick

            anchors.top: header.bottom
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            contentWidth: width
            contentHeight: settingsColumn.height
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOff
            }

            Column {
                id: settingsColumn

                width: flick.width
                spacing: 8

                Text {
                    width: parent.width
                    text: "偏好设置"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.DemiBold
                    topPadding: 4
                    bottomPadding: 2
                }

                Rectangle {
                    width: parent.width
                    height: 72
                    radius: Theme.radiusListCard
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.textPrimary, 0.045)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 16

                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4

                            Text {
                                text: "音效"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "抽取与中签时播放提示音"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontCaption
                            }
                        }

                        IosSwitch {
                            Layout.alignment: Qt.AlignVCenter
                            checked: backendBridge.soundEnabled
                            onToggled: function(value) {
                                backendBridge.soundEnabled = value
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 72
                    radius: Theme.radiusListCard
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.textPrimary, 0.045)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 16

                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4

                            Text {
                                text: "动效"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "转盘、翻牌与盲盒的完整动画"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontCaption
                            }
                        }

                        IosSwitch {
                            Layout.alignment: Qt.AlignVCenter
                            checked: backendBridge.motionEnabled
                            onToggled: function(value) {
                                backendBridge.motionEnabled = value
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: "数据管理"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.DemiBold
                    topPadding: 14
                    bottomPadding: 2
                }

                Rectangle {
                    width: parent.width
                    height: 76
                    radius: Theme.radiusListCard
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.textPrimary, 0.045)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 16

                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4

                            Text {
                                text: "备份数据"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "将名单、历史与设置导出为 JSON 文件"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontCaption
                            }
                        }

                        SettingButton {
                            Layout.alignment: Qt.AlignVCenter
                            width: 96
                            height: 38
                            text: "备份"
                            soft: true
                            onClicked: {
                                var path = backendBridge.chooseBackupPath()
                                if (path && path.length > 0)
                                    backendBridge.exportData(path)
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 76
                    radius: Theme.radiusListCard
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.textPrimary, 0.045)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 16

                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4

                            Text {
                                text: "恢复数据"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "从 JSON 备份恢复名单、历史与设置"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontCaption
                            }
                        }

                        SettingButton {
                            Layout.alignment: Qt.AlignVCenter
                            width: 96
                            height: 38
                            text: "恢复"
                            soft: false
                            onClicked: {
                                var path = backendBridge.chooseRestorePath()
                                if (path && path.length > 0) {
                                    page.pendingRestorePath = path
                                    restoreDialog.open()
                                }
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: "危险操作"
                    color: Theme.danger
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.DemiBold
                    topPadding: 14
                    bottomPadding: 2
                }

                Rectangle {
                    width: parent.width
                    height: 86
                    radius: Theme.radiusListCard
                    color: Theme.dangerSoft
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.danger, 0.16)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 16

                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4

                            Text {
                                text: "清空所有数据"
                                color: Theme.danger
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "名单与中奖记录将被永久删除，不可撤销"
                                color: Theme.withAlpha(Theme.danger, 0.72)
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontCaption
                            }
                        }

                        SettingButton {
                            Layout.alignment: Qt.AlignVCenter
                            width: 106
                            height: 38
                            text: "清空数据"
                            danger: true
                            onClicked: clearDialog.open()
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 16
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 恢复确认
    // ─────────────────────────────────────────────────────────────
    Dialog {
        id: restoreDialog

        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: 400
        padding: 24

        background: Rectangle {
            radius: Theme.radiusDialog
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
            width: 352
            spacing: 16

            Text {
                width: parent.width
                text: "确认恢复数据？"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontH2
                font.weight: Font.DemiBold
            }

            Text {
                width: parent.width
                text: "恢复后将覆盖当前名单、历史与设置，请确认已选择正确的备份文件。"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontCaption
                wrapMode: Text.WordWrap
                lineHeight: 1.35
            }

            Item {
                width: parent.width
                height: 40

                Row {
                    anchors.right: parent.right
                    height: parent.height
                    spacing: 10

                    SettingButton {
                        width: 92
                        height: 40
                        text: "取消"
                        onClicked: restoreDialog.close()
                    }

                    SettingButton {
                        width: 110
                        height: 40
                        text: "确认恢复"
                        danger: true
                        onClicked: {
                            backendBridge.importData(page.pendingRestorePath)
                            restoreDialog.close()
                        }
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 清空确认
    // ─────────────────────────────────────────────────────────────
    Dialog {
        id: clearDialog

        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: 400
        padding: 24

        background: Rectangle {
            radius: Theme.radiusDialog
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
            width: 352
            spacing: 16

            Text {
                width: parent.width
                text: "清空所有数据？"
                color: Theme.danger
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontH2
                font.weight: Font.DemiBold
            }

            Text {
                width: parent.width
                text: "名单与中奖记录将被永久删除，此操作不可撤销。"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontCaption
                wrapMode: Text.WordWrap
                lineHeight: 1.35
            }

            Item {
                width: parent.width
                height: 40

                Row {
                    anchors.right: parent.right
                    height: parent.height
                    spacing: 10

                    SettingButton {
                        width: 92
                        height: 40
                        text: "取消"
                        onClicked: clearDialog.close()
                    }

                    SettingButton {
                        width: 110
                        height: 40
                        text: "确认清空"
                        danger: true
                        onClicked: {
                            backendBridge.clearAllData()
                            clearDialog.close()
                        }
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // iOS 风格开关
    // ─────────────────────────────────────────────────────────────
    component IosSwitch: Item {
        id: control

        width: 50
        height: 30

        property bool checked: false
        signal toggled(bool value)

        Rectangle {
            id: track
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
            id: knob
            y: 2
            x: control.checked ? control.width - width - 2 : 2
            width: 26
            height: 26
            radius: 13
            color: Theme.white

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.shadowColorStrong
                shadowBlur: 0.35
                shadowVerticalOffset: 1
                shadowHorizontalOffset: 0
                autoPaddingEnabled: true
            }

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
    // 设置按钮
    // ─────────────────────────────────────────────────────────────
    component SettingButton: Item {
        id: button

        property string text: ""
        property bool soft: false
        property bool danger: false
        signal clicked()

        width: 100
        height: 40
        enabled: true
        opacity: enabled ? 1.0 : 0.45
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
                   ? (mouse.containsMouse ? Theme.dangerHover : Theme.danger)
                   : (button.soft
                      ? (mouse.containsMouse ? Theme.primarySoft : Theme.surfaceAlt)
                      : Theme.surface)
            border.width: button.danger ? 0 : 1
            border.color: button.soft
                          ? Theme.withAlpha(Theme.primary, 0.10)
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
            text: button.text
            color: button.danger
                   ? Theme.white
                   : (button.soft ? Theme.primary : Theme.textPrimary)
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
