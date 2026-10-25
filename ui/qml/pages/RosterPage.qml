import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page

    property var participants: []
    property bool aiBusy: false
    property string aiMessage: ""

    function refresh() {
        participants = backendBridge.getParticipantsWithStatus();
    }

    function weightLabel(value) {
        return "x" + Number(value).toFixed(1);
    }

    function startAiRoster() {
        if (page.aiBusy)
            return;

        page.aiBusy = true;
        page.aiMessage = "";
        backendBridge.aiManager.generateMockRoster();
    }

    Component.onCompleted: refresh()

    Connections {
        target: backendBridge

        function onRosterUpdated() {
            page.refresh();
        }

        function onHistoryUpdated() {
            page.refresh();
        }
    }

    Connections {
        target: backendBridge.aiManager

        function onMockRosterReady(roster) {
            page.aiBusy = false;
            backendBridge.applyMockRoster(roster);
        }

        function onMockRosterFailed(message) {
            page.aiBusy = false;
            page.aiMessage = message;
        }

        function onNetworkError(message) {
            page.aiBusy = false;
            page.aiMessage = message;
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
                id: resetButton

                implicitWidth: 140
                implicitHeight: 40
                text: "重置防连抽"
                enabled: backendBridge.rosterCount > 0

                onClicked: backendBridge.resetDrawnHistory()

                background: Rectangle {
                    radius: 2
                    color: "transparent"
                    border.width: 1
                    border.color: resetButton.hovered ? "#2D3E50" : "#C9C2B2"
                }

                contentItem: Text {
                    text: resetButton.text
                    color: resetButton.enabled ? "#3F5A4E" : "#A4B0BE"
                    font.pixelSize: 14
                    font.letterSpacing: 2
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                id: aiButton

                implicitWidth: 200
                implicitHeight: 40
                text: page.aiBusy ? "AI 正在思考中..." : "✨ AI 生成测试名单"
                enabled: !page.aiBusy && !backendBridge.rosterLoading
                scale: aiButton.pressed ? 0.95 : 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }

                onClicked: page.startAiRoster()

                background: Rectangle {
                    radius: 2
                    color: aiButton.hovered && aiButton.enabled ? "#F3E9D2" : "transparent"
                    border.width: 1
                    border.color: aiButton.enabled ? "#D4AF37" : "#C9C2B2"
                }

                contentItem: Text {
                    text: aiButton.text
                    color: aiButton.enabled ? "#8C6B1F" : "#A4B0BE"
                    font.pixelSize: 14
                    font.letterSpacing: 1
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                id: importButton

                implicitWidth: 150
                implicitHeight: 40
                text: backendBridge.rosterLoading ? "正在解析中..." : "导入 CSV 名单"
                enabled: !backendBridge.rosterLoading
                scale: importButton.pressed ? 0.95 : 1.0

                Behavior on scale {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }

                onClicked: backendBridge.openCsvFileDialog()

                background: Rectangle {
                    radius: 2
                    color: importButton.enabled ? (importButton.hovered ? "#3A4E63" : "#2D3E50") : "#B9C2CB"
                    border.width: 1
                    border.color: importButton.enabled ? "#D4AF37" : "#B9C2CB"
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

        Text {
            Layout.fillWidth: true
            visible: page.aiMessage.length > 0
            text: page.aiMessage
            color: "#B4543F"
            font.pixelSize: 13
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
            cacheBuffer: 2000
            model: page.participants

            delegate: Rectangle {
                width: list.width
                height: 64
                radius: 2
                color: "#FBF9F4"
                border.width: 1
                border.color: modelData.enabled ? "#D8E0D6" : "#E4DFD3"
                opacity: !modelData.enabled ? 0.55 : (modelData.isDrawn ? 0.72 : 1.0)

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: backendBridge.toggleParticipantStatus(modelData.index)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 16

                    RowLayout {
                        Layout.preferredWidth: 230
                        spacing: 8

                        Text {
                            Layout.preferredWidth: 140
                            text: modelData.name
                            color: "#2D3E50"
                            font.pixelSize: 18
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            visible: modelData.isDrawn
                            width: 62
                            height: 22
                            radius: 2
                            color: "transparent"
                            border.width: 1
                            border.color: "#3F5A4E"

                            Text {
                                anchors.centerIn: parent
                                text: "已抽中"
                                color: "#3F5A4E"
                                font.pixelSize: 11
                            }
                        }
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
                        width: 64
                        height: 30
                        radius: 15
                        color: weightArea.containsMouse ? "#EFEAE0" : "transparent"
                        border.width: 1
                        border.color: "#D4AF37"

                        Behavior on color {
                            ColorAnimation {
                                duration: 140
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: page.weightLabel(modelData.weight)
                            color: "#8C6B1F"
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: weightArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                weightDialog.targetId = modelData.id;
                                weightDialog.targetName = modelData.name;
                                weightField.text = modelData.weight.toString();
                                weightDialog.open();
                            }
                        }
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

    Dialog {
        id: weightDialog

        property string targetId: ""
        property string targetName: ""

        anchors.centerIn: parent
        parent: Overlay.overlay
        modal: true
        width: 340
        padding: 24

        background: Rectangle {
            color: "#FBF9F4"
            border.width: 1
            border.color: "#D4AF37"
        }

        contentItem: ColumnLayout {
            spacing: 14

            Text {
                text: weightDialog.targetName + " · 中签权重"
                color: "#2D3E50"
                font.pixelSize: 16
                font.letterSpacing: 2
            }

            TextField {
                id: weightField

                Layout.fillWidth: true
                placeholderText: "大于 0 的数字"
                selectByMouse: true

                validator: DoubleValidator {
                    bottom: 0.1
                    top: 1000
                    decimals: 2
                }

                onAccepted: weightDialog.accept()
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 10

                Button {
                    id: weightCancelButton

                    text: "取 消"
                    implicitWidth: 90
                    implicitHeight: 36

                    onClicked: weightDialog.reject()

                    background: Rectangle {
                        radius: 2
                        color: "transparent"
                        border.width: 1
                        border.color: "#C9C2B2"
                    }

                    contentItem: Text {
                        text: weightCancelButton.text
                        color: "#6B7A88"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    id: weightApplyButton

                    text: "确 定"
                    implicitWidth: 90
                    implicitHeight: 36
                    enabled: weightField.acceptableInput && weightField.text.length > 0

                    onClicked: weightDialog.accept()

                    background: Rectangle {
                        radius: 2
                        color: weightApplyButton.enabled ? "#2D3E50" : "#B9C2CB"
                        border.width: 1
                        border.color: weightApplyButton.enabled ? "#D4AF37" : "#B9C2CB"
                    }

                    contentItem: Text {
                        text: weightApplyButton.text
                        color: "#F8F6F0"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        onAccepted: backendBridge.updateParticipantWeight(targetId, parseFloat(weightField.text))
    }
}
