import QtQuick

Item {
    id: flipRoot

    property color paperColor: "#F8F6F0"
    property color cardColor: "#FBF6E9"
    property color daiColor: "#2D3E50"
    property color bambooColor: "#3F5A4E"
    property color goldColor: "#D4AF37"

    property int cardCount: 6
    property bool showPointer: true

    readonly property real availableWidth: 680
    readonly property real cardSpacing: cardCount <= 6 ? 22 : 12
    readonly property real cardWidth: Math.min(92, Math.floor((availableWidth - cardSpacing * (cardCount - 1)) / cardCount))
    readonly property real cardHeight: Math.round(cardWidth * 2.065)

    // 洗牌位移与整体抖动由动画驱动，卡牌位置直接绑定这两个值
    property real spread: 0
    property real shake: 0
    property var winnerNames: []
    property var flippedIndices: []

    signal shuffleFinished()
    signal revealFinished()

    implicitWidth: cardCount * cardWidth + (cardCount - 1) * cardSpacing
    implicitHeight: cardHeight + 56

    function startAnimation() {
        reset();
        shuffleAnimation.start();
    }

    function reveal(names) {
        winnerNames = names;

        var pool = [];
        for (var i = 0; i < cardCount; ++i)
            pool.push(i);
        for (var k = pool.length - 1; k > 0; --k) {
            var j = Math.floor(Math.random() * (k + 1));
            var swap = pool[k];
            pool[k] = pool[j];
            pool[j] = swap;
        }
        flippedIndices = pool.slice(0, Math.min(names.length, cardCount));
        flipAnimation.start();
    }

    function reset() {
        winnerNames = [];
        flippedIndices = [];
        spread = 0;
        shake = 0;
        for (var i = 0; i < cardRepeater.count; ++i) {
            var card = cardRepeater.itemAt(i);
            if (card) {
                card.flipAngle = 0;
                card.lifted = false;
            }
        }
    }

    SequentialAnimation {
        id: shuffleAnimation

        NumberAnimation {
            target: flipRoot
            property: "shake"
            from: 0
            to: -9
            duration: 60
        }
        NumberAnimation {
            target: flipRoot
            property: "shake"
            from: -9
            to: 9
            duration: 80
        }
        NumberAnimation {
            target: flipRoot
            property: "shake"
            from: 9
            to: -6
            duration: 70
        }
        NumberAnimation {
            target: flipRoot
            property: "shake"
            from: -6
            to: 0
            duration: 70
        }
        SequentialAnimation {
            loops: 3

            NumberAnimation {
                target: flipRoot
                property: "spread"
                from: 0
                to: 62
                duration: 150
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: flipRoot
                property: "spread"
                from: 62
                to: 0
                duration: 150
                easing.type: Easing.InOutQuad
            }
        }
        ScriptAction {
            script: flipRoot.shuffleFinished()
        }
    }

    SequentialAnimation {
        id: flipAnimation

        PauseAnimation {
            duration: 140
        }
        ScriptAction {
            script: {
                for (var i = 0; i < flipRoot.flippedIndices.length; ++i) {
                    var card = cardRepeater.itemAt(flipRoot.flippedIndices[i]);
                    if (card)
                        card.lifted = true;
                }
            }
        }
        PauseAnimation {
            duration: 200
        }
        ScriptAction {
            script: {
                for (var i = 0; i < flipRoot.flippedIndices.length; ++i) {
                    var card = cardRepeater.itemAt(flipRoot.flippedIndices[i]);
                    if (card)
                        card.flipAngle = 180;
                }
            }
        }
        PauseAnimation {
            duration: 760
        }
        ScriptAction {
            script: flipRoot.revealFinished()
        }
    }

    Repeater {
        id: cardRepeater

        model: flipRoot.cardCount

        delegate: Item {
            id: card

            property real flipAngle: 0
            property bool lifted: false
            property real bob: 0

            readonly property real baseX: index * (flipRoot.cardWidth + flipRoot.cardSpacing)
            readonly property real faceScale: flipRoot.cardWidth / 92
            readonly property int winnerIndex: flipRoot.flippedIndices.indexOf(index)
            readonly property string userName: winnerIndex >= 0 ? flipRoot.winnerNames[winnerIndex] : ""

            width: flipRoot.cardWidth
            height: flipRoot.cardHeight
            x: baseX + (index % 2 === 0 ? -flipRoot.spread : flipRoot.spread) + flipRoot.shake
            y: (flipRoot.height - height) / 2 - (lifted ? 18 : 0)
            z: winnerIndex >= 0 ? 10 : (index % 2)

            transform: Translate {
                y: card.bob + (index % 2 === 0 ? -7 : 7)
            }

            Behavior on y {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on flipAngle {
                NumberAnimation {
                    duration: 720
                    easing.type: Easing.OutCubic
                }
            }

            SequentialAnimation on bob {
                loops: Animation.Infinite

                NumberAnimation {
                    to: 5
                    duration: 1500 + index * 220
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: -5
                    duration: 1500 + index * 220
                    easing.type: Easing.InOutSine
                }
            }

            // 卡背：宣纸底 + 祥云暗纹
            Item {
                id: backFace

                anchors.fill: parent
                visible: card.flipAngle <= 90

                transform: Rotation {
                    origin.x: backFace.width / 2
                    origin.y: backFace.height / 2
                    axis {
                        x: 0
                        y: 1
                        z: 0
                    }
                    angle: card.flipAngle
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: flipRoot.cardColor
                    border.width: 1
                    border.color: flipRoot.goldColor
                }

                Canvas {
                    anchors.fill: parent
                    anchors.margins: Math.max(3, Math.round(8 * card.faceScale))

                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = "#C9A63E";
                        ctx.globalAlpha = 0.4;
                        ctx.lineWidth = 1;

                        function cloud(cx, cy) {
                            ctx.beginPath();
                            ctx.arc(cx, cy, 9, Math.PI, Math.PI * 2);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.arc(cx - 10, cy, 6, Math.PI, Math.PI * 2);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.arc(cx + 10, cy, 6, Math.PI, Math.PI * 2);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(cx - 18, cy);
                            ctx.lineTo(cx + 18, cy);
                            ctx.stroke();
                        }

                        var rows = 4;
                        for (var row = 0; row < rows; ++row) {
                            var cy = 14 + row * (height - 28) / (rows - 1);
                            var offset = row % 2 === 0 ? -8 : 8;
                            cloud(width / 2 + offset, cy);
                        }
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - Math.max(8, Math.round(22 * card.faceScale))
                    height: parent.height - Math.max(8, Math.round(22 * card.faceScale))
                    radius: 4
                    color: "transparent"
                    border.width: 1
                    border.color: "#E3D3A3"
                }
            }

            // 卡面：中奖者姓名
            Item {
                id: frontFace

                anchors.fill: parent
                visible: card.flipAngle > 90

                transform: Rotation {
                    origin.x: frontFace.width / 2
                    origin.y: frontFace.height / 2
                    axis {
                        x: 0
                        y: 1
                        z: 0
                    }
                    angle: card.flipAngle - 180
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: flipRoot.paperColor
                    border.width: 1
                    border.color: flipRoot.bambooColor
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: Math.max(2, Math.round(6 * card.faceScale))
                    radius: 4
                    color: "transparent"
                    border.width: 1
                    border.color: "#D9D0BC"
                }

                Text {
                    anchors.top: parent.top
                    anchors.topMargin: Math.round(12 * card.faceScale)
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "签"
                    color: flipRoot.goldColor
                    font.pixelSize: Math.max(8, Math.round(12 * card.faceScale))
                    opacity: 0.8
                }

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 16
                    text: card.userName
                    visible: card.winnerIndex >= 0
                    color: flipRoot.daiColor
                    font.pixelSize: Math.max(13, Math.round((card.userName.length > 2 ? 26 : 32) * card.faceScale))
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    lineHeight: 1.15
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: -26
                width: 14
                height: 14
                rotation: 45
                color: flipRoot.goldColor
                visible: flipRoot.showPointer && card.winnerIndex >= 0
            }
        }
    }
}
