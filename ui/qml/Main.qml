import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "pages"

ApplicationWindow {
    id: window

    width: 1200
    height: 800
    minimumWidth: 960
    minimumHeight: 640
    visible: true
    title: qsTr("撷签")
    color: "#F8F6F0"

    property int currentPage: 0

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // 左侧导航栏
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 80
            color: "#2D3E50"

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 28
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "签"
                    color: "#F8F6F0"
                    font.pixelSize: 26
                }

                Item {
                    width: 1
                    height: 36
                }

                Repeater {
                    model: [
                        { symbol: "抽", name: "抽奖" },
                        { symbol: "名", name: "名单" },
                        { symbol: "史", name: "历史" }
                    ]

                    delegate: Rectangle {
                        id: navItem

                        width: 80
                        height: 72
                        color: {
                            if (window.currentPage === index)
                                return "#22303F"
                            return hoverArea.containsMouse ? "#28394A" : "transparent"
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.symbol
                            color: window.currentPage === index ? "#F8F6F0" : "#A4B0BE"
                            font.pixelSize: 20
                        }

                        Rectangle {
                            visible: window.currentPage === index
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 2
                            height: 26
                            color: "#C9B48C"
                        }

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.currentPage = index
                        }
                    }
                }
            }
        }

        // 导航与内容区的分隔线
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: "#E4DFD3"
        }

        // 右侧主内容区
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: window.currentPage

            HomePage {}

            RosterPage {}

            HistoryPage {}
        }
    }
}
