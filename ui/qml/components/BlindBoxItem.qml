import QtQuick

Item {
    id: boxRoot

    property color paperColor: "#F8F6F0"
    property color daiColor: "#2D3E50"
    property color goldColor: "#D4AF37"

    property string winnerName: ""

    readonly property int boxCount: 3
    readonly property real boxWidth: 150
    readonly property real boxHeight: 170
    readonly property real boxSpacing: 56

    property int highlightIndex: -1
    property int selectedIndex: -1
    property bool opened: false

    signal selectRequested()
    signal revealFinished()

    implicitWidth: boxCount * boxWidth + (boxCount - 1) * boxSpacing
    implicitHeight: boxHeight + 150

    function startAnimation() {
        reset();
        highlightAnimation.start();
    }

    function reveal(name) {
        winnerName = name;
        selectedIndex = Math.floor(Math.random() * boxCount);
        opened = true;
        revealTimer.start();
    }

    function reset() {
        winnerName = "";
        highlightIndex = -1;
        selectedIndex = -1;
        opened = false;
        revealTimer.stop();
        highlightAnimation.stop();
    }

    Timer {
        id: revealTimer

        interval: 1100
        repeat: false

        onTriggered: boxRoot.revealFinished()
    }

    SequentialAnimation {
        id: highlightAnimation

        loops: 4

        PropertyAction {
            target: boxRoot
            property: "highlightIndex"
            value: 0
        }
        PauseAnimation {
            duration: 130
        }
        PropertyAction {
            target: boxRoot
            property: "highlightIndex"
            value: 1
        }
        PauseAnimation {
            duration: 130
        }
        PropertyAction {
            target: boxRoot
            property: "highlightIndex"
            value: 2
        }
        PauseAnimation {
            duration: 130
        }

        onStopped: {
            // 被 reset() 中断时 highlightIndex 已置为 -1，不应再触发抽取
            if (boxRoot.highlightIndex >= 0) {
                boxRoot.highlightIndex = -1;
                boxRoot.selectRequested();
            }
        }
    }

    Repeater {
        id: boxRepeater

        model: boxRoot.boxCount

        delegate: Item {
            id: box

            property bool open: boxRoot.opened && boxRoot.selectedIndex === index
            property bool dimmed: boxRoot.selectedIndex >= 0 && boxRoot.selectedIndex !== index
            property bool highlighted: boxRoot.highlightIndex === index

            width: boxRoot.boxWidth
            height: boxRoot.boxHeight
            x: index * (boxRoot.boxWidth + boxRoot.boxSpacing)
            y: (boxRoot.height - height) / 2 - (open ? 26 : 0)
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
                height: parent.height - 30
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
                    height: 8
                    color: boxRoot.goldColor
                    opacity: 0.75
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 56
                    height: 56
                    radius: 2
                    color: "transparent"
                    border.width: 1
                    border.color: boxRoot.goldColor
                    opacity: 0.7

                    Text {
                        anchors.centerIn: parent
                        text: "福"
                        color: boxRoot.goldColor
                        font.pixelSize: 26
                    }
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    width: 2
                    color: boxRoot.goldColor
                    opacity: 0.35
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    width: 2
                    color: boxRoot.goldColor
                    opacity: 0.35
                }
            }

            // 盖子：开启时飞出
            Rectangle {
                id: lid

                width: parent.width + 8
                height: 30
                anchors.horizontalCenter: parent.horizontalCenter
                y: open ? -150 : -6
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
                    width: 34
                    height: parent.height
                    opacity: box.open ? 0 : 0.85

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
                        from: -34
                        to: boxRoot.boxWidth + 8
                        duration: 1600 + index * 260
                    }
                }
            }

            // 卷轴：开启后从盒中弹出
            Item {
                id: scroll

                width: 96
                height: 74
                anchors.horizontalCenter: parent.horizontalCenter
                y: open ? -74 : 20
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
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    color: "#FBF3DE"
                    border.width: 1
                    border.color: "#DCC48A"
                }

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 8
                    radius: 4
                    color: "#8C6B1F"
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 8
                    radius: 4
                    color: "#8C6B1F"
                }

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 12
                    text: boxRoot.winnerName
                    color: "#7B2018"
                    font.pixelSize: boxRoot.winnerName.length > 2 ? 20 : 26
                    font.letterSpacing: 2
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
