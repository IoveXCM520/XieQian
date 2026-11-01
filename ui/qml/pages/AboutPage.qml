import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import ".."

/*!
    关于页。
    - 左右分栏：左侧 40% 放品牌，右侧 60% 放作者、联系方式、语录与诗句
    - 每条信息之间用细分隔线隔开
*/
Item {
    id: page

    anchors.fill: parent

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

                var glow = ctx.createRadialGradient(width * 0.24, height * 0.34,
                                                    0, width * 0.24, height * 0.34,
                                                    Math.max(width, height) * 0.6)
                glow.addColorStop(0, "rgba(59,139,246,0.055)")
                glow.addColorStop(0.55, "rgba(46,212,165,0.02)")
                glow.addColorStop(1, "rgba(59,139,246,0)")
                ctx.fillStyle = glow
                ctx.fillRect(0, 0, width, height)
            }
        }

        RowLayout {
            id: columns

            anchors.fill: parent
            spacing: 0

            // ── 左栏：品牌 ──
            Item {
                Layout.preferredWidth: parent.width * 0.4
                Layout.fillHeight: true

                Column {
                    anchors.centerIn: parent
                    width: Math.min(320, parent.width - 48)
                    spacing: 0

                    Item {
                        width: parent.width
                        height: 124

                        Image {
                            anchors.centerIn: parent
                            width: 112
                            height: 112
                            source: "qrc:/ui/assets/app-icon-512.png"
                            sourceSize.width: 512
                            sourceSize.height: 512
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                        }
                    }

                    Item { width: 1; height: 22 }

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

                    Item { width: 1; height: 18 }

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
                            text: "v1.0.9.9"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontMicro
                            font.letterSpacing: 1
                        }
                    }
                }
            }

            // ── 竖直分隔线 ──
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: parent.height * 0.62
                Layout.alignment: Qt.AlignVCenter
                color: Theme.withAlpha(Theme.textPrimary, 0.07)
            }

            // ── 右栏：信息 ──
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Flickable {
                    id: infoFlick

                    anchors.fill: parent
                    anchors.leftMargin: 48
                    anchors.rightMargin: 48
                    clip: true
                    contentWidth: width
                    contentHeight: Math.max(infoFlick.height, infoColumn.height)
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AlwaysOff
                    }

                    Column {
                        id: infoColumn

                        width: Math.min(460, infoFlick.width)
                        x: Math.max(0, (infoFlick.width - width) / 2)
                        y: Math.max(0, (infoFlick.height - height) / 2)
                        spacing: 0

                        Text {
                            width: parent.width
                            text: "作者"
                            color: Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                            font.letterSpacing: 3
                        }

                        Item { width: 1; height: 8 }

                        Text {
                            width: parent.width
                            text: "汐辞梦"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                            font.letterSpacing: 2
                        }

                        Item { width: 1; height: 20 }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.withAlpha(Theme.textPrimary, 0.07)
                        }

                        Item { width: 1; height: 20 }

                        Text {
                            width: parent.width
                            text: "QQ"
                            color: Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                            font.letterSpacing: 3
                        }

                        Item { width: 1; height: 8 }

                        Text {
                            width: parent.width
                            text: "2995723028"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.letterSpacing: 1
                        }

                        Item { width: 1; height: 20 }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.withAlpha(Theme.textPrimary, 0.07)
                        }

                        Item { width: 1; height: 20 }

                        Text {
                            width: parent.width
                            text: "语录"
                            color: Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                            font.letterSpacing: 3
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

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.withAlpha(Theme.textPrimary, 0.07)
                        }

                        Item { width: 1; height: 20 }

                        Text {
                            width: parent.width
                            text: "诗句"
                            color: Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                            font.letterSpacing: 3
                        }

                        Item { width: 1; height: 8 }

                        Text {
                            width: parent.width
                            text: "「远潮藏诗，魅影托梦」"
                            color: Theme.primary
                            font.family: Theme.fontFamily
                            font.pixelSize: 22
                            font.letterSpacing: 2
                        }

                        Item { width: 1; height: 20 }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.withAlpha(Theme.textPrimary, 0.07)
                        }

                        Item { width: 1; height: 20 }

                        Text {
                            width: parent.width
                            text: "MIT License · 2026"
                            color: Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontMicro
                            font.letterSpacing: 1
                        }

                        Item { width: 1; height: 24 }
                    }
                }
            }
        }
    }
}
