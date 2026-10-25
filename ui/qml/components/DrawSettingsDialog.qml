import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: dialogRoot

    visible: false
    opacity: 0
    z: 100

    function open() {
        countSpin.value = backendBridge.drawCount;
        for (var i = 0; i < strategyRepeater.count; ++i) {
            var button = strategyRepeater.itemAt(i);
            if (button)
                button.checked = (i === backendBridge.drawStrategy);
        }
        visible = true;
        fadeIn.start();
    }

    function close() {
        fadeOut.start();
    }

    function selectedStrategy() {
        for (var i = 0; i < strategyRepeater.count; ++i) {
            var button = strategyRepeater.itemAt(i);
            if (button && button.checked)
                return i;
        }
        return 0;
    }

    NumberAnimation {
        id: fadeIn

        target: dialogRoot
        property: "opacity"
        from: 0
        to: 1
        duration: 180
    }

    NumberAnimation {
        id: fadeOut

        target: dialogRoot
        property: "opacity"
        from: 1
        to: 0
        duration: 160

        onStopped: dialogRoot.visible = false
    }

    Rectangle {
        anchors.fill: parent
        color: "#1B2A38"
        opacity: 0.42

        MouseArea {
            anchors.fill: parent
            onClicked: dialogRoot.close()
        }
    }

    Rectangle {
        id: panel

        anchors.centerIn: parent
        width: 420
        implicitHeight: form.implicitHeight + 56
        color: "#FBF9F4"
        border.width: 1
        border.color: "#D4AF37"

        ColumnLayout {
            id: form

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 28
            spacing: 18

            Text {
                text: "抽 奖 规 则"
                color: "#2D3E50"
                font.pixelSize: 18
                font.letterSpacing: 4
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#E3D3A3"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "抽取人数"
                    color: "#3F5A4E"
                    font.pixelSize: 14
                }

                Item {
                    Layout.fillWidth: true
                }

                SpinBox {
                    id: countSpin

                    from: 1
                    to: 10
                    editable: true
                    implicitWidth: 130
                    implicitHeight: 40
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "抽奖模式"
                    color: "#3F5A4E"
                    font.pixelSize: 14
                }

                ButtonGroup {
                    id: strategyGroup
                }

                Repeater {
                    id: strategyRepeater

                    model: [
                        { label: "等概率抽取" },
                        { label: "防连抽" },
                        { label: "加权抽取" }
                    ]

                    delegate: RadioButton {
                        Layout.fillWidth: true
                        text: modelData.label
                        font.pixelSize: 14
                        ButtonGroup.group: strategyGroup
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 12

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    id: cancelButton

                    text: "取 消"
                    implicitWidth: 110
                    implicitHeight: 40

                    onClicked: dialogRoot.close()

                    background: Rectangle {
                        radius: 2
                        color: "transparent"
                        border.width: 1
                        border.color: "#C9C2B2"
                    }

                    contentItem: Text {
                        text: cancelButton.text
                        color: "#6B7A88"
                        font.pixelSize: 15
                        font.letterSpacing: 3
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    id: applyButton

                    text: "应 用"
                    implicitWidth: 110
                    implicitHeight: 40

                    onClicked: {
                        backendBridge.updateDrawSettings(countSpin.value, dialogRoot.selectedStrategy());
                        dialogRoot.close();
                    }

                    background: Rectangle {
                        radius: 2
                        color: "#2D3E50"
                        border.width: 1
                        border.color: "#D4AF37"
                    }

                    contentItem: Text {
                        text: applyButton.text
                        color: "#F8F6F0"
                        font.pixelSize: 15
                        font.letterSpacing: 3
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
}
