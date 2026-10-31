import QtQuick

import ".."

/*!
    实心多彩大转盘。
    - 高饱和现代色盘，Canvas ctx.fill() 绘制实心扇形 + 白色分割线
    - 选项文字沿半径向外放射，纯白 14px 加粗 + 深色阴影
    - 纯白中心轴，带微弱内阴影与灰色“签”字
    - 白色立体外圈（带阴影与内倒角）
    - 顶部白色水滴指针
    - startSpin()：3 秒 OutQuart 旋转，结束后发出 finished()
*/
Item {
    id: wheelRoot

    implicitWidth: 420
    implicitHeight: 420

    // 转盘选项；为空时使用内置的“签运”文案，保证独立预览也有内容
    property var options: []
    property real angle: 0
    property bool spinActive: false
    property bool showPointer: true

    readonly property bool spinning: spinAnimation.running

    // 几何尺寸全部按实际宽高推导，缩放时保持比例
    readonly property real diameter: Math.min(width, height)
    readonly property real outerMargin: Math.max(18, diameter * 0.050)
    readonly property real ringWidth: Math.max(10, diameter * 0.026)
    readonly property real discRadius: Math.max(0, diameter / 2 - outerMargin - ringWidth)
    readonly property real hubSize: Math.max(64, diameter * 0.230)
    readonly property real pointerWidth: Math.max(30, diameter * 0.076)
    readonly property real pointerHeight: pointerWidth * 1.36
    readonly property real pointerPadding: Math.max(16, pointerWidth * 0.55)

    signal finished()

    function effectiveCount() {
        if (!options || options.length === 0)
            return 8
        return Math.max(1, options.length)
    }

    function startSpin() {
        if (spinAnimation.running)
            return

        // 落点对齐到扇区中心：既让指针不压在分割线上，
        // 也保证停止后文字保持设计时的放射朝向。
        var count = effectiveCount()
        var stepDegrees = 360 / count
        var target = Math.floor(Math.random() * count)

        spinActive = true
        spinAnimation.from = angle
        spinAnimation.to = angle + 1440 + target * stepDegrees
        spinAnimation.start()
    }

    onOptionsChanged: {
        if (sectorCanvas)
            sectorCanvas.requestPaint()
    }

    RotationAnimation {
        id: spinAnimation

        target: wheelRoot
        property: "angle"
        duration: 3000
        direction: RotationAnimation.Numerical
        easing.type: Easing.OutQuart

        onStopped: {
            if (!wheelRoot.spinActive)
                return

            wheelRoot.spinActive = false
            wheelRoot.finished()
        }
    }

    // ═════════════════════════════════════════════════════════════
    // 旋转盘面：实心扇形 + 放射文字
    // ═════════════════════════════════════════════════════════════
    Item {
        id: disc

        anchors.fill: parent
        rotation: wheelRoot.angle
        transformOrigin: Item.Center

        Canvas {
            id: sectorCanvas

            anchors.fill: parent

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()

            onPaint: {
                if (width <= 0 || height <= 0)
                    return

                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var cx = width / 2
                var cy = height / 2
                var radius = wheelRoot.discRadius
                if (radius <= 0)
                    return

                var labels = wheelRoot.options
                if (!labels || labels.length === 0)
                    labels = ["上上签", "好运", "如愿", "惊喜", "欢喜", "顺遂", "圆满", "相逢"]

                var count = labels.length
                var step = Math.PI * 2 / count
                var start = -Math.PI / 2 - step / 2
                var pi2 = Math.PI * 2

                // 高饱和、冷暖交替的现代色盘
                var palette = [
                    "#FF4D6D",
                    "#FF8A00",
                    "#F4B400",
                    "#37D67A",
                    "#00C2A8",
                    "#2F80FF",
                    "#7B61FF",
                    "#E84DFF",
                    "#FF5E9C",
                    "#00B8D9"
                ]

                // 1. 实心扇形
                var separator = Math.max(2, radius * 0.012)

                for (var i = 0; i < count; ++i) {
                    var a0 = start + i * step
                    var a1 = a0 + step

                    ctx.beginPath()
                    ctx.moveTo(cx, cy)
                    ctx.arc(cx, cy, radius, a0, a1)
                    ctx.closePath()
                    ctx.fillStyle = palette[i % palette.length]
                    ctx.fill()

                    ctx.strokeStyle = "rgba(255,255,255,0.94)"
                    ctx.lineWidth = separator
                    ctx.stroke()
                }

                // 2. 顶层玻璃高光，保留色彩饱和度
                var sheen = ctx.createLinearGradient(cx - radius, cy - radius,
                                                     cx + radius, cy + radius)
                sheen.addColorStop(0.0, "rgba(255,255,255,0.16)")
                sheen.addColorStop(0.42, "rgba(255,255,255,0.035)")
                sheen.addColorStop(0.72, "rgba(0,0,0,0.025)")
                sheen.addColorStop(1.0, "rgba(0,0,0,0.085)")

                ctx.beginPath()
                ctx.arc(cx, cy, radius, 0, pi2)
                ctx.fillStyle = sheen
                ctx.fill()

                // 3. 盘面边缘的轻微暗角，让外圈更有嵌入感
                var vignette = ctx.createRadialGradient(cx, cy, radius * 0.76,
                                                        cx, cy, radius)
                vignette.addColorStop(0.0, "rgba(0,0,0,0)")
                vignette.addColorStop(1.0, "rgba(0,0,0,0.10)")

                ctx.beginPath()
                ctx.arc(cx, cy, radius, 0, pi2)
                ctx.fillStyle = vignette
                ctx.fill()

                // 4. 放射文字：白色 14px 加粗 + 深色阴影
                // 使用通用 sans-serif，避免 Canvas 字体库找不到品牌字体时回退成默认 10px
                ctx.font = "bold 14px sans-serif"

                for (var j = 0; j < count; ++j) {
                    var mid = start + (j + 0.5) * step
                    var flipped = mid > Math.PI / 2 && mid < Math.PI * 1.5

                    ctx.save()
                    ctx.translate(cx, cy)
                    ctx.rotate(mid)
                    ctx.translate(radius * 0.66, 0)

                    // 左半圈翻转 180°，避免文字完全倒置
                    if (flipped)
                        ctx.rotate(Math.PI)

                    ctx.textAlign = "center"
                    ctx.textBaseline = "middle"
                    ctx.fillStyle = "#FFFFFF"
                    ctx.shadowColor = "rgba(15,23,42,0.58)"
                    ctx.shadowBlur = 3
                    ctx.shadowOffsetX = 0
                    ctx.shadowOffsetY = flipped ? -1.4 : 1.4

                    var text = String(labels[j])
                    var maxWidth = radius * 0.50
                    if (ctx.measureText(text).width > maxWidth) {
                        var clipped = text
                        while (clipped.length > 1
                               && ctx.measureText(clipped + "…").width > maxWidth)
                            clipped = clipped.substring(0, clipped.length - 1)
                        text = clipped + "…"
                    }

                    ctx.fillText(text, 0, 0)
                    ctx.restore()
                }
            }
        }
    }

    // ═════════════════════════════════════════════════════════════
    // 白色外圈：立体阴影 + 内倒角
    // ═════════════════════════════════════════════════════════════
    Canvas {
        id: ringCanvas

        anchors.fill: parent
        z: 3

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            if (width <= 0 || height <= 0)
                return

            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var cx = width / 2
            var cy = height / 2
            var radius = wheelRoot.discRadius
            var ring = wheelRoot.ringWidth
            if (radius <= 0 || ring <= 0)
                return

            var ringRadius = radius + ring / 2
            var pi2 = Math.PI * 2

            // 外圈投影：先画一层带阴影的白环
            ctx.save()
            ctx.beginPath()
            ctx.arc(cx, cy, ringRadius, 0, pi2)
            ctx.lineWidth = ring
            ctx.strokeStyle = "#FFFFFF"
            ctx.shadowColor = "rgba(17,24,39,0.22)"
            ctx.shadowBlur = Math.max(10, ring * 1.8)
            ctx.shadowOffsetX = 0
            ctx.shadowOffsetY = Math.max(3, ring * 0.35)
            ctx.stroke()
            ctx.restore()

            // 纯白立体环
            var ringGradient = ctx.createLinearGradient(cx, cy - ringRadius,
                                                        cx, cy + ringRadius)
            ringGradient.addColorStop(0.0, "#FFFFFF")
            ringGradient.addColorStop(0.55, "#FFFFFF")
            ringGradient.addColorStop(1.0, "#F2F5FA")

            ctx.beginPath()
            ctx.arc(cx, cy, ringRadius, 0, pi2)
            ctx.lineWidth = ring
            ctx.strokeStyle = ringGradient
            ctx.stroke()

            // 最外缘细灰边，让白环在白底上也能被看见
            ctx.beginPath()
            ctx.arc(cx, cy, radius + ring + 0.5, 0, pi2)
            ctx.lineWidth = 1.5
            ctx.strokeStyle = "rgba(17,24,39,0.16)"
            ctx.stroke()

            // 内倒角：一圈高光 + 一圈极淡内阴影
            ctx.beginPath()
            ctx.arc(cx, cy, radius - 0.75, 0, pi2)
            ctx.lineWidth = 2
            ctx.strokeStyle = "rgba(255,255,255,0.88)"
            ctx.stroke()

            ctx.beginPath()
            ctx.arc(cx, cy, radius - 3.5, 0, pi2)
            ctx.lineWidth = 3
            ctx.strokeStyle = "rgba(17,24,39,0.08)"
            ctx.stroke()
        }
    }

    // ═════════════════════════════════════════════════════════════
    // 中心轴：纯白圆盘 + 微弱内阴影 + 灰色“签”
    // ═════════════════════════════════════════════════════════════
    Item {
        id: hub

        width: wheelRoot.hubSize
        height: width
        anchors.centerIn: parent
        z: 5

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "#FFFFFF"
            border.width: 1
            border.color: Theme.withAlpha(Theme.textPrimary, 0.08)
        }

        Canvas {
            id: hubInnerShadow

            anchors.fill: parent

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                var cx = width / 2
                var cy = height / 2
                var radius = Math.min(width, height) / 2 - 1
                if (radius <= 0)
                    return

                ctx.clearRect(0, 0, width, height)
                var inner = ctx.createRadialGradient(cx, cy, radius * 0.56,
                                                     cx, cy, radius)
                inner.addColorStop(0.0, "rgba(15,23,42,0)")
                inner.addColorStop(0.76, "rgba(15,23,42,0.02)")
                inner.addColorStop(1.0, "rgba(15,23,42,0.13)")

                ctx.beginPath()
                ctx.arc(cx, cy, radius, 0, Math.PI * 2)
                ctx.fillStyle = inner
                ctx.fill()
            }
        }

        Text {
            anchors.centerIn: parent
            text: "签"
            color: "#8C96A8"
            font.family: Theme.fontFamily
            font.pixelSize: Math.max(22, Math.round(hub.width * 0.30))
            font.weight: Font.Bold
        }
    }

    // ═════════════════════════════════════════════════════════════
    // 顶部指针：白色水滴形，尖端指向圆心
    // ═════════════════════════════════════════════════════════════
    Item {
        id: pointer

        width: wheelRoot.pointerWidth + wheelRoot.pointerPadding * 2
        height: wheelRoot.pointerHeight + wheelRoot.pointerPadding * 2
        anchors.horizontalCenter: parent.horizontalCenter
        y: wheelRoot.outerMargin - wheelRoot.pointerPadding - 10
        z: 10
        visible: wheelRoot.showPointer

        Canvas {
            anchors.fill: parent

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()

            onPaint: {
                if (width <= 0 || height <= 0)
                    return

                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                // 四周留出阴影淡出空间，避免 Canvas 边界切出矩形灰边
                var pad = wheelRoot.pointerPadding
                var shapeWidth = width - pad * 2
                var shapeHeight = height - pad * 2
                var cx = width / 2
                var radius = shapeWidth * 0.42
                var topY = pad + radius + 2
                var tipY = height - pad - 3
                var pi2 = Math.PI * 2

                var fill = ctx.createLinearGradient(0, pad, 0, height - pad)
                fill.addColorStop(0.0, "#FFFFFF")
                fill.addColorStop(0.58, "#FBFCFE")
                fill.addColorStop(1.0, "#EEF2F8")

                // 白色水滴 + 立体投影
                ctx.save()
                ctx.shadowColor = "rgba(17,24,39,0.28)"
                ctx.shadowBlur = Math.max(8, shapeWidth * 0.30)
                ctx.shadowOffsetX = 0
                ctx.shadowOffsetY = Math.max(3, shapeWidth * 0.10)
                ctx.fillStyle = fill

                ctx.beginPath()
                ctx.moveTo(cx, tipY)
                ctx.bezierCurveTo(cx - shapeWidth * 0.10, pad + shapeHeight * 0.62,
                                  cx - radius, pad + shapeHeight * 0.48,
                                  cx - radius, topY)
                ctx.arc(cx, topY, radius, Math.PI, 0)
                ctx.bezierCurveTo(cx + radius, pad + shapeHeight * 0.48,
                                  cx + shapeWidth * 0.10, pad + shapeHeight * 0.62,
                                  cx, tipY)
                ctx.closePath()
                ctx.fill()
                ctx.restore()

                // 细灰边，避免白色指针在白色卡片上消失
                ctx.strokeStyle = "rgba(17,24,39,0.14)"
                ctx.lineWidth = 1.2
                ctx.stroke()

                // 顶部高光
                ctx.beginPath()
                ctx.arc(cx - radius * 0.24, topY - radius * 0.18,
                        radius * 0.20, 0, pi2)
                ctx.fillStyle = "rgba(255,255,255,0.95)"
                ctx.fill()
            }
        }
    }
}
