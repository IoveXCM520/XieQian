import QtQuick

Item {
    id: boxRoot

    property color paperColor: "#F8F6F0"
    property color daiColor: "#2D3E50"
    property color goldColor: "#D4AF37"

    property int boxCount: 3

    readonly property real availableWidth: 680
    readonly property real boxSpacing: boxCount <= 3 ? 56 : (boxCount <= 5 ? 30 : 14)
    readonly property real boxWidth: Math.min(150, Math.floor((availableWidth - boxSpacing * (boxCount - 1)) / boxCount))
    readonly property real boxHeight: Math.round(boxWidth * 1.13)
    readonly property real boxScale: boxWidth / 150

    property var winnerNames: []
    property var openedIndices: []
    readonly property bool opened: openedIndices.length > 0

    property real highlightStep: -1
    readonly property int highlightIndex: highlightStep >= 0 ? Math.floor(highlightStep) % boxCount : -1

    signal selectRequested()
    signal revealFinished()

    implicitWidth: boxCount * boxWidth + (boxCount - 1) * boxSpacing
    implicitHeight: boxHeight + Math.round(boxHeight * 0.88)

    function startAnimation() {
        reset();
        highlightAnimation.start();
    }

    function reveal(names) {
        winnerNames = names;

        var pool = [];
        for (var i = 0; i < boxCount; ++i)
            pool.push(i);
        for (var k = pool.length - 1; k > 0; --k) {
            var j = Math.floor(Math.random() * (k + 1));
            var swap = pool[k];
            pool[k] = pool[j];
            pool[j] = swap;
        }
        openedIndices = pool.slice(0, Math.min(names.length, boxCount));
        revealTimer.start();
    }

    function reset() {
        winnerNames = [];
        openedIndices = [];
        highlightStep = -1;
        revealTimer.stop();
        highlightAnimation.stop();
    }

    Timer {
        id: revealTimer

        interval: 1100
        repeat: false

        onTriggered: boxRoot.revealFinished()
    }

    NumberAnimation {
        id: highlightAnimation

        target: boxRoot
        property: "highlightStep"
        from: 0
        to: boxRoot.boxCount * 4
        duration: boxRoot.boxCount * 390
        easing.type: Easing.Linear

        onStopped: {
            // 被 reset() 中断时 highlightStep 已置为 -1，不应再触发抽取
            if (boxRoot.highlightStep >= 0) {
                boxRoot.highlightStep = -1;
                boxRoot.selectRequested();
            }
        }
    }

    Repeater {
        id: boxRepeater

        model: boxRoot.boxCount

        delegate: Item {
            id: box

            readonly property int winnerIndex: boxRoot.openedIndices.indexOf(index)
            readonly property string userName: winnerIndex >= 0 ? boxRoot.winnerNames[winnerIndex] : ""
            readonly property bool open: winnerIndex >= 0
            readonly property bool dimmed: boxRoot.openedIndices.length > 0 && winnerIndex < 0
            readonly property bool highlighted: boxRoot.highlightIndex === index
            readonly property real lidHeight: Math.max(16, Math.round(30 * boxRoot.boxScale))

            width: boxRoot.boxWidth
            height: boxRoot.boxHeight
            x: index * (boxRoot.boxWidth + boxRoot.boxSpacing)
            y: (boxRoot.height - height) / 2 - (open ? Math.round(26 * boxRoot.boxScale) : 0)
            opacity: dimmed ? 0.32 : 1

            Behavior on y {
                NumberAnimation {
                    duration: 520
                    easing.type: Easing.OutBack
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 420
                }
            }

            // 盒身
            Rectangle {
                id: body

                anchors.bottom: parent.bottom
                width: parent.width
                height: parent.height - box.lidHeight
                radius: 4
                border.width: 1
                border.color: boxRoot.goldColor

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: "#B93B2E"
                    }
                    GradientStop {
                        position: 0.55
                        color: "#9C2B21"
                    }
                    GradientStop {
                        position: 1.0
                        color: "#6E1A13"
                    }
                }

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: Math.max(3, Math.round(8 * boxRoot.boxScale))
                    color: boxRoot.goldColor
                    opacity: 0.75
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.max(18, Math.round(56 * boxRoot.boxScale))
                    height: width
                    radius: 2
                    color: "transparent"
                    border.width: 1
                    border.color: boxRoot.goldColor
                    opacity: 0.7

                    Text {
                        anchors.centerIn: parent
                        text: "福"
                        color: boxRoot.goldColor
                        font.pixelSize: Math.max(11, Math.round(26 * boxRoot.boxScale))
                    }
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.leftMargin: Math.max(4, Math.round(10 * boxRoot.boxScale))
                    width: Math.max(1, Math.round(2 * boxRoot.boxScale))
                    color: boxRoot.goldColor
                    opacity: 0.35
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.rightMargin: Math.max(4, Math.round(10 * boxRoot.boxScale))
                    width: Math.max(1, Math.round(2 * boxRoot.boxScale))
                    color: boxRoot.goldColor
                    opacity: 0.35
                }
            }

            // 盖子：开启时飞出
            Rectangle {
                id: lid

                width: parent.width + Math.max(2, Math.round(8 * boxRoot.boxScale))
                height: box.lidHeight
                anchors.horizontalCenter: parent.horizontalCenter
                y: open ? -Math.round(150 * boxRoot.boxScale) : -Math.round(6 * boxRoot.boxScale)
                rotation: open ? -20 : 0
                opacity: open ? 0 : 1
                radius: 4
                clip: true
                border.width: 1
                border.color: "#F0DCA0"

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: "#D4AF37"
                    }
                    GradientStop {
                        position: 0.5
                        color: "#B8912C"
                    }
                    GradientStop {
                        position: 1.0
                        color: "#8C6B1F"
                    }
                }

                Behavior on y {
                    NumberAnimation {
                        duration: 620
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on rotation {
                    NumberAnimation {
                        duration: 620
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: 520
                        easing.type: Easing.InQuad
                    }
                }

                // 金色流光
                Rectangle {
                    id: shimmer

                    width: Math.max(12, Math.round(34 * boxRoot.boxScale))
                    height: parent.height
                    opacity: open ? 0 : 0.85

                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: "transparent"
                        }
                        GradientStop {
                            position: 0.5
                            color: "#FFF3C9"
                        }
                        GradientStop {
                            position: 1.0
                            color: "transparent"
                        }
                    }

                    NumberAnimation on x {
                        running: !box.open
                        loops: Animation.Infinite
                        from: -shimmer.width
                        to: lid.width
                        duration: 1600 + index * 260
                    }
                }
            }

            // 卷轴：开启后从盒中弹出
            Item {
                id: scroll

                width: Math.max(40, Math.round(96 * boxRoot.boxScale))
                height: Math.max(36, Math.round(74 * boxRoot.boxScale))
                anchors.horizontalCenter: parent.horizontalCenter
                y: open ? -(height + Math.round(8 * boxRoot.boxScale)) : Math.round(20 * boxRoot.boxScale)
                scale: open ? 1 : 0.25
                opacity: open ? 1 : 0
                visible: opacity > 0.01
                z: 5

                Behavior on y {
                    NumberAnimation {
                        duration: 520
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 520
                        easing.type: Easing.OutBack
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: 360
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: Math.max(3, Math.round(8 * boxRoot.boxScale))
                    anchors.bottomMargin: anchors.topMargin
                    color: "#FBF3DE"
                    border.width: 1
                    border.color: "#DCC48A"
                }

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: Math.max(3, Math.round(8 * boxRoot.boxScale))
                    radius: 4
                    color: "#8C6B1F"
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.max(3, Math.round(8 * boxRoot.boxScale))
                    radius: 4
                    color: "#8C6B1F"
                }

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 12
                    text: box.userName
                    color: "#7B2018"
                    font.pixelSize: Math.max(11, Math.round((box.userName.length > 2 ? 20 : 26) * boxRoot.boxScale))
                    font.letterSpacing: 1
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }
            }

            // 闪烁高亮
            Rectangle {
                anchors.fill: parent
                radius: 6
                color: boxRoot.goldColor
                opacity: box.highlighted ? 0.45 : 0
                visible: opacity > 0.01

                Behavior on opacity {
                    NumberAnimation {
                        duration: 120
                    }
                }
            }
        }
    }
}
