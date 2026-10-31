import QtQuick

import ".."

/*!
    现代盲盒抽签组件。
    - 3 个盲盒，蓝/薄荷绿低饱和渐变，全部使用 Rectangle + Gradient
    - 顶部独立盖子，可向上弹飞并旋转
    - 不使用红色，也没有传统印花
    - startOpen()：三个盒子轻微跳动 → 随机选中一个 → 盖子弹飞 → 内部强光 → 卷轴升起
    - 选中时发出 boxSelected()，可在此时写入 winnerName
    - 全部结束发出 finished()
*/
Item {
    id: blindRoot

    implicitWidth: 680
    implicitHeight: 380

    readonly property int boxCount: 3
    readonly property real boxWidth: Math.max(0, Math.min(width * 0.24, height * 0.40))
    readonly property real lidHeight: Math.max(0, boxWidth * 0.17)
    readonly property real bodyHeight: Math.max(0, boxWidth * 0.92)
    readonly property real bodyY: Math.max(0, lidHeight - 3)
    readonly property real boxHeight: bodyY + bodyHeight
    readonly property real boxSpacing: Math.max(0, boxWidth * 0.38)
    readonly property real totalWidth: boxCount * boxWidth + (boxCount - 1) * boxSpacing
    readonly property real startX: (width - totalWidth) / 2
    readonly property real baseY: (height - boxHeight) / 2

    readonly property bool running: (!!masterAnimation && masterAnimation.running) || openActive

    property string winnerName: ""
    property int selectedIndex: -1
    property bool openActive: false

    signal boxSelected()
    signal finished()

    function startOpen() {
        if (running)
            return

        reset()
        openActive = true

        for (var i = 0; i < boxRepeater.count; ++i) {
            var box = boxRepeater.itemAt(i)
            if (box)
                box.jump(i * 45)
        }

        masterAnimation.start()
    }

    function reset() {
        openActive = false
        selectedIndex = -1
        masterAnimation.stop()
        openConnections.target = null

        for (var i = 0; i < boxRepeater.count; ++i) {
            var box = boxRepeater.itemAt(i)
            if (box)
                box.resetBox()
        }
    }

    function selectRandomBox() {
        selectedIndex = Math.floor(Math.random() * boxCount)
    }

    function beginOpen() {
        var box = boxRepeater.itemAt(selectedIndex)
        if (!box) {
            openActive = false
            finished()
            return
        }

        openConnections.target = box
        box.openBox()
    }

    SequentialAnimation {
        id: masterAnimation

        PauseAnimation {
            duration: 720
        }

        ScriptAction {
            script: {
                blindRoot.selectRandomBox()
                blindRoot.boxSelected()
            }
        }

        PauseAnimation {
            duration: 260
        }

        ScriptAction {
            script: blindRoot.beginOpen()
        }
    }

    Connections {
        id: openConnections
        target: null
        ignoreUnknownSignals: true

        function onOpenFinished() {
            if (blindRoot.openActive) {
                blindRoot.openActive = false
                blindRoot.finished()
            }
        }
    }

    Repeater {
        id: boxRepeater
        model: blindRoot.boxCount

        delegate: Item {
            id: box

            readonly property bool selected: blindRoot.selectedIndex === index
            readonly property bool mint: index % 2 === 1

            property real bounce: 0
            property real lidOffset: 0
            property real lidRotation: 0
            property real lidOpacity: 1
            property real glowOpacity: 0
            property real scrollProgress: 0
            property real scrollOpacity: 0
            property bool opening: false

            signal openFinished()

            width: blindRoot.boxWidth
            height: blindRoot.boxHeight
            x: blindRoot.startX + index * (blindRoot.boxWidth + blindRoot.boxSpacing)
            y: blindRoot.baseY + (selected ? -10 : 0)
            z: selected ? 20 : 10 - Math.abs(index - 1)
            opacity: blindRoot.selectedIndex >= 0 && !selected ? 0.58 : 1.0
            scale: selected ? 1.04 : (blindRoot.selectedIndex >= 0 && !selected ? 0.97 : 1.0)

            transform: Translate {
                y: -box.bounce
            }

            Behavior on y {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }

            function jump(delay) {
                bounceSequence.stop()
                bouncePause.duration = delay
                bounceSequence.start()
            }

            function openBox() {
                if (opening)
                    return

                bounceSequence.stop()
                bounce = 0
                opening = true
                openSequence.start()
            }

            function resetBox() {
                opening = false
                bounceSequence.stop()
                openSequence.stop()

                bounce = 0
                lidOffset = 0
                lidRotation = 0
                lidOpacity = 1
                glowOpacity = 0
                scrollProgress = 0
                scrollOpacity = 0
            }

            // ─────────────────────────────────────────────────────
            // 地面投影
            // ─────────────────────────────────────────────────────
            Rectangle {
                x: (box.width - width) / 2
                y: blindRoot.bodyY + blindRoot.bodyHeight - 6
                width: box.width * 0.82
                height: 14
                radius: 7
                color: "#0A000000"
                z: 0
            }

            // ─────────────────────────────────────────────────────
            // 卷轴：位于盒身之后，升起时从盒口露出
            // ─────────────────────────────────────────────────────
            Rectangle {
                id: scroll

                width: box.width * 0.60
                height: blindRoot.boxWidth * 0.78
                x: (box.width - width) / 2
                y: blindRoot.bodyY + blindRoot.bodyHeight - height - box.scrollProgress * (blindRoot.bodyHeight * 0.95)
                z: 0.5
                opacity: box.scrollOpacity
                radius: 10
                border.width: 1
                border.color: Theme.withAlpha(Theme.textPrimary, 0.08)

                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: "#FFFEFA" }
                    GradientStop { position: 0.62; color: "#FFFFFF" }
                    GradientStop { position: 1.0; color: "#F2F9FF" }
                }

                // 卷轴上下卷边
                Rectangle {
                    x: -4
                    y: -5
                    width: parent.width + 8
                    height: 10
                    radius: 5
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.textPrimary, 0.07)
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#E6F0FB" }
                        GradientStop { position: 0.5; color: "#FFFFFF" }
                        GradientStop { position: 1.0; color: "#DDEEE7" }
                    }
                }

                Rectangle {
                    x: -4
                    y: parent.height - 8
                    width: parent.width + 8
                    height: 8
                    radius: 4
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.textPrimary, 0.07)
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#E6F0FB" }
                        GradientStop { position: 0.5; color: "#FFFFFF" }
                        GradientStop { position: 1.0; color: "#DDEEE7" }
                    }
                }

                Text {
                    width: Math.max(0, parent.width - 12)
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 18
                    text: "幸运签"
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 8
                    font.letterSpacing: 2
                }

                Text {
                    width: Math.max(0, parent.width - 10)
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 32
                    text: blindRoot.winnerName.length > 0
                          ? blindRoot.winnerName
                          : "幸运签"
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Rectangle {
                    width: 22
                    height: 2
                    radius: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 54
                    gradient: Theme.primaryGradient
                    opacity: 0.8
                }
            }

            // ─────────────────────────────────────────────────────
            // 盒身
            // ─────────────────────────────────────────────────────
            Item {
                id: body

                x: 0
                y: blindRoot.bodyY
                width: box.width
                height: blindRoot.bodyHeight
                z: 1

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusCard
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.white, 0.68)

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0.0
                            color: box.mint ? "#C6E5DA" : "#C9DFF8"
                        }
                        GradientStop {
                            position: 0.18
                            color: box.mint ? "#E2F6EF" : "#E8F3FF"
                        }
                        GradientStop {
                            position: 0.45
                            color: box.mint ? "#F8FEFB" : "#FBFDFF"
                        }
                        GradientStop {
                            position: 0.72
                            color: box.mint ? "#D4EFE5" : "#D9EAFC"
                        }
                        GradientStop {
                            position: 1.0
                            color: box.mint ? "#B7D9CB" : "#BCD6F3"
                        }
                    }
                }

                // 左侧竖向高光，模拟圆柱的立体感
                Rectangle {
                    x: 14
                    y: 16
                    width: box.width * 0.11
                    height: body.height - 32
                    radius: width / 2
                    opacity: 0.72

                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "#99FFFFFF" }
                        GradientStop { position: 0.55; color: "#4DFFFFFF" }
                        GradientStop { position: 1.0; color: "#00FFFFFF" }
                    }
                }

                // 底部轻压暗
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 28
                    radius: Theme.radiusCard
                    opacity: 0.55

                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "#00000000" }
                        GradientStop { position: 1.0; color: "#141F2329" }
                    }
                }

                // 蓝绿缎带
                Rectangle {
                    y: body.height * 0.40
                    width: body.width
                    height: 7
                    gradient: Theme.primaryGradient
                    opacity: 0.92
                }

                Rectangle {
                    y: body.height * 0.40
                    width: body.width
                    height: 1
                    color: Theme.withAlpha(Theme.white, 0.42)
                }

                // 正面印记：只保留“签”，不使用传统印花
                Rectangle {
                    width: Math.max(28, box.width * 0.27)
                    height: width
                    radius: width / 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: body.height * 0.58 - height / 2
                    color: "#D9FFFFFF"
                    border.width: 1
                    border.color: "#99FFFFFF"

                    Text {
                        anchors.centerIn: parent
                        text: "签"
                        color: Theme.primary
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.max(12, Math.round(parent.width * 0.40))
                        font.weight: Font.DemiBold
                    }
                }
            }

            // ─────────────────────────────────────────────────────
            // 盒口暗边：盖子飞走后露出
            // ─────────────────────────────────────────────────────
            Rectangle {
                x: body.x + body.width * 0.10
                y: body.y - 2
                width: body.width * 0.80
                height: 8
                radius: 4
                color: "#1A1F2329"
                opacity: 1.0 - box.lidOpacity
                z: 2.1

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 3
                    color: "#0D3B8BF6"
                }
            }

            // ─────────────────────────────────────────────────────
            // 内部强光
            // ─────────────────────────────────────────────────────
            Canvas {
                id: glow

                width: body.width * 1.35
                height: body.height * 0.95
                x: body.x + (body.width - width) / 2
                y: body.y - height * 0.42
                z: 2.4
                opacity: box.glowOpacity

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
                Component.onCompleted: requestPaint()

                onPaint: {
                    if (width <= 0 || height <= 0)
                        return

                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var cx = width / 2
                    var cy = height * 0.56
                    var pi2 = Math.PI * 2
                    var radius = Math.min(width, height) * 0.52

                    var light = ctx.createRadialGradient(cx, cy, 0, cx, cy, radius)
                    light.addColorStop(0, "rgba(255,255,255,0.92)")
                    light.addColorStop(0.18, "rgba(228,245,255,0.78)")
                    light.addColorStop(0.45, "rgba(120,200,255,0.28)")
                    light.addColorStop(0.78, "rgba(59,139,246,0.08)")
                    light.addColorStop(1, "rgba(59,139,246,0)")
                    ctx.fillStyle = light
                    ctx.beginPath()
                    ctx.arc(cx, cy, radius, 0, pi2)
                    ctx.fill()

                    var beam = ctx.createLinearGradient(cx, 0, cx, height)
                    beam.addColorStop(0, "rgba(255,255,255,0)")
                    beam.addColorStop(0.45, "rgba(255,255,255,0.28)")
                    beam.addColorStop(1, "rgba(255,255,255,0)")
                    ctx.fillStyle = beam
                    ctx.fillRect(cx - width * 0.10, 0, width * 0.20, height)
                }
            }

            // ─────────────────────────────────────────────────────
            // 独立盖子
            // ─────────────────────────────────────────────────────
            Item {
                id: lid

                width: box.width * 1.06
                height: blindRoot.lidHeight
                x: (box.width - width) / 2
                y: -box.lidOffset
                rotation: box.lidRotation
                opacity: box.lidOpacity
                transformOrigin: Item.Center
                z: 3

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.white, 0.80)

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0.0
                            color: box.mint ? "#E4F8F1" : "#E4F1FF"
                        }
                        GradientStop {
                            position: 0.45
                            color: "#FFFFFF"
                        }
                        GradientStop {
                            position: 1.0
                            color: box.mint ? "#CDEDE2" : "#D2E5FA"
                        }
                    }
                }

                Rectangle {
                    x: 8
                    y: 3
                    width: parent.width - 16
                    height: parent.height * 0.42
                    radius: height / 2
                    color: "#66FFFFFF"
                }

                Rectangle {
                    x: 8
                    anchors.bottom: parent.bottom
                    width: parent.width - 16
                    height: 1
                    color: "#141F2329"
                }
            }

            // 轻微跳动
            SequentialAnimation {
                id: bounceSequence

                PauseAnimation {
                    id: bouncePause
                    duration: 0
                }

                NumberAnimation {
                    target: box
                    property: "bounce"
                    to: 8
                    duration: 130
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: box
                    property: "bounce"
                    to: 0
                    duration: 150
                    easing.type: Easing.InCubic
                }

                NumberAnimation {
                    target: box
                    property: "bounce"
                    to: 5
                    duration: 100
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: box
                    property: "bounce"
                    to: 0
                    duration: 130
                    easing.type: Easing.InCubic
                }
            }

            // 盖子弹飞 → 强光 → 卷轴升起
            SequentialAnimation {
                id: openSequence

                ParallelAnimation {
                    NumberAnimation {
                        target: box
                        property: "lidOffset"
                        to: blindRoot.boxWidth * 0.95
                        duration: 480
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        target: box
                        property: "lidRotation"
                        to: 38
                        duration: 520
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        target: box
                        property: "lidOpacity"
                        to: 0
                        duration: 460
                        easing.type: Easing.InCubic
                    }

                    NumberAnimation {
                        target: box
                        property: "glowOpacity"
                        to: 1
                        duration: 280
                        easing.type: Easing.OutCubic
                    }
                }

                PauseAnimation {
                    duration: 70
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: box
                        property: "scrollProgress"
                        to: 1
                        duration: 650
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        target: box
                        property: "scrollOpacity"
                        to: 1
                        duration: 260
                        easing.type: Easing.OutCubic
                    }
                }

                PauseAnimation {
                    duration: 140
                }

                onStopped: {
                    if (box.opening) {
                        box.opening = false
                        box.openFinished()
                    }
                }
            }
        }
    }
}
