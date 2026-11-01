import QtQuick

import ".."
import "../components"

/*!
    关于页。
    - 品牌图标 + 名称 + 版本 + 开源协议
    - 作者信息卡片
    - 与其他页面一致的白卡与标题层级
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
            height: 336
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

                    var glow = ctx.createRadialGradient(width * 0.5, height * 0.42,
                                                        0, width * 0.5, height * 0.42,
                                                        Math.max(width, height) * 0.42)
                    glow.addColorStop(0, "rgba(59,139,246,0.055)")
                    glow.addColorStop(0.55, "rgba(46,212,165,0.022)")
                    glow.addColorStop(1, "rgba(59,139,246,0)")
                    ctx.fillStyle = glow
                    ctx.fillRect(0, 0, width, height)
                }
            }

            Column {
                anchors.centerIn: parent
                width: Math.min(520, card.width - 64)
                spacing: 0

                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 108
                    height: 108
                    source: "qrc:/ui/assets/app-icon-512.png"
                    sourceSize.width: 512
                    sourceSize.height: 512
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }

                Item { width: 1; height: 18 }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "撷签 · XieQian"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 30
                    font.weight: Font.Bold
                    font.letterSpacing: 2
                }

                Item { width: 1; height: 12 }

                Rectangle {
                    width: 56
                    height: 3
                    radius: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    gradient: Theme.primaryGradient
                }

                Item { width: 1; height: 18 }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "v1.0.8 (Build 2026)"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    font.letterSpacing: 1
                }

                Item { width: 1; height: 10 }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "妙择一签，落定心安"
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontH2
                    font.letterSpacing: 2
                }

                Item { width: 1; height: 22 }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.divider
                }

                Item { width: 1; height: 16 }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "开源协议：MIT License"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                    font.letterSpacing: 1
                }
            }
        }

        CardShadowBehind {
            target: authorCard
        }

        Rectangle {
            id: authorCard

            anchors.top: card.bottom
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            radius: Theme.radiusCard
            color: Theme.surface
            border.width: 1
            border.color: Theme.withAlpha(Theme.textPrimary, 0.045)

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 28
                anchors.rightMargin: 28
                spacing: 8

                Row {
                    spacing: 10

                    Rectangle {
                        width: 3
                        height: 16
                        radius: 1.5
                        anchors.verticalCenter: parent.verticalCenter
                        gradient: Theme.primaryGradient
                    }

                    Text {
                        text: "作者"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontCaption
                        font.letterSpacing: 2
                    }

                    Text {
                        text: "汐辞梦"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontH2
                        font.weight: Font.Bold
                        font.letterSpacing: 1
                    }
                }

                Text {
                    text: "QQ 2995723028"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                    font.letterSpacing: 1
                }

                Text {
                    width: parent.width
                    text: "Misty Arcane Dreamy Ethereal Radiant Omen Xenon Cipher Muse"
                    color: Theme.primary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                    font.letterSpacing: 1
                    elide: Text.ElideRight
                }

                Text {
                    text: "「远潮藏诗，魅影托梦」"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    font.letterSpacing: 1
                }
            }
        }
    }
}
