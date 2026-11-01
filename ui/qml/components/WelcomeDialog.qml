import QtQuick
import QtQuick.Effects

import ".."

/*!
    首次启动欢迎弹窗。
    - 半透明遮罩 + 纯白大圆角卡片，风格与 ResultCard 一致
    - 唯一动作是“开始使用”，关闭时由使用方写入首次启动标记
*/
Item {
    id: dialog

    property bool opened: false

    opacity: opened ? 1.0 : 0.0
    visible: opacity > 0.001

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.durationNormal
            easing.type: Easing.OutCubic
        }
    }

    function open() {
        opened = true
    }

    function close() {
        opened = false
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.overlay

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }
    }

    CardShadowBehind {
        z: 0
        target: card
        shadowBlur: 0.75
        shadowOffsetY: 18
        shadowColor: Theme.withAlpha(Theme.textPrimary, 0.22)
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: Math.min(460, dialog.width - 80)
        height: 372
        radius: Theme.radiusDialog
        color: Theme.surface
        scale: dialog.opened ? 1.0 : 0.96

        Behavior on scale {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            width: 84
            height: 84
            radius: 26
            anchors.top: parent.top
            anchors.topMargin: 34
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.primarySoft

            Image {
                anchors.centerIn: parent
                width: 64
                height: 64
                source: "qrc:/ui/assets/app-icon-512.png"
                sourceSize.width: 512
                sourceSize.height: 512
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }
        }

        Text {
            id: titleText

            anchors.top: parent.top
            anchors.topMargin: 138
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "欢迎使用撷签"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontH0
            font.weight: Font.Bold
            font.letterSpacing: 1
        }

        Text {
            id: bodyText

            anchors.top: titleText.bottom
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 40
            anchors.rightMargin: 40
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "自定义转盘、名单权重与成绩识图，都在一个窗口里"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            lineHeight: 1.45
        }

        Text {
            id: hintText

            anchors.top: bodyText.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 40
            anchors.rightMargin: 40
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "去设置页填上自己的 AI 密钥，或直接用内置功能"
            color: Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontCaption
        }

        Item {
            id: startButton

            anchors.bottom: parent.bottom
            anchors.bottomMargin: 34
            anchors.horizontalCenter: parent.horizontalCenter
            width: 210
            height: 48

            Rectangle {
                id: buttonBody

                anchors.fill: parent
                radius: Theme.radiusPill
                gradient: Theme.primaryGradient
                scale: startMouse.pressed ? 0.97 : (startMouse.containsMouse ? 1.02 : 1.0)

                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.durationFast
                        easing.type: Easing.OutCubic
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "开始使用"
                    color: Theme.white
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontH2
                    font.weight: Font.DemiBold
                    font.letterSpacing: 2
                }
            }

            MouseArea {
                id: startMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: dialog.close()
            }
        }
    }
}
