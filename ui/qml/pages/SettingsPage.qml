import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page

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
                    text: backendBridge.highMotion ? "高" : "低"
                    color: "#8A97A5"
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignRight
                }

                Switch {
                    checked: backendBridge.highMotion
                    onToggled: backendBridge.highMotion = checked
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
