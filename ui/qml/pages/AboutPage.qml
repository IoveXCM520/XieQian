import QtQuick
import QtQuick.Controls

import ".."
import "../components"

/*!
    关于页。
    - 单张大圆角白卡：上半部分居中放图标与版本号
    - 下半部分克制地展示作者、联系方式、语录与诗句
*/
Item {
    id: page

    Item {
        id: pageContent
        anchors.fill: parent
        anchors.margins: Theme.pagePadding

        Item {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 64

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Text {
                    text: "关于"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontH0
                    font.weight: Font.Bold
                }

                Text {
                    text: "面向教育场景的离线抽奖系统"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }
        }

        CardShadowBehind {
            target: card
        }

        Rectangle {
            id: card

            anchors.top: header.bottom
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            radius: Theme.radiusCard
            color: Theme.surface
            border.width: 1
            border.color: Theme.withAlpha(Theme.textPrimary, 0.045)
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

                    var glow = ctx.createRadialGradient(width * 0.5, height * 0.14,
                                                        0, width * 0.5, height * 0.14,
                                                        Math.max(width, height) * 0.55)
                    glow.addColorStop(0, "rgba(59,139,246,0.055)")
                    glow.addColorStop(0.55, "rgba(46,212,165,0.02)")
                    glow.addColorStop(1, "rgba(59,139,246,0)")
                    ctx.fillStyle = glow
                    ctx.fillRect(0, 0, width, height)
                }
            }

            Flickable {
                id: aboutFlick

                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: aboutColumn.height + 96
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AlwaysOff
                }

                Column {
                    id: aboutColumn

                    width: Math.min(520, card.width - 96)
                    x: (aboutFlick.width - width) / 2
                    y: 48
                    spacing: 0

                    // ── 品牌区 ──
                    Item {
                        width: parent.width
                        height: 96

                        Image {
                            anchors.centerIn: parent
                            width: 96
                            height: 96
                            source: "qrc:/ui/assets/app-icon-512.png"
                            sourceSize.width: 512
                            sourceSize.height: 512
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                        }
                    }

                    Item { width: 1; height: 20 }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "撷签"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 30
                        font.weight: Font.Bold
                        font.letterSpacing: 4
                    }

                    Item { width: 1; height: 6 }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "XIE QIAN"
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.letterSpacing: 5
                    }

                    Item { width: 1; height: 18 }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: versionText.implicitWidth + 26
                        height: 28
                        radius: 14
                        color: Theme.surfaceAlt
                        border.width: 1
                        border.color: Theme.withAlpha(Theme.textPrimary, 0.05)

                        Text {
                            id: versionText
                            anchors.centerIn: parent
                            text: "v1.0.8.5"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontMicro
                            font.letterSpacing: 1
                        }
                    }

                    Item { width: 1; height: 14 }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "妙择一签，落定心安"
                        color: Theme.primary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        font.letterSpacing: 2
                    }

                    Item { width: 1; height: 30 }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.withAlpha(Theme.textPrimary, 0.06)
                    }

                    Item { width: 1; height: 26 }

                    // ── 信息区 ──
                    Row {
                        width: parent.width
                        spacing: 16

                        Text {
                            width: 64
                            anchors.verticalCenter: parent.verticalCenter
                            text: "作者"
                            color: Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                            font.letterSpacing: 2
                        }

                        Text {
                            text: "汐辞梦"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontH2
                            font.weight: Font.DemiBold
                        }
                    }

                    Item { width: 1; height: 16 }

                    Row {
                        width: parent.width
                        spacing: 16

                        Text {
                            width: 64
                            anchors.verticalCenter: parent.verticalCenter
                            text: "QQ"
                            color: Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                            font.letterSpacing: 2
                        }

                        Text {
                            text: "2995723028"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.letterSpacing: 1
                        }
                    }

                    Item { width: 1; height: 22 }

                    // ── 语录与诗句 ──
                    Text {
                        width: 64
                        text: "语录"
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontCaption
                        font.letterSpacing: 2
                    }

                    Item { width: 1; height: 8 }

                    Text {
                        width: parent.width
                        text: "Misty Arcane Dreamy Ethereal Radiant Omen Xenon Cipher Muse"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        font.letterSpacing: 0.6
                        wrapMode: Text.WordWrap
                        lineHeight: 1.4
                    }

                    Item { width: 1; height: 20 }

                    Text {
                        width: parent.width
                        text: "「远潮藏诗，魅影托梦」"
                        color: Theme.primary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontH2
                        font.letterSpacing: 2
                    }

                    Item { width: 1; height: 30 }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.withAlpha(Theme.textPrimary, 0.06)
                    }

                    Item { width: 1; height: 16 }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "MIT License · 2026"
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontMicro
                        font.letterSpacing: 1
                    }

                    Item { width: 1; height: 32 }
                }
            }
        }
    }
}
