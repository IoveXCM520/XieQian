import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page

    property var participants: []

    function refresh() {
        participants = backendBridge.getParticipants();
    }

    Component.onCompleted: refresh()

    Connections {
        target: backendBridge

        function onRosterUpdated() {
            page.refresh();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Text {
                Layout.fillWidth: true
                text: "名单管理"
                color: "#2D3E50"
                font.pixelSize: 28
                font.letterSpacing: 4
            }

            Text {
                text: backendBridge.rosterCount + " 人"
                color: "#3F5A4E"
                font.pixelSize: 14
            }

            Button {
                id: importButton

                implicitWidth: 150
                implicitHeight: 40
                text: "导入 CSV 名单"

                onClicked: backendBridge.openCsvFileDialog()

                background: Rectangle {
                    radius: 2
                    color: importButton.hovered ? "#3A4E63" : "#2D3E50"
                    border.width: 1
                    border.color: "#D4AF37"
                }

                contentItem: Text {
                    text: importButton.text
                    color: "#F8F6F0"
                    font.pixelSize: 14
                    font.letterSpacing: 2
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#E4DFD3"
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10
            clip: true
            model: page.participants

            delegate: Rectangle {
                width: list.width
                height: 64
                radius: 2
                color: "#FBF9F4"
                border.width: 1
                border.color: modelData.enabled ? "#D8E0D6" : "#E4DFD3"
                opacity: modelData.enabled ? 1.0 : 0.55

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 16

                    Text {
                        Layout.preferredWidth: 140
                        text: modelData.name
                        color: "#2D3E50"
                        font.pixelSize: 18
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.group.length > 0 ? modelData.group : "未分组"
                        color: "#3F5A4E"
                        font.pixelSize: 14
                    }

                    Text {
                        text: modelData.studentId
                        color: "#8A97A5"
                        font.pixelSize: 13
                    }

                    Rectangle {
                        width: 10
                        height: 10
                        radius: width / 2
                        color: modelData.enabled ? "#3F5A4E" : "transparent"
                        border.width: 1
                        border.color: modelData.enabled ? "#3F5A4E" : "#B9C2CB"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: backendBridge.toggleParticipantStatus(modelData.index)
                }
            }

            Text {
                anchors.centerIn: parent
                visible: list.count === 0
                text: "暂无名单，点击右上角导入"
                color: "#8A97A5"
                font.pixelSize: 16
            }
        }
    }
}
