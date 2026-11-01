import QtQuick
import QtQuick.Controls

import ".."

/*!
    关于页。
    - 白底海报：卡片铺满整个右侧内容区，不再有页头
    - 大面积留白，Logo、作者与诗句居中排布
*/
Item {
    id: page

    Rectangle {
        id: poster

        anchors.fill: parent
        radius: 0
        color: Theme.surface
        clip: true

        Canvas {
            anchors.fill: parent
            opacity: 0.9
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()

            onPaint: {
                if (width <= 0 || height <= 0)
                    return

                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var glow = ctx.createRadialGradient(width * 0.5, height * 0.3,
                                                    0, width * 0.5, height * 0.3,
                                                    Math.max(width, height) * 0.62)
                glow.addColorStop(0, "rgba(59,139,246,0.05)")
                glow.addColorStop(0.55, "rgba(46,212,165,0.018)")
                glow.addColorStop(1, "rgba(59,139,246,0)")
                ctx.fillStyle = glow
                ctx.fillRect(0, 0, width, height)
            }
        }

        Flickable {
            id: posterFlick

            anchors.fill: parent
            clip: true
            contentWidth: width
            contentHeight: Math.max(posterFlick.height, posterColumn.height + 120)
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOff
            }

            Column {
                id: posterColumn

                width: Math.min(560, posterFlick.width - 96)
                x: (posterFlick.width - width) / 2
                y: Math.max(48, (posterFlick.height - height) / 2)
                spacing: 0

                Item {
                    width: parent.width
                    height: 132

                    Image {
                        anchors.centerIn: parent
                        width: 128
                        height: 128
                        source: "qrc:/ui/assets/app-icon-512.png"
                        sourceSize.width: 512
                        sourceSize.height: 512
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        mipmap: true
                    }
                }

                Item { width: 1; height: 26 }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "撷签"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 34
                    font.weight: Font.Bold
                    font.letterSpacing: 6
                }

                Item { width: 1; height: 8 }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "XIE QIAN"
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.letterSpacing: 6
                }

                Item { width: 1; height: 20 }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: versionText.implicitWidth + 28
                    height: 28
                    radius: 14
                    color: Theme.surfaceAlt
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.textPrimary, 0.05)

                    Text {
                        id: versionText
                        anchors.centerIn: parent
                        text: "v1.0.9"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontMicro
                        font.letterSpacing: 1
                    }
                }

                Item { width: 1; height: 64 }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "作者"
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                    font.letterSpacing: 4
                }

                Item { width: 1; height: 10 }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "汐辞梦"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 24
                    font.weight: Font.DemiBold
                    font.letterSpacing: 4
                }

                Item { width: 1; height: 8 }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "QQ 2995723028"
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontMicro
                    font.letterSpacing: 1
                }

                Item { width: 1; height: 56 }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "「远潮藏诗，魅影托梦」"
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: 22
                    font.letterSpacing: 3
                }

                Item { width: 1; height: 14 }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "妙择一签，落定心安"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    font.letterSpacing: 3
                }

                Item { width: 1; height: 72 }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "MIT License · 2026"
                    color: Theme.withAlpha(Theme.textTertiary, 0.8)
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.letterSpacing: 1
                }
            }
        }
    }
}
