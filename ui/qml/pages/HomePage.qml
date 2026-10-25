import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import "../components"

Item {
    id: page

    property var winnerNames: []

    state: "idle"

    function stopSpinSound() {
        if (Window.window)
            Window.window.stopSpin();
    }

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
        if (page.state !== "idle" || backendBridge.rosterCount === 0)
            return;

        page.state = "spinning";
        if (Window.window) {
            Window.window.playClick();
            Window.window.playSpin();
        }
        flipCard.cardCount = Math.max(6, backendBridge.drawCount);
        blindBox.boxCount = Math.max(3, backendBridge.drawCount);

        switch (backendBridge.currentDrawMode) {
        case 0:
            spinAnimation.from = wheel.angle;
            spinAnimation.to = wheel.angle + 1440;
            spinAnimation.start();
            break;
        case 1:
            flipCard.startAnimation();
            break;
        default:
            blindBox.startAnimation();
            break;
        }
    }

    function drawAndReveal() {
        if (backendBridge.drawCount > 1)
            backendBridge.drawMultipleWinners();
        else
            backendBridge.drawWinner();
    }

    function revealWinners(names, mode) {
        page.winnerNames = names;

        switch (mode) {
        case 1:
            flipCard.reveal(names);
            break;
        case 2:
            blindBox.reveal(names);
            break;
        default:
            page.showResult();
            break;
        }
    }

    function showResult() {
        page.stopSpinSound();
        page.state = "result";
        cardFadeIn.start();
    }

    function closeResult() {
        cardFadeOut.start();
    }

    Connections {
        target: backendBridge

        function onWinnerDrawn(name, mode) {
            page.revealWinners([name], mode);
        }

        function onWinnersDrawn(names, mode) {
            page.revealWinners(names, mode);
        }
    }

    RotationAnimation {
        id: spinAnimation

        target: wheel
        property: "angle"
        direction: RotationAnimation.Numerical
        duration: 2500
        easing.type: Easing.OutQuint

        onStopped: {
            page.stopSpinSound();
            if (page.state === "spinning")
                page.drawAndReveal();
        }
    }

    Shortcut {
        sequence: "Space"
        enabled: page.state === "idle" && page.visible && !drawSettings.visible
        onActivated: page.startDraw()
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

        onStopped: {
            page.state = "idle";
            page.winnerNames = [];
            flipCard.reset();
            blindBox.reset();
        }
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
        spacing: 22

        Rectangle {
            id: modeSwitcher

            Layout.alignment: Qt.AlignHCenter
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
                    model: ["大转盘", "翻牌抽签", "盲盒开箱"]

                    delegate: Rectangle {
                        id: modeTab

                        width: modeLabel.implicitWidth + 36
                        height: 36
                        radius: height / 2
                        color: backendBridge.currentDrawMode === index ? "#2D3E50" : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: 180
                            }
                        }

                        Text {
                            id: modeLabel

                            anchors.centerIn: parent
                            text: modelData
                            color: backendBridge.currentDrawMode === index ? "#F8F6F0" : "#6B7A88"
                            font.pixelSize: 14
                            font.letterSpacing: 2
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: page.state === "idle"
                            cursorShape: Qt.PointingHandCursor

                            onClicked: backendBridge.currentDrawMode = index
                        }
                    }
                }
            }
        }

        Item {
            id: visualHost

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 680
            Layout.preferredHeight: 430

            WheelItem {
                id: wheel

                anchors.centerIn: parent
                width: 400
                height: 400
                showPointer: backendBridge.rosterCount > 0
                opacity: backendBridge.currentDrawMode === 0 ? 1 : 0
                visible: opacity > 0.01

                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                    }
                }
            }

            FlipCardItem {
                id: flipCard

                anchors.centerIn: parent
                showPointer: backendBridge.rosterCount > 0
                opacity: backendBridge.currentDrawMode === 1 ? 1 : 0
                visible: opacity > 0.01

                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                    }
                }

                onShuffleFinished: {
                    page.stopSpinSound();
                    page.drawAndReveal();
                }
                onRevealFinished: page.showResult()
            }

            BlindBoxItem {
                id: blindBox

                anchors.centerIn: parent
                opacity: backendBridge.currentDrawMode === 2 ? 1 : 0
                visible: opacity > 0.01

                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                    }
                }

                onSelectRequested: {
                    page.stopSpinSound();
                    page.drawAndReveal();
                }
                onRevealFinished: page.showResult()
            }
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
            enabled: backendBridge.rosterCount > 0
            text: backendBridge.rosterCount > 0 ? "抽 取" : "暂无数据"

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

    Item {
        id: settingsButton

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 24
        anchors.rightMargin: 28
        width: 40
        height: 40

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: settingsArea.containsMouse ? "#D4AF37" : "transparent"

            Behavior on border.color {
                ColorAnimation {
                    duration: 160
                }
            }
        }

        Item {
            id: gearIcon

            anchors.centerIn: parent
            width: 20
            height: 20

            Repeater {
                model: 8

                delegate: Rectangle {
                    width: 3
                    height: gearIcon.height
                    x: (gearIcon.width - width) / 2
                    y: 0
                    radius: 1
                    color: settingsArea.containsMouse ? "#2D3E50" : "#6B7A88"
                    rotation: index * 45
                    transformOrigin: Item.Center
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 15
                height: 15
                radius: width / 2
                color: "#F8F6F0"
                border.width: 2
                border.color: settingsArea.containsMouse ? "#2D3E50" : "#6B7A88"
                Behavior on border.color {
                    ColorAnimation {
                        duration: 160
                    }
                }
            }
        }

        MouseArea {
            id: settingsArea

            anchors.fill: parent
            hoverEnabled: true
            enabled: page.state === "idle"
            cursorShape: Qt.PointingHandCursor

            onClicked: drawSettings.open()
        }
    }

    ResultCard {
        id: resultCard

        anchors.fill: parent
        opacity: 0
        visible: opacity > 0.001
        winnerNames: page.winnerNames

        onContinueRequested: page.closeResult()
    }

    DrawSettingsDialog {
        id: drawSettings

        anchors.fill: parent
    }
}
