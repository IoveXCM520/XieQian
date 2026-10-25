import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Item {
    id: page

    readonly property bool reducedMotion: !backendBridge.motionEnabled
    readonly property int modeGroups: 0
    readonly property int modeSeats: 1

    property int mode: modeGroups
    property var groups: []
    property var seats: []
    readonly property int seatColumns: 6

    function startGrouping() {
        if (backendBridge.rosterCount === 0)
            return;

        var count = parseInt(groupCountField.text);
        if (isNaN(count) || count < 1)
            return;

        if (Window.window)
            Window.window.playClick();

        page.groups = backendBridge.generateGroups(count);
    }

    function startSeating() {
        if (backendBridge.rosterCount === 0)
            return;

        if (Window.window)
            Window.window.playClick();

        page.seats = backendBridge.generateSeats();
    }

    Connections {
        target: backendBridge

        function onRosterUpdated() {
            page.groups = [];
            page.seats = [];
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
                text: "教学工具"
                color: "#2D3E50"
                font.pixelSize: 28
                font.letterSpacing: 4
            }

            Text {
                text: backendBridge.rosterCount + " 人"
                color: "#3F5A4E"
                font.pixelSize: 14
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#E4DFD3"
        }

        Rectangle {
            id: modeSwitcher

            implicitWidth: modeRow.implicitWidth + 10
            implicitHeight: 44
            radius: height / 2
            color: "#EFEAE0"
            border.width: 1
            border.color: "#E1D8C6"

            Row {
                id: modeRow

                anchors.centerIn: parent
                spacing: 4

                Repeater {
                    model: ["随机分组", "随机排座位"]

                    delegate: Rectangle {
                        width: modeLabel.implicitWidth + 36
                        height: 36
                        radius: height / 2
                        color: page.mode === index ? "#2D3E50" : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: 180
                            }
                        }

                        Text {
                            id: modeLabel

                            anchors.centerIn: parent
                            text: modelData
                            color: page.mode === index ? "#F8F6F0" : "#6B7A88"
                            font.pixelSize: 14
                            font.letterSpacing: 2
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.mode = index
                        }
                    }
                }
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: page.mode

            // 随机分组
            ColumnLayout {
                spacing: 18

                RowLayout {
                    spacing: 12

                    Text {
                        text: "组数"
                        color: "#3F5A4E"
                        font.pixelSize: 14
                        font.letterSpacing: 2
                    }

                    TextField {
                        id: groupCountField

                        implicitWidth: 90
                        implicitHeight: 40
                        text: "4"
                        selectByMouse: true
                        horizontalAlignment: TextInput.AlignHCenter

                        validator: IntValidator {
                            bottom: 1
                            top: 50
                        }

                        onAccepted: page.startGrouping()
                    }

                    Button {
                        id: groupButton

                        implicitWidth: 150
                        implicitHeight: 40
                        text: "开始分组"
                        enabled: backendBridge.rosterCount > 0 && groupCountField.acceptableInput

                        onClicked: page.startGrouping()

                        background: Rectangle {
                            radius: 2
                            color: groupButton.enabled ? (groupButton.hovered ? "#3A4E63" : "#2D3E50") : "#B9C2CB"
                            border.width: 1
                            border.color: groupButton.enabled ? "#D4AF37" : "#B9C2CB"
                        }

                        contentItem: Text {
                            text: groupButton.text
                            color: "#F8F6F0"
                            font.pixelSize: 14
                            font.letterSpacing: 2
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: page.groups.length > 0 ? "共 " + page.groups.length + " 组" : ""
                        color: "#8A97A5"
                        font.pixelSize: 13
                    }
                }

                ScrollView {
                    id: groupScroll

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: availableWidth
                    contentHeight: groupFlow.height + 8

                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    Flow {
                        id: groupFlow

                        width: groupScroll.availableWidth
                        height: childrenRect.height
                        spacing: 16

                        Repeater {
                            model: page.groups

                            delegate: Rectangle {
                                id: groupCard

                                property bool shown: false

                                width: 220
                                height: cardColumn.childrenRect.height + 32
                                radius: 2
                                color: "#FBF9F4"
                                border.width: 1
                                border.color: "#DCD3C0"
                                opacity: shown ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: page.reducedMotion ? 0 : 260
                                    }
                                }

                                transform: Translate {
                                    y: groupCard.shown ? 0 : 16

                                    Behavior on y {
                                        NumberAnimation {
                                            duration: page.reducedMotion ? 0 : 260
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }

                                Timer {
                                    interval: page.reducedMotion ? 0 : index * 70
                                    running: true
                                    onTriggered: groupCard.shown = true
                                }

                                Column {
                                    id: cardColumn

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 16
                                    spacing: 10

                                    Item {
                                        width: cardColumn.width
                                        height: 22

                                        Text {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "第 " + (index + 1) + " 组"
                                            color: "#8C6B1F"
                                            font.pixelSize: 15
                                            font.letterSpacing: 2
                                        }

                                        Text {
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.length + " 人"
                                            color: "#8A97A5"
                                            font.pixelSize: 12
                                        }
                                    }

                                    Rectangle {
                                        width: cardColumn.width
                                        height: 1
                                        color: "#E7DFCF"
                                    }

                                    Repeater {
                                        model: modelData

                                        delegate: Text {
                                            width: cardColumn.width
                                            text: modelData
                                            color: "#2D3E50"
                                            font.pixelSize: 16
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            width: groupScroll.availableWidth
                            topPadding: 70
                            visible: page.groups.length === 0
                            text: backendBridge.rosterCount > 0 ? "设定组数后点击“开始分组”" : "暂无名单，请先在名单页导入"
                            color: "#8A97A5"
                            font.pixelSize: 16
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }

            // 随机排座位
            ColumnLayout {
                spacing: 18

                RowLayout {
                    spacing: 12

                    Button {
                        id: seatButton

                        implicitWidth: 170
                        implicitHeight: 40
                        text: "生成座位表"
                        enabled: backendBridge.rosterCount > 0

                        onClicked: page.startSeating()

                        background: Rectangle {
                            radius: 2
                            color: seatButton.enabled ? (seatButton.hovered ? "#3A4E63" : "#2D3E50") : "#B9C2CB"
                            border.width: 1
                            border.color: seatButton.enabled ? "#D4AF37" : "#B9C2CB"
                        }

                        contentItem: Text {
                            text: seatButton.text
                            color: "#F8F6F0"
                            font.pixelSize: 14
                            font.letterSpacing: 2
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: page.seats.length > 0
                              ? page.seatColumns + " 列 × " + Math.ceil(page.seats.length / page.seatColumns) + " 行"
                              : ""
                        color: "#8A97A5"
                        font.pixelSize: 13
                    }
                }

                ScrollView {
                    id: seatScroll

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: availableWidth
                    contentHeight: seatContent.height

                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    Item {
                        id: seatContent

                        width: seatScroll.availableWidth
                        height: seatGrid.height + 4

                        Grid {
                            id: seatGrid

                            readonly property real cellWidth: Math.max(1, Math.floor((width - columnSpacing * (page.seatColumns - 1)) / page.seatColumns))
                            readonly property real cellHeight: Math.max(56, Math.round(cellWidth * 0.55))
                            readonly property int rowCount: page.seatColumns > 0
                                                             ? Math.ceil(page.seats.length / page.seatColumns)
                                                             : 0

                            width: parent.width
                            height: rowCount > 0 ? rowCount * cellHeight + (rowCount - 1) * rowSpacing : 0
                            columns: page.seatColumns
                            rowSpacing: 14
                            columnSpacing: 14

                            Repeater {
                                model: page.seats

                                delegate: Rectangle {
                                    id: seatCell

                                    property bool shown: false

                                    width: seatGrid.cellWidth
                                    height: seatGrid.cellHeight
                                    radius: 2
                                    color: "#FBF9F4"
                                    border.width: 1
                                    border.color: "#DCD3C0"
                                    opacity: shown ? 1 : 0

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: page.reducedMotion ? 0 : 240
                                        }
                                    }

                                    transform: Translate {
                                        y: seatCell.shown ? 0 : 18

                                        Behavior on y {
                                            NumberAnimation {
                                                duration: page.reducedMotion ? 0 : 240
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }

                                    Timer {
                                        interval: page.reducedMotion ? 0 : index * 45
                                        running: true
                                        onTriggered: seatCell.shown = true
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        width: parent.width - 16
                                        text: modelData
                                        color: "#2D3E50"
                                        font.pixelSize: 17
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 70
                            visible: page.seats.length === 0
                            text: backendBridge.rosterCount > 0 ? "点击“生成座位表”随机安排座位" : "暂无名单，请先在名单页导入"
                            color: "#8A97A5"
                            font.pixelSize: 16
                        }
                    }
                }
            }
        }
    }
}
