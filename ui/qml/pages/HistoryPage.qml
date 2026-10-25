import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page

    property var records: []

    function refresh() {
        records = backendBridge.getHistory();
    }

    Component.onCompleted: refresh()

    Connections {
        target: backendBridge

        function onHistoryUpdated() {
            page.refresh();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 20

        Text {
            text: "历史记录"
            color: "#2D3E50"
            font.pixelSize: 28
            font.letterSpacing: 4
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
            clip: true
            cacheBuffer: 2000
            model: page.records

            delegate: Item {
                width: list.width
                height: 56

                RowLayout {
                    anchors.fill: parent
                    spacing: 16

                    Text {
                        text: modelData.name
                        color: "#2D3E50"
                        font.pixelSize: 18
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: modelData.time
                        color: "#8A97A5"
                        font.pixelSize: 13
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: "#E4DFD3"
                }
            }

            Text {
                anchors.centerIn: parent
                visible: list.count === 0
                text: "暂无中奖记录"
                color: "#8A97A5"
                font.pixelSize: 16
            }
        }
    }
}
