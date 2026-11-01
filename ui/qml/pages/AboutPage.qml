import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import ".."

/*!
    关于页。
    iOS 大标题 + App Store 应用详情页的排版：
    左侧 40% 放品牌与应用图标，右侧 60% 是应用信息卡片与资料列表。
*/
Item {
    id: page

    anchors.fill: parent

    Item {
        id: pageContent

        anchors.fill: parent
        anchors.margins: Theme.pagePadding

        Item {
            id: header

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 76

            Column {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                spacing: 2

                Text {
                    text: "关于"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLargeTitle
                    font.weight: Font.Bold
                }

                Text {
                    text: "一款为课堂而生的抽签工具"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }
        }

        RowLayout {
            id: columns

            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 28

            // ── 左栏：品牌 ──
            Item {
                Layout.preferredWidth: (columns.width - columns.spacing) * 0.4
                Layout.fillHeight: true

                Column {
                    anchors.centerIn: parent
                    width: Math.min(300, parent.width)
                    spacing: 0

                    Item {
                        width: parent.width
                        height: 132

                        Rectangle {
                            anchors.centerIn: parent
                            width: 116
                            height: 116
                            radius: 28
                            color: Theme.surface

                            Image {
                                anchors.centerIn: parent
                                width: 104
                                height: 104
                                source: "qrc:/ui/assets/app-icon-512.png"
                                sourceSize.width: 512
                                sourceSize.height: 512
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                mipmap: true
                            }
                        }
                    }

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

                    Item { width: 1; height: 16 }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: versionText.implicitWidth + 26
                        height: 26
                        radius: 13
                        color: Theme.fill

                        Text {
                            id: versionText
                            anchors.centerIn: parent
                            text: "v1.1.1"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontMicro
                            font.letterSpacing: 1
                        }
                    }

                    Item { width: 1; height: 18 }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "「远潮藏诗，魅影托梦」"
                        color: Theme.primary
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                    }
                }
            }

            // ── 右栏：应用详情 ──
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Flickable {
                    id: infoFlick

                    anchors.fill: parent
                    clip: true
                    contentWidth: width
                    contentHeight: infoColumn.height + 8
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 2600

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AlwaysOff
                    }

                    Column {
                        id: infoColumn

                        width: infoFlick.width
                        spacing: 0

                        // App Store 顶部信息卡：图标 + 名称 + 版本/语言等要素
                        Rectangle {
                            width: parent.width
                            height: 132
                            radius: Theme.radiusCard
                            color: Theme.surface

                            CardShadowLight {}

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20
                                spacing: 16

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 88
                                    height: 88
                                    radius: 20
                                    color: Theme.fill

                                    Image {
                                        anchors.centerIn: parent
                                        width: 78
                                        height: 78
                                        source: "qrc:/ui/assets/app-icon-512.png"
                                        sourceSize.width: 512
                                        sourceSize.height: 512
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        mipmap: true
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 88 - 16
                                    spacing: 4

                                    Text {
                                        width: parent.width
                                        text: "撷签"
                                        color: Theme.textPrimary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 22
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        width: parent.width
                                        text: "课堂抽签 · 随机分组 · 自定义转盘"
                                        color: Theme.textSecondary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontBody
                                        elide: Text.ElideRight
                                    }

                                    Item { width: 1; height: 6 }

                                    Row {
                                        spacing: 0

                                        Column {
                                            width: 84
                                            spacing: 2

                                            Text {
                                                text: "版本"
                                                color: Theme.textTertiary
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 10
                                            }

                                            Text {
                                                text: "1.1.1"
                                                color: Theme.textPrimary
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontCaption
                                                font.weight: Font.DemiBold
                                            }
                                        }

                                        Column {
                                            width: 96
                                            spacing: 2

                                            Text {
                                                text: "类型"
                                                color: Theme.textTertiary
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 10
                                            }

                                            Text {
                                                text: "教学工具"
                                                color: Theme.textPrimary
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontCaption
                                                font.weight: Font.DemiBold
                                            }
                                        }

                                        Column {
                                            width: 96
                                            spacing: 2

                                            Text {
                                                text: "语言"
                                                color: Theme.textTertiary
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 10
                                            }

                                            Text {
                                                text: "简体中文"
                                                color: Theme.textPrimary
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontCaption
                                                font.weight: Font.DemiBold
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item { width: 1; height: 18 }

                        Text {
                            leftPadding: 4
                            text: "作者与资料"
                            color: Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                        }

                        Item { width: 1; height: 7 }

                        Rectangle {
                            width: parent.width
                            height: detailColumn.height
                            radius: Theme.radiusCard
                            color: Theme.surface

                            CardShadowLight {}

                            Column {
                                id: detailColumn
                                width: parent.width

                                DetailRow {
                                    title: "作者"
                                    value: "汐辞梦"
                                }

                                Sep {}

                                DetailRow {
                                    title: "QQ"
                                    value: "2995723028"
                                }

                                Sep {}

                                DetailRow {
                                    title: "语录"
                                    value: "Misty Arcane Dreamy Ethereal Radiant Omen Xenon Cipher Muse"
                                    multiline: true
                                }

                                Sep {}

                                DetailRow {
                                    title: "许可"
                                    value: "MIT License · 2026"
                                }
                            }
                        }

                        Item { width: 1; height: 18 }

                        Text {
                            leftPadding: 4
                            text: "简介"
                            color: Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                        }

                        Item { width: 1; height: 7 }

                        Rectangle {
                            width: parent.width
                            height: introText.implicitHeight + 36
                            radius: Theme.radiusCard
                            color: Theme.surface

                            CardShadowLight {}

                            Text {
                                id: introText

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Theme.cardPadding
                                anchors.rightMargin: Theme.cardPadding
                                text: "撷签把「点谁」这件事做得更轻：转盘先定答案再旋转，"
                                      + "名单支持成绩调权，也能用一张截图把名字认出来。"
                                      + "愿每一次选择，都少一点犹豫。"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                lineHeight: 1.5
                                wrapMode: Text.WordWrap
                            }
                        }

                        Item { width: 1; height: 16 }
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 卡片投影（关于页只读，不绘制交互态）
    // ─────────────────────────────────────────────────────────────
    component CardShadowLight: Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, (parent && parent.radius !== undefined
                             ? parent.radius
                             : Theme.radiusCard) - 1)
        color: Theme.surface
        z: -1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadowColor
            shadowBlur: 0.5
            shadowVerticalOffset: 3
            shadowHorizontalOffset: 0
            autoPaddingEnabled: true
        }
    }

    // 图标底板不需要投影，占位类型让 layer.effect 保持类型安全
    component MultiEffectPlaceholder: MultiEffect {
        shadowEnabled: false
    }

    // ─────────────────────────────────────────────────────────────
    // 资料行
    // ─────────────────────────────────────────────────────────────
    component DetailRow: Item {
        id: row

        width: parent ? parent.width : 0
        height: row.multiline ? valueText.implicitHeight + 34 : 52

        property string title: ""
        property string value: ""
        property bool multiline: false

        Text {
            anchors.left: parent.left
            anchors.leftMargin: Theme.cardPadding
            y: row.multiline ? 17 : (row.height - height) / 2
            text: row.title
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
        }

        Text {
            id: valueText

            anchors.left: parent.left
            anchors.leftMargin: 92
            anchors.right: parent.right
            anchors.rightMargin: Theme.cardPadding
            y: row.multiline ? 17 : (row.height - height) / 2
            text: row.value
            horizontalAlignment: Text.AlignRight
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            elide: row.multiline ? Text.ElideNone : Text.ElideRight
            wrapMode: row.multiline ? Text.WordWrap : Text.NoWrap
            lineHeight: 1.4
        }
    }

    // 卡片内极细分割线
    component Sep: Item {
        width: parent ? parent.width : 0
        height: 1

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: Theme.cardPadding
            anchors.right: parent.right
            height: 1
            color: Theme.separator
        }
    }
}
