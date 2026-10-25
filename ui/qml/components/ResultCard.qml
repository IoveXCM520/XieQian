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

    property bool aiBusy: false
    property string aiSpeech: ""
    property string aiError: ""
    property real speechOpacity: 0
    readonly property string awardWinnerName: winnerNames.length > 0 ? winnerNames[0] : ""

    signal continueRequested()

    function requestAiSpeech() {
        if (cardRoot.aiBusy || cardRoot.awardWinnerName.length === 0)
            return;

        cardRoot.aiBusy = true;
        cardRoot.aiError = "";
        backendBridge.aiManager.generateAwardSpeech(cardRoot.awardWinnerName);
    }

    onVisibleChanged: {
        if (cardRoot.visible) {
            if (Window.window)
                Window.window.playWin();
        } else {
            cardRoot.aiBusy = false;
            cardRoot.aiSpeech = "";
            cardRoot.aiError = "";
            cardRoot.speechOpacity = 0;
        }
    }

    Connections {
        target: backendBridge.aiManager

        function onAwardSpeechReady(speech) {
            if (!cardRoot.visible)
                return;
            cardRoot.aiBusy = false;
            cardRoot.aiSpeech = speech;
            speechFadeIn.start();
        }

        function onAwardSpeechFailed(message) {
            if (!cardRoot.visible)
                return;
            cardRoot.aiBusy = false;
            cardRoot.aiError = message;
        }

        function onNetworkError(message) {
            if (!cardRoot.visible)
                return;
            cardRoot.aiBusy = false;
            cardRoot.aiError = message;
        }
    }

    NumberAnimation {
        id: speechFadeIn

        target: cardRoot
        property: "speechOpacity"
        from: 0
        to: 1
        duration: 420
        easing.type: Easing.OutCubic
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
        maximumEmitted: cardRoot.multi ? 60 : 40
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
            id: winnerNameText

            anchors.top: divider.bottom
            anchors.topMargin: 28
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !cardRoot.multi
            text: cardRoot.winnerNames.length > 0 ? cardRoot.winnerNames[0] : ""
            color: "#2D3E50"
            font.pixelSize: 56
            font.letterSpacing: 8
        }

        Button {
            id: aiButton

            anchors.top: winnerNameText.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: 170
            height: 32
            visible: !cardRoot.multi && cardRoot.aiSpeech.length === 0
            enabled: !cardRoot.aiBusy
            text: cardRoot.aiBusy ? "思考中..." : "✨ 获取 AI 点评"
            scale: aiButton.pressed ? 0.95 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }

            onClicked: cardRoot.requestAiSpeech()

            background: Rectangle {
                radius: 2
                color: aiButton.hovered && aiButton.enabled ? "#F3E9D2" : "transparent"
                border.width: 1
                border.color: aiButton.enabled ? "#D4AF37" : "#C9C2B2"
            }

            contentItem: Text {
                text: aiButton.text
                color: aiButton.enabled ? "#8C6B1F" : "#A4A094"
                font.pixelSize: 13
                font.letterSpacing: 1
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        Text {
            id: speechText

            anchors.top: aiButton.bottom
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 80
            text: cardRoot.aiSpeech
            visible: cardRoot.speechOpacity > 0.001
            opacity: cardRoot.speechOpacity
            color: "#3F5A4E"
            font.pixelSize: 14
            lineHeight: 1.25
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            anchors.top: aiButton.bottom
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            visible: cardRoot.aiError.length > 0 && !cardRoot.multi
            text: cardRoot.aiError
            color: "#B4543F"
            font.pixelSize: 12
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
