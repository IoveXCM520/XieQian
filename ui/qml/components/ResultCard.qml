import QtQuick
import QtQuick.Controls

Item {
    id: cardRoot

    property string winnerName: ""

    signal continueRequested()

    Rectangle {
        anchors.fill: parent
        color: "#F8F6F0"
        opacity: 0.72
    }

    Repeater {
        model: 24

        delegate: Rectangle {
            id: foil

            readonly property int travelTime: 1500 + index * 30

            width: index % 3 === 0 ? 3 : 5
            height: width
            color: index % 4 === 0 ? "#E8CE7A" : "#D4AF37"
            opacity: 0

            x: 30 + (index * 97) % Math.max(1, cardRoot.width - 60)
            y: cardRoot.height * 0.15

            SequentialAnimation {
                running: cardRoot.visible

                PauseAnimation {
                    duration: 120 + index * 45
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: foil
                        property: "y"
                        from: cardRoot.height * 0.15
                        to: cardRoot.height * 0.9
                        duration: foil.travelTime
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: foil
                        property: "opacity"
                        from: 0.85
                        to: 0
                        duration: foil.travelTime
                    }
                    NumberAnimation {
                        target: foil
                        property: "rotation"
                        from: -30
                        to: 210
                        duration: foil.travelTime
                    }
                }
            }
        }
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: Math.min(520, cardRoot.width - 80)
        height: 340
        radius: 2
        color: "#FBF9F4"
        border.width: 1
        border.color: "#D4AF37"

        Column {
            anchors.centerIn: parent
            spacing: 18

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "恭 喜 中 签"
                color: "#D4AF37"
                font.pixelSize: 16
                font.letterSpacing: 6
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 150
                height: 1
                color: "#E3D3A3"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: cardRoot.winnerName
                color: "#2D3E50"
                font.pixelSize: 56
                font.letterSpacing: 8
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 60
                height: 1
                color: "#3F5A4E"
                opacity: 0.5
            }
        }

        Button {
            id: continueButton

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 28

            width: 160
            height: 44
            text: "继 续"

            onClicked: cardRoot.continueRequested()

            background: Rectangle {
                radius: 2
                color: "transparent"
                border.width: 1
                border.color: continueButton.hovered ? "#2D3E50" : "#D4AF37"
            }

            contentItem: Text {
                text: continueButton.text
                color: "#2D3E50"
                font.pixelSize: 16
                font.letterSpacing: 4
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
