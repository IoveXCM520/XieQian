import QtQuick
import QtQuick.Effects

import ".."

/*!
    现代化极简转盘。
    - 8 个低饱和扇区，按 A/B/C/D 交替
    - 中心轴为品牌渐变圆盘
    - 外圈渐变发光环
    - 顶部水滴形指针
    - startSpin()：2.5s OutQuint 旋转，结束后发出 finished()
*/
Item {
    id: wheelRoot

    implicitWidth: 420
    implicitHeight: 420

    property real angle: 0
    property bool spinActive: false
    property bool showPointer: true
    readonly property bool spinning: spinAnimation.running

    signal finished()

    function startSpin() {
        if (spinAnimation.running)
            return

        spinActive = true
        spinAnimation.from = angle
        spinAnimation.to = angle + 1440 + Math.floor(Math.random() * 8) * 45
        spinAnimation.start()
    }

    RotationAnimation {
        id: spinAnimation

        target: wheelRoot
        property: "angle"
        duration: 2500
        direction: RotationAnimation.Numerical
        easing.type: Easing.OutQuint

        onStopped: {
            if (wheelRoot.spinActive) {
                wheelRoot.spinActive = false
                wheelRoot.finished()
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 外圈：微弱发光 + 渐变描边
    // ─────────────────────────────────────────────────────────────
    Canvas {
        id: ringCanvas
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
            var radius = Math.min(width, height) / 2 - 10
            var pi2 = Math.PI * 2

            if (radius <= 0)
                return

            // 外圈柔光
            var halo = ctx.createRadialGradient(cx, cy, Math.max(0, radius - 18),
                                                cx, cy, radius + 10)
            halo.addColorStop(0, "rgba(59,139,246,0)")
            halo.addColorStop(0.55, "rgba(59,139,246,0.085)")
            halo.addColorStop(0.82, "rgba(46,212,165,0.070)")
            halo.addColorStop(1, "rgba(46,212,165,0)")
            ctx.fillStyle = halo
            ctx.beginPath()
            ctx.arc(cx, cy, radius + 10, 0, pi2)
            ctx.fill()

            // 渐变主环
            var ring = ctx.createLinearGradient(cx - radius, cy - radius,
                                                cx + radius, cy + radius)
            ring.addColorStop(0, String(Theme.primary))
            ring.addColorStop(1, String(Theme.primaryEnd))

            ctx.strokeStyle = ring
            ctx.lineWidth = Math.max(4, radius * 0.030)
            ctx.shadowColor = "rgba(59,139,246,0.30)"
            ctx.shadowBlur = 14
            ctx.shadowOffsetX = 0
            ctx.shadowOffsetY = 0
            ctx.beginPath()
            ctx.arc(cx, cy, radius, 0, pi2)
            ctx.stroke()

            ctx.shadowBlur = 0
            ctx.shadowColor = "transparent"

            // 环内/环外各一条极细高光，增加精致度
            ctx.strokeStyle = "rgba(255,255,255,0.85)"
            ctx.lineWidth = 1
            ctx.beginPath()
            ctx.arc(cx, cy, radius - 5, 0, pi2)
            ctx.stroke()

            ctx.strokeStyle = "rgba(255,255,255,0.55)"
            ctx.beginPath()
            ctx.arc(cx, cy, radius + 5, 0, pi2)
            ctx.stroke()
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 旋转盘面：8 个扁平扇区
    // ─────────────────────────────────────────────────────────────
    Item {
        id: disc
        anchors.fill: parent
        anchors.margins: 26
        rotation: wheelRoot.angle
        transformOrigin: Item.Center
        z: 1

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
                var radius = Math.min(width, height) / 2
                var pi2 = Math.PI * 2
                var sectors = 8
                var step = pi2 / sectors
                var start = -Math.PI / 2

                var colors = [
                    String(Theme.wheelSectorA),
                    String(Theme.wheelSectorB),
                    String(Theme.wheelSectorC),
                    String(Theme.wheelSectorD)
                ]

                for (var i = 0; i < sectors; ++i) {
                    ctx.beginPath()
                    ctx.moveTo(cx, cy)
                    ctx.arc(cx, cy, radius,
                            start + i * step,
                            start + (i + 1) * step)
                    ctx.closePath()

                    ctx.fillStyle = colors[i % colors.length]
                    ctx.fill()

                    ctx.strokeStyle = String(Theme.surface)
                    ctx.lineWidth = Math.max(2, radius * 0.015)
                    ctx.stroke()
                }

                // 盘面中心的一层极淡白色柔光，避免大面积纯色发闷
                var gloss = ctx.createRadialGradient(cx, cy, 0, cx, cy, radius)
                gloss.addColorStop(0, "rgba(255,255,255,0.11)")
                gloss.addColorStop(0.45, "rgba(255,255,255,0.035)")
                gloss.addColorStop(1, "rgba(255,255,255,0)")
                ctx.fillStyle = gloss
                ctx.beginPath()
                ctx.arc(cx, cy, radius, 0, pi2)
                ctx.fill()

                // 内圈细白边
                ctx.strokeStyle = "rgba(255,255,255,0.65)"
                ctx.lineWidth = 1
                ctx.beginPath()
                ctx.arc(cx, cy, radius - 1, 0, pi2)
                ctx.stroke()
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 中心轴：品牌渐变 + 签
    // ─────────────────────────────────────────────────────────────
    Item {
        id: hub

        width: Math.max(56, Math.min(wheelRoot.width, wheelRoot.height) * 0.235)
        height: width
        anchors.centerIn: parent
        z: 5

        Rectangle {
            id: hubPlate
            anchors.fill: parent
            radius: width / 2
            color: Theme.surface
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.shadowColorStrong
                shadowBlur: 0.55
                shadowVerticalOffset: 4
                shadowHorizontalOffset: 0
                autoPaddingEnabled: true
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 5
            radius: width / 2
            gradient: Theme.primaryGradient
            border.width: 1
            border.color: Theme.withAlpha(Theme.white, 0.35)
        }

        Text {
            anchors.centerIn: parent
            text: "签"
            color: Theme.white
            font.family: Theme.fontFamily
            font.pixelSize: Math.max(18, Math.round(hub.width * 0.30))
            font.weight: Font.Bold
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 顶部水滴指针
    // ─────────────────────────────────────────────────────────────
    Item {
        id: pointer
        width: Math.max(26, wheelRoot.width * 0.085)
        height: width * 1.42
        anchors.horizontalCenter: parent.horizontalCenter
        y: -2
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

                var cx = width / 2
                var radius = width * 0.44
                var topY = radius + 2
                var tipY = height - 4
                var pi2 = Math.PI * 2

                var fill = ctx.createLinearGradient(cx, 0, cx, height)
                fill.addColorStop(0, String(Theme.primary))
                fill.addColorStop(1, String(Theme.primaryEnd))

                ctx.fillStyle = fill
                ctx.shadowColor = "rgba(31,35,41,0.18)"
                ctx.shadowBlur = 10
                ctx.shadowOffsetX = 0
                ctx.shadowOffsetY = 4

                ctx.beginPath()
                ctx.moveTo(cx, tipY)
                ctx.bezierCurveTo(cx - width * 0.10, height * 0.62,
                                  cx - radius, height * 0.48,
                                  cx - radius, topY)
                ctx.arc(cx, topY, radius, Math.PI, 0)
                ctx.bezierCurveTo(cx + radius, height * 0.48,
                                  cx + width * 0.10, height * 0.62,
                                  cx, tipY)
                ctx.closePath()
                ctx.fill()

                ctx.shadowBlur = 0
                ctx.shadowColor = "transparent"

                ctx.strokeStyle = "rgba(255,255,255,0.55)"
                ctx.lineWidth = 1
                ctx.stroke()

                // 水滴高光
                ctx.beginPath()
                ctx.arc(cx - width * 0.08, topY - radius * 0.22,
                        width * 0.085, 0, pi2)
                ctx.fillStyle = "rgba(255,255,255,0.78)"
                ctx.fill()
            }
        }
    }
}
