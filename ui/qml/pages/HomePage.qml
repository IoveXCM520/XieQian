import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../components"

Item {
    id: page

    property string winnerName: ""

    state: "idle"

    states: [
        State {
            name: "idle"
        },
        State {
            name: "spinning"

            PropertyChanges {
                target: drawButton
                enabled: false
                opacity: 0.4
            }
            PropertyChanges {
                target: statusLabel
                opacity: 1
            }
        },
        State {
            name: "result"

            PropertyChanges {
                target: drawButton
                enabled: false
                opacity: 0.4
            }
        }
    ]

    transitions: [
        Transition {
            from: "idle"
            to: "spinning"

            NumberAnimation {
                target: drawButton
                property: "opacity"
                duration: 200
            }
            NumberAnimation {
                target: statusLabel
                property: "opacity"
                duration: 200
            }
        },
        Transition {
            from: "spinning"
            to: "result"

            NumberAnimation {
                target: statusLabel
                property: "opacity"
                duration: 200
            }
        },
        Transition {
            from: "result"
            to: "idle"

            NumberAnimation {
                target: drawButton
                property: "opacity"
                duration: 260
            }
        }
    ]

    function startDraw() {
        if (page.state !== "idle")
            return;

        page.state = "spinning";
        spinAnimation.from = wheel.angle;
        spinAnimation.to = wheel.angle + 1440;
        spinAnimation.start();
    }

    function revealWinner() {
        page.winnerName = backendBridge.drawWinner();
        page.state = "result";
        cardFadeIn.start();
    }

    function closeResult() {
        cardFadeOut.start();
    }

    RotationAnimation {
        id: spinAnimation

        target: wheel
        property: "angle"
        direction: RotationAnimation.Numerical
        duration: 2500
        easing.type: Easing.OutQuint

        onStopped: {
            if (page.state === "spinning")
                page.revealWinner();
        }
    }

    OpacityAnimator {
        id: cardFadeIn

        target: resultCard
        from: 0
        to: 1
        duration: 420
        easing.type: Easing.OutCubic
    }

    OpacityAnimator {
        id: cardFadeOut

        target: resultCard
        from: 1
        to: 0
        duration: 260
        easing.type: Easing.InCubic

        onStopped: page.state = "idle"
    }

    Rectangle {
        id: buttonHalo

        anchors.centerIn: drawButton
        width: drawButton.width + 26
        height: drawButton.height + 26
        radius: 4
        color: "transparent"
        border.width: 1
        border.color: "#D4AF37"
        visible: drawButton.hovered && drawButton.enabled
        opacity: 0

        SequentialAnimation on opacity {
            running: buttonHalo.visible
            loops: Animation.Infinite

            NumberAnimation {
                to: 0.75
                duration: 900
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                to: 0.2
                duration: 900
                easing.type: Easing.InOutSine
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 32

        WheelItem {
            id: wheel

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 420
            Layout.preferredHeight: 420
        }

        Text {
            id: statusLabel

            Layout.alignment: Qt.AlignHCenter
            text: "签 运 流 转"
            color: "#3F5A4E"
            font.pixelSize: 14
            font.letterSpacing: 6
            opacity: 0
        }

        Button {
            id: drawButton

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 220
            implicitHeight: 60
            hoverEnabled: true
            text: "抽 取"

            onClicked: page.startDraw()

            background: Rectangle {
                radius: 2
                color: drawButton.hovered && drawButton.enabled ? "#3A4E63" : "#2D3E50"
                border.width: 1
                border.color: "#D4AF37"
            }

            contentItem: Text {
                text: drawButton.text
                color: "#F8F6F0"
                font.pixelSize: 20
                font.letterSpacing: 6
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    ResultCard {
        id: resultCard

        anchors.fill: parent
        opacity: 0
        visible: opacity > 0.001
        winnerName: page.winnerName

        onContinueRequested: page.closeResult()
    }
}
