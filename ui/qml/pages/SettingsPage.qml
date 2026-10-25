import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page

    property string pendingImportPath: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 20

        Text {
            text: "全局设置"
            color: "#2D3E50"
            font.pixelSize: 28
            font.letterSpacing: 4
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#E4DFD3"
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            radius: 2
            color: "#FBF9F4"
            border.width: 1
            border.color: "#E4DFD3"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 16

                Text {
                    Layout.fillWidth: true
                    text: "音效"
                    color: "#2D3E50"
                    font.pixelSize: 16
                }

                Switch {
                    checked: backendBridge.soundEnabled
                    onToggled: backendBridge.soundEnabled = checked
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            radius: 2
            color: "#FBF9F4"
            border.width: 1
            border.color: "#E4DFD3"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 16

                Text {
                    text: "动效强度"
                    color: "#2D3E50"
                    font.pixelSize: 16
                }

                Text {
                    Layout.fillWidth: true
                    text: backendBridge.motionEnabled ? "高" : "低"
                    color: "#8A97A5"
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignRight
                }

                Switch {
                    checked: backendBridge.motionEnabled
                    onToggled: backendBridge.motionEnabled = checked
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            radius: 2
            color: "#FBF9F4"
            border.width: 1
            border.color: "#E4DFD3"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "备份数据"
                        color: "#2D3E50"
                        font.pixelSize: 16
                    }

                    Text {
                        text: "将名单、历史与设置导出为 JSON 文件"
                        color: "#8A97A5"
                        font.pixelSize: 12
                    }
                }

                Button {
                    id: backupButton

                    implicitWidth: 110
                    implicitHeight: 40
                    text: "备份数据"

                    onClicked: {
                        var path = backendBridge.chooseBackupPath();
                        if (path.length > 0)
                            backendBridge.exportData(path);
                    }

                    background: Rectangle {
                        radius: 2
                        color: "transparent"
                        border.width: 1
                        border.color: backupButton.hovered ? "#2D3E50" : "#C9C2B2"
                    }

                    contentItem: Text {
                        text: backupButton.text
                        color: "#3F5A4E"
                        font.pixelSize: 14
                        font.letterSpacing: 2
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            radius: 2
            color: "#FBF9F4"
            border.width: 1
            border.color: "#E4DFD3"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "恢复数据"
                        color: "#2D3E50"
                        font.pixelSize: 16
                    }

                    Text {
                        text: "从 JSON 备份文件恢复名单、历史与设置"
                        color: "#8A97A5"
                        font.pixelSize: 12
                    }
                }

                Button {
                    id: restoreButton

                    implicitWidth: 110
                    implicitHeight: 40
                    text: "恢复数据"

                    onClicked: {
                        var path = backendBridge.chooseRestorePath();
                        if (path.length > 0) {
                            page.pendingImportPath = path;
                            restoreDialog.open();
                        }
                    }

                    background: Rectangle {
                        radius: 2
                        color: restoreButton.hovered ? "#3A4E63" : "#2D3E50"
                        border.width: 1
                        border.color: "#D4AF37"
                    }

                    contentItem: Text {
                        text: restoreButton.text
                        color: "#F8F6F0"
                        font.pixelSize: 14
                        font.letterSpacing: 2
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 92
            radius: 2
            color: "#FBF6F5"
            border.width: 1
            border.color: "#E2C3BE"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "清空所有数据"
                        color: "#8C3A31"
                        font.pixelSize: 16
                    }

                    Text {
                        text: "名单与中奖记录将被永久删除"
                        color: "#A98079"
                        font.pixelSize: 12
                    }
                }

                Button {
                    id: clearButton

                    implicitWidth: 130
                    implicitHeight: 40
                    text: "清空所有数据"

                    onClicked: confirmDialog.open()

                    background: Rectangle {
                        radius: 2
                        color: clearButton.hovered ? "#9B443A" : "#8C3A31"
                    }

                    contentItem: Text {
                        text: clearButton.text
                        color: "#FBF6F5"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    Dialog {
        id: restoreDialog

        anchors.centerIn: Overlay.overlay
        modal: true
        title: "确认恢复"
        padding: 24

        contentItem: Column {
            width: 340
            spacing: 20

            Text {
                width: parent.width
                text: "恢复数据将覆盖当前所有名单和历史，确定吗？"
                color: "#2D3E50"
                font.pixelSize: 15
                wrapMode: Text.WordWrap
            }

            Row {
                x: parent.width - width
                spacing: 12

                Button {
                    id: restoreCancelButton

                    width: 96
                    height: 40
                    text: "取消"

                    onClicked: restoreDialog.close()

                    background: Rectangle {
                        radius: 2
                        color: "transparent"
                        border.width: 1
                        border.color: "#B9C2CB"
                    }

                    contentItem: Text {
                        text: restoreCancelButton.text
                        color: "#2D3E50"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    id: restoreConfirmButton

                    width: 110
                    height: 40
                    text: "确认恢复"

                    onClicked: {
                        backendBridge.importData(page.pendingImportPath);
                        restoreDialog.close();
                    }

                    background: Rectangle {
                        radius: 2
                        color: restoreConfirmButton.hovered ? "#9B443A" : "#8C3A31"
                    }

                    contentItem: Text {
                        text: restoreConfirmButton.text
                        color: "#FBF6F5"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }

    Dialog {
        id: confirmDialog

        anchors.centerIn: Overlay.overlay
        modal: true
        title: "确认清空"
        padding: 24

        contentItem: Column {
            width: 320
            spacing: 20

            Text {
                width: parent.width
                text: "确定要清空名单与历史记录吗？此操作不可撤销。"
                color: "#2D3E50"
                font.pixelSize: 15
                wrapMode: Text.WordWrap
            }

            Row {
                x: parent.width - width
                spacing: 12

                Button {
                    id: cancelButton

                    width: 96
                    height: 40
                    text: "取消"

                    onClicked: confirmDialog.close()

                    background: Rectangle {
                        radius: 2
                        color: "transparent"
                        border.width: 1
                        border.color: "#B9C2CB"
                    }

                    contentItem: Text {
                        text: cancelButton.text
                        color: "#2D3E50"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    id: confirmButton

                    width: 110
                    height: 40
                    text: "确认清空"

                    onClicked: {
                        backendBridge.clearAllData();
                        confirmDialog.close();
                    }

                    background: Rectangle {
                        radius: 2
                        color: confirmButton.hovered ? "#9B443A" : "#8C3A31"
                    }

                    contentItem: Text {
                        text: confirmButton.text
                        color: "#FBF6F5"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
}
