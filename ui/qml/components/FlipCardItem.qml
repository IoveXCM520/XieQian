import QtQuick

import ".."

/*!
    现代翻牌抽签组件。
    - 6 张 3:4 圆角卡片，radius 16
    - 卡背纯白 + 极淡对角线蓝绿微光 + 极简几何线条
    - startFlip()：PathAnimation 发牌 → 选中一张 → Y 轴 3D 翻转 0→180°
    - 发牌结束发出 shuffleFinished()，供外部在此期间写入 winnerName
    - 翻转结束发出 finished()
*/
Item {
    id: flipRoot

    implicitWidth: 680
    implicitHeight: 380

    readonly property int cardCount: 6
    readonly property real cardWidth: Math.max(0, Math.min(width * 0.14, height * 0.28))
    readonly property real cardHeight: cardWidth * 4 / 3
    readonly property real cardSpacing: cardWidth * 0.22
    readonly property real fanWidth: cardCount * cardWidth
                                           + (cardCount - 1) * cardSpacing
    readonly property real fanStartX: (width - fanWidth) / 2
    readonly property real fanBaseY: (height - cardHeight) / 2

    readonly property bool running: (!!masterAnimation && masterAnimation.running) || (!!flipAnimation && flipAnimation.running)

    property string winnerName: ""
    property int selectedIndex: -1
    property bool flipActive: false
    property bool settled: false

    signal shuffleFinished()
    signal finished()

    function startFlip() {
        if (running)
            return

        reset()
        flipActive = true

        // 随机发牌顺序，让洗牌过程更有随机感
        var order = []
        for (var i = 0; i < cardCount; ++i)
            order.push(i)
        for (var k = order.length - 1; k > 0; --k) {
            var j = Math.floor(Math.random() * (k + 1))
            var swap = order[k]
            order[k] = order[j]
            order[j] = swap
        }

        for (var n = 0; n < cardCount; ++n) {
            var card = cardRepeater.itemAt(n)
            if (card)
                card.deal(order[n])
        }

        masterAnimation.start()
    }

    function reset() {
        flipActive = false
        settled = false
        selectedIndex = -1
        masterAnimation.stop()
        flipAnimation.stop()

        for (var i = 0; i < cardRepeater.count; ++i) {
            var card = cardRepeater.itemAt(i)
            if (card)
                card.resetCard()
        }
    }

    function selectRandomCard() {
        selectedIndex = Math.floor(Math.random() * cardCount)
    }

    function beginFlip() {
        var slot = cardRepeater.itemAt(selectedIndex)
        if (!slot || !slot.cardItem) {
            flipActive = false
            settled = true
            finished()
            return
        }

        var targetCard = slot.cardItem
        flipAngleAnimation.target = targetCard
        flipAngleAnimation.from = targetCard.flipAngle
        flipLiftAnimation.target = targetCard
        flipLiftAnimation.from = targetCard.lift
        flipAnimation.start()
    }

    function resetDeck() {
        if (!cardRepeater)
            return

        for (var i = 0; i < cardRepeater.count; ++i) {
            var card = cardRepeater.itemAt(i)
            if (card)
                card.resetCard()
        }
    }

    onWidthChanged: {
        if (!running && !settled)
            resetDeck()
    }

    onHeightChanged: {
        if (!running && !settled)
            resetDeck()
    }

    // 发牌总时长约 925ms，留一点缓冲后进入翻牌阶段
    SequentialAnimation {
        id: masterAnimation

        PauseAnimation {
            duration: 1000
        }

        ScriptAction {
            script: {
                flipRoot.shuffleFinished()
                flipRoot.selectRandomCard()
            }
        }

        PauseAnimation {
            duration: 260
        }

        ScriptAction {
            script: flipRoot.beginFlip()
        }
    }

    ParallelAnimation {
        id: flipAnimation

        NumberAnimation {
            id: flipAngleAnimation
            property: "flipAngle"
            to: 180
            duration: 760
            easing.type: Easing.InOutCubic
        }

        NumberAnimation {
            id: flipLiftAnimation
            property: "lift"
            to: 18
            duration: 360
            easing.type: Easing.OutCubic
        }

        onStopped: {
            if (flipRoot.flipActive) {
                flipRoot.flipActive = false
                flipRoot.settled = true
                flipRoot.finished()
            }
        }
    }

    Repeater {
        id: cardRepeater
        model: flipRoot.cardCount

        delegate: Item {
            id: slot

            width: flipRoot.cardWidth
            height: flipRoot.cardHeight
            x: flipRoot.fanStartX
               + index * (flipRoot.cardWidth + flipRoot.cardSpacing)
            y: flipRoot.fanBaseY
               + Math.abs(offset) * (flipRoot.cardHeight * 0.05)

            readonly property real offset: index - (flipRoot.cardCount - 1) / 2
            readonly property bool selected: flipRoot.selectedIndex === index
            readonly property real deckX: flipRoot.width / 2 - x - flipRoot.cardWidth / 2
            readonly property real deckY: flipRoot.height / 2 - y - flipRoot.cardHeight / 2
            readonly property Item cardItem: card

            rotation: selected ? 0 : offset * 4.0
            z: selected ? 30 : 20 - Math.abs(offset)

            Behavior on rotation {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }

            Item {
                id: card

                width: slot.width
                height: slot.height
                x: slot.deckX
                y: slot.deckY
                z: slot.selected ? 50 : 0

                property real flipAngle: 0
                property real lift: 0
                readonly property real startX: slot.deckX
                readonly property real startY: slot.deckY

                scale: 1 + lift * 0.0035

                transform: [
                    Rotation {
                        axis.x: 0
                        axis.y: 1
                        axis.z: 0
                        angle: card.flipAngle
                        origin.x: card.width / 2
                        origin.y: card.height / 2
                    },
                    Translate {
                        y: -card.lift
                    }
                ]

                // 卡片底部的极淡投影
                Rectangle {
                    x: 0
                    y: 4
                    width: parent.width
                    height: parent.height
                    radius: 16
                    color: "#0A000000"
                    z: -1
                }

                // ─────────────────────────────────────────────
                // 卡背
                // ─────────────────────────────────────────────
                Canvas {
                    id: backCanvas
                    anchors.fill: parent
                    visible: card.flipAngle < 90

                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    Component.onCompleted: requestPaint()

                    function roundedRect(ctx, x, y, w, h, r) {
                        var radius = Math.min(r, w / 2, h / 2)
                        ctx.beginPath()
                        ctx.moveTo(x + radius, y)
                        ctx.lineTo(x + w - radius, y)
                        ctx.quadraticCurveTo(x + w, y, x + w, y + radius)
                        ctx.lineTo(x + w, y + h - radius)
                        ctx.quadraticCurveTo(x + w, y + h, x + w - radius, y + h)
                        ctx.lineTo(x + radius, y + h)
                        ctx.quadraticCurveTo(x, y + h, x, y + h - radius)
                        ctx.lineTo(x, y + radius)
                        ctx.quadraticCurveTo(x, y, x + radius, y)
                        ctx.closePath()
                    }

                    onPaint: {
                        if (width <= 0 || height <= 0)
                            return

                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        var w = width
                        var h = height
                        var pi2 = Math.PI * 2

                        // 圆角裁切
                        ctx.save()
                        roundedRect(ctx, 0.5, 0.5, w - 1, h - 1, 16)
                        ctx.clip()

                        // 纯白至蓝绿的对角微光
                        var base = ctx.createLinearGradient(0, 0, w, h)
                        base.addColorStop(0, "#FFFFFF")
                        base.addColorStop(0.55, "#F9FCFF")
                        base.addColorStop(1, "#EAF7F2")
                        ctx.fillStyle = base
                        ctx.fillRect(0, 0, w, h)

                        // 一道很淡的对角高光
                        var sheen = ctx.createLinearGradient(0, h, w, 0)
                        sheen.addColorStop(0, "rgba(255,255,255,0)")
                        sheen.addColorStop(0.44, "rgba(255,255,255,0.48)")
                        sheen.addColorStop(0.58, "rgba(255,255,255,0)")
                        sheen.addColorStop(1, "rgba(255,255,255,0)")
                        ctx.fillStyle = sheen
                        ctx.fillRect(0, 0, w, h)

                        var cx = w / 2
                        var cy = h / 2
                        var d = Math.min(w, h) * 0.19

                        // 极简几何：菱形 + 横线 + 微光点
                        ctx.strokeStyle = "rgba(59,139,246,0.28)"
                        ctx.lineWidth = 1.2
                        ctx.beginPath()
                        ctx.moveTo(cx, cy - d)
                        ctx.lineTo(cx + d * 0.72, cy)
                        ctx.lineTo(cx, cy + d)
                        ctx.lineTo(cx - d * 0.72, cy)
                        ctx.closePath()
                        ctx.stroke()

                        ctx.strokeStyle = "rgba(46,212,165,0.24)"
                        ctx.beginPath()
                        ctx.moveTo(cx - d * 0.50, cy)
                        ctx.lineTo(cx + d * 0.50, cy)
                        ctx.stroke()

                        ctx.strokeStyle = "rgba(46,212,165,0.16)"
                        ctx.lineWidth = 1
                        ctx.beginPath()
                        ctx.moveTo(w * 0.22, h * 0.76)
                        ctx.lineTo(w * 0.40, h * 0.58)
                        ctx.moveTo(w * 0.60, h * 0.42)
                        ctx.lineTo(w * 0.78, h * 0.24)
                        ctx.stroke()

                        ctx.beginPath()
                        ctx.arc(cx, cy, 2.6, 0, pi2)
                        ctx.fillStyle = "rgba(59,139,246,0.45)"
                        ctx.fill()

                        ctx.restore()

                        // 外边框
                        roundedRect(ctx, 0.5, 0.5, w - 1, h - 1, 16)
                        ctx.strokeStyle = "rgba(31,35,41,0.08)"
                        ctx.lineWidth = 1
                        ctx.stroke()
                    }
                }

                // ─────────────────────────────────────────────
                // 正面
                // ─────────────────────────────────────────────
                Rectangle {
                    id: frontFace
                    anchors.fill: parent
                    radius: 16
                    visible: card.flipAngle >= 90
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.textPrimary, 0.07)

                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Theme.surface }
                        GradientStop { position: 0.72; color: "#FBFEFC" }
                        GradientStop { position: 1.0; color: Theme.primarySoftGreen }
                    }

                    transform: Rotation {
                        axis.x: 0
                        axis.y: 1
                        axis.z: 0
                        angle: 180
                        origin.x: frontFace.width / 2
                        origin.y: frontFace.height / 2
                    }

                    Column {
                        width: Math.max(0, parent.width - 16)
                        anchors.centerIn: parent
                        spacing: 6

                        Item {
                            width: parent.width
                            height: 3

                            Rectangle {
                                width: 24
                                height: 3
                                radius: 1.5
                                anchors.centerIn: parent
                                gradient: Theme.primaryGradient
                            }
                        }

                        Text {
                            width: parent.width
                            text: "抽中"
                            horizontalAlignment: Text.AlignHCenter
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.letterSpacing: 2
                        }

                        Text {
                            width: parent.width
                            text: flipRoot.winnerName.length > 0
                                  ? flipRoot.winnerName
                                  : "幸运签"
                            horizontalAlignment: Text.AlignHCenter
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            function deal(order) {
                resetCard()
                dealPause.duration = order * 55
                dealSequence.start()
            }

            function resetCard() {
                if (dealSequence)
                    dealSequence.stop()
                card.flipAngle = 0
                card.lift = 0
                card.x = card.startX
                card.y = card.startY
            }

            SequentialAnimation {
                id: dealSequence

                PauseAnimation {
                    id: dealPause
                    duration: 0
                }

                PathAnimation {
                    id: dealPath
                    target: card
                    duration: 650
                    easing.type: Easing.OutCubic

                    path: Path {
                        startX: card.startX
                        startY: card.startY

                        PathCubic {
                            x: 0
                            y: 0
                            control1X: card.startX * 0.58
                            control1Y: card.startY * 0.10 - flipRoot.cardHeight * 0.18
                            control2X: -card.startX * 0.18
                            control2Y: card.startY * 0.44
                        }
                    }
                }
            }
        }
    }
}
