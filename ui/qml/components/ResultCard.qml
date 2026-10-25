import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtQuick.Particles

Item {
    id: cardRoot

    property var winnerNames: []
    readonly property bool multi: winnerNames.length > 1
    readonly property int columns: winnerNames.length <= 4 ? 2 : 3
    readonly property int rows: multi ? Math.ceil(winnerNames.length / columns) : 1

    signal continueRequested()

    onVisibleChanged: {
        if (cardRoot.visible && Window.window)
            Window.window.playWin();
    }

    Rectangle {
        anchors.fill: parent
        color: "#F8F6F0"
        opacity: 0.72
    }

    // 金箔粒子：贺卡展示期间从顶部持续散落
    ParticleSystem {
        id: foil

        anchors.fill: parent
        z: 1
        running: cardRoot.visible
    }

    Emitter {
        system: foil
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        emitRate: cardRoot.multi ? 36 : 26
        lifeSpan: 2600
        lifeSpanVariation: 800
        size: 10
        sizeVariation: 5

        velocity: AngleDirection {
            angle: 90
            angleVariation: 20
            magnitude: 90
            magnitudeVariation: 45
        }

        acceleration: PointDirection {
            y: 35
            yVariation: 10
        }
    }

    ItemParticle {
        system: foil
        fade: true

        delegate: Rectangle {
            width: 6
            height: 6
            radius: 1
            color: "#D4AF37"
        }
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: cardRoot.multi ? Math.min(760, cardRoot.width - 80) : Math.min(520, cardRoot.width - 80)
        height: cardRoot.multi ? Math.max(300, 170 + cardRoot.rows * 56) : 340
        radius: 2
        color: "#FBF9F4"
        border.width: 1
        border.color: "#D4AF37"

        Text {
            id: titleText

            anchors.top: parent.top
            anchors.topMargin: 28
            anchors.horizontalCenter: parent.horizontalCenter
            text: cardRoot.multi ? "共 " + cardRoot.winnerNames.length + " 位 中 签" : "恭 喜 中 签"
            color: "#D4AF37"
            font.pixelSize: 16
            font.letterSpacing: 6
        }

        Rectangle {
            id: divider

            anchors.top: titleText.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: 150
            height: 1
            color: "#E3D3A3"
        }

        Text {
            anchors.top: divider.bottom
            anchors.topMargin: 28
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !cardRoot.multi
            text: cardRoot.winnerNames.length > 0 ? cardRoot.winnerNames[0] : ""
            color: "#2D3E50"
            font.pixelSize: 56
            font.letterSpacing: 8
        }

        Grid {
            anchors.top: divider.bottom
            anchors.topMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter
            visible: cardRoot.multi
            columns: cardRoot.columns
            spacing: 12

            Repeater {
                model: cardRoot.winnerNames.length

                delegate: Rectangle {
                    width: 150
                    height: 44
                    radius: 2
                    color: "#F8F6F0"
                    border.width: 1
                    border.color: "#E1D8C6"

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 16
                        text: cardRoot.winnerNames[index]
                        color: "#2D3E50"
                        font.pixelSize: 22
                        font.letterSpacing: 2
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }
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
