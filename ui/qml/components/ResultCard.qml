import QtQuick
import QtQuick.Controls
import QtQuick.Effects

import ".."

/*!
    中奖贺卡。
    - 全屏半透明遮罩 + 白色大圆角弹窗
    - 单人中奖大字号渐变姓名；多人中奖网格排列
    - 姓名下方随机展示一句本地语录
    - “关闭”与“继续抽奖”两个动作
*/
Item {
    id: resultCard

    property var winnerNames: []
    property bool opened: false
    property string quote: ""

    readonly property var quotes: [
        "命运的齿轮开始转动",
        "你就是今日的幸运星",
        "远潮藏诗，此刻为你",
        "所有伏笔，都在这一刻揭晓",
        "光落在你身上，刚好",
        "好运正在加速赶来",
        "这一签，是宇宙偷偷偏爱你",
        "风起时，答案已经有了",
        "你从人海里，被点名成为惊喜",
        "今天的运气，是限量款",
        "把平凡的一刻，过成小庆典",
        "心里有花，签上有光",
        "这是属于你的高光三秒钟",
        "恰好的时间，恰好的你",
        "签筒很诚实，它说就是你",
        "请查收这份突如其来的好运",
        "你被幸运轻轻地拍了拍",
        "万事胜意，从这一刻开始",
        "星光不问赶路人，时光不负有心人",
        "愿你此后所遇，皆是温柔",
        "幸运没有剧本，却偏偏选中你",
        "掌声给到这位天选之人",
        "概率很小，你很大",
        "抽中你的那一下，连风都在鼓掌",
        "这一刻，签文为你折返",
        "好事发生，正在加载 100%",
        "你今天的运气，超标了",
        "这一签，藏着小小的盛大",
        "人间值得，你也值得",
        "云端有信，落款是你",
        "你的名字，是今天的答案",
        "好运不是偶然，是你值得",
        "请收下这份不讲道理的偏爱",
        "生活偶尔发糖，这次发给了你",
        "被选中的瞬间，世界安静了一秒",
        "山海有归期，好运有回音",
        "你一笑，签就亮了",
        "这一刻，请允许自己得意一下",
        "有风自南，吹来你的好运",
        "这只是开始，后面还有更多",
        "你是这份名单里最亮的注脚",
        "灯亮起，主角是你",
        "世界很大，幸运刚好路过你",
        "签上有名，心里有光",
        "把今天，记成一个小小的纪念日",
        "被幸运点名，记得答“到”",
        "你的好运，正在派送中",
        "好事成双，先来一半",
        "星河滚烫，你是人间理想",
        "这一刻，山川都替你高兴",
        "你是概率里的浪漫",
        "抬头看，幸运正朝你走来",
        "今天的小确幸，署名是你",
        "生活的彩蛋，刚好砸中你",
        "不必谦虚，这次就是你",
        "风把你吹到了答案这一页",
        "世界偷偷奖励了认真生活的你",
        "被选中的感觉，还不错吧",
        "一盏灯为你亮，一签为你留",
        "愿这份惊喜，抵得过所有疲惫",
        "好运有迹可循，线索是你的名字",
        "抽中你，是今天最顺的事",
        "你走过的路，都算数",
        "命运敲门时，你刚好在家",
        "这一签，祝你万事顺遂",
        "幸运正在你的名字上停留",
        "请保持微笑，你被好运看中了",
        "生活偶尔偏心，这次偏向你",
        "人群之中，光先找到了你",
        "你值得所有不期而遇的欢喜",
        "这一刻，请把好运据为己有",
        "有请今日份的幸运儿",
        "你被写进了今天的温柔里",
        "一签落地，万事可期",
        "风会记得你今天的笑",
        "愿你所求皆如愿，所行皆坦途",
        "被光选中的人，不必低头",
        "这份运气，请慢慢用",
        "你出现的时候，答案就出现了",
        "今日签文：宜得意，宜欢喜",
        "恭喜你，成为今日的小概率事件",
        "这一下，抽出了整个春天",
        "好运已在路上，请保持开机",
        "你是被时光温柔以待的人",
        "山高水长，好运常在",
        "请把这份惊喜，讲给喜欢的人听",
        "你在名单里，也在星光里",
        "这个瞬间，值得被记住",
        "愿你有好运气，也有好心情",
        "今日份的浪漫，由你签收",
        "被选中的一秒，值得庆祝一天",
        "所有等待，都在此刻有了回音",
        "你一笑，整间教室都亮了",
        "这一签，签的是心想事成",
        "好运不请自来，主角刚好是你",
        "请允许今天，为你多亮一盏灯",
        "你在的地方，就是好运的方向",
        "愿这份小小幸运，陪你很久",
        "恭喜，你被今天格外喜欢",
        "命运的签，正好落在你手心"
    ]

    readonly property bool multi: winnerNames.length > 1
    readonly property int columns: winnerNames.length <= 4 ? 2 : 3
    readonly property int rows: multi ? Math.ceil(winnerNames.length / columns) : 1
    readonly property string firstWinner: winnerNames.length > 0 ? winnerNames[0] : ""

    opacity: opened ? 1.0 : 0.0
    visible: opacity > 0.001
    focus: opened

    signal closeRequested()
    signal continueRequested()

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.durationNormal
            easing.type: Easing.OutCubic
        }
    }

    function open(names) {
        var list = []
        if (names !== undefined && names !== null) {
            for (var i = 0; i < names.length; ++i) {
                var name = String(names[i])
                if (name.length > 0)
                    list.push(name)
            }
        }

        winnerNames = list
        quote = quotes[Math.floor(Math.random() * quotes.length)]
        opened = true

        // 彩带只在弹出瞬间撒一次，2 秒后整层卸载
        confettiLoader.active = true
        confettiTimer.restart()
    }

    function close() {
        if (!opened)
            return
        opened = false
        closeRequested()
    }

    function continueDrawing() {
        if (!opened)
            return
        opened = false
        continueRequested()
    }

    Keys.onEscapePressed: resultCard.close()

    // ─────────────────────────────────────────────────────────────
    // 中奖彩带：纯 QML 矩形 + 位移动画，不依赖 QtQuick.Particles
    // ─────────────────────────────────────────────────────────────
    Loader {
        id: confettiLoader

        anchors.fill: parent
        z: 10
        active: false
        sourceComponent: confettiComponent
    }

    Timer {
        id: confettiTimer
        interval: 3000
        repeat: false
        onTriggered: confettiLoader.active = false
    }

    Component {
        id: confettiComponent

        Item {
            id: confettiField

            anchors.fill: parent

            Repeater {
                model: 90

                delegate: Rectangle {
                    id: ribbon

                    readonly property real startX: ((index * 97) % 100) / 100 * confettiField.width

                    x: startX
                    y: -24
                    width: 6
                    height: 18
                    radius: 1.5
                    transformOrigin: Item.Center
                    color: ["#3B8BF6", "#2ED4A5", "#FFD600", "#FF6D00", "#F54A45", "#B36BFF"][index % 6]

                    // 横向飘移
                    property real drift: 0
                    transform: Translate { x: ribbon.drift }

                    NumberAnimation on y {
                        running: true
                        from: -24
                        to: confettiField.height + 40
                        duration: 2000 + (index % 5) * 260
                        easing.type: Easing.InQuad
                    }

                    NumberAnimation on drift {
                        running: true
                        from: 0
                        to: (index % 2 === 0 ? 1 : -1) * (18 + (index % 5) * 14)
                        duration: 1600 + (index % 7) * 140
                        easing.type: Easing.InOutSine
                    }

                    RotationAnimator on rotation {
                        from: 0
                        to: 360 * (index % 2 === 0 ? 1 : -1)
                        duration: 900 + (index % 4) * 220
                        loops: Animation.Infinite
                        running: true
                    }
                }
            }
        }
    }

    // 全屏遮罩
    Rectangle {
        anchors.fill: parent
        color: Theme.overlay

        MouseArea {
            anchors.fill: parent
            onClicked: resultCard.close()
        }
    }

    // 贺卡外投影（独立一层，避免整张贺卡 layer 后内容在软件渲染下丢失）
    CardShadowBehind {
        z: 0
        target: card
        shadowBlur: 0.75
        shadowOffsetY: 18
        shadowColor: Theme.withAlpha(Theme.textPrimary, 0.22)
    }

    // 贺卡
    Rectangle {
        id: card

        anchors.centerIn: parent
        width: resultCard.multi
               ? Math.min(780, resultCard.width - 80)
               : Math.min(540, resultCard.width - 80)
        readonly property real contentHeight: 28 + titleText.implicitHeight + 18
                                              + bodyColumn.implicitHeight
                                              + 24 + 44 + 28
        height: Math.min(resultCard.height - 48, Math.max(320, contentHeight))
        radius: Theme.radiusDialog
        color: Theme.surface
        scale: resultCard.opened ? 1.0 : 0.96

        Behavior on scale {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // 顶部标题
        Text {
            id: titleText

            anchors.top: parent.top
            anchors.topMargin: 28
            anchors.horizontalCenter: parent.horizontalCenter
            text: resultCard.multi
                  ? "共 " + resultCard.winnerNames.length + " 位中签"
                  : "恭 喜 中 签"
            color: Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontMicro
            font.letterSpacing: 4
        }

        // 关闭按钮
        Item {
            width: 32
            height: 32
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 18
            anchors.rightMargin: 18

            Rectangle {
                anchors.fill: parent
                radius: 16
                color: closeMouse.containsMouse ? Theme.surfaceAlt : Theme.transparent

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.durationFast
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "×"
                color: closeMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 20
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: resultCard.close()
            }
        }

        Column {
            id: bodyColumn

            anchors.top: titleText.bottom
            anchors.topMargin: 18
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 34
            anchors.rightMargin: 34
            spacing: 14

            // 单人：大字号渐变姓名
            GradientName {
                width: parent.width
                height: resultCard.multi ? 0 : 84
                visible: !resultCard.multi
                text: resultCard.firstWinner
                fontPixelSize: 56
            }

            // 多人：网格姓名
            Item {
                width: parent.width
                height: resultCard.multi ? winnerGrid.height + 4 : 0
                visible: resultCard.multi

                Grid {
                    id: winnerGrid

                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: resultCard.columns
                    spacing: 8

                    Repeater {
                        model: resultCard.winnerNames

                        delegate: Rectangle {
                            width: 150
                            height: 40
                            radius: 12
                            color: Theme.surfaceAlt
                            border.width: 1
                            border.color: Theme.withAlpha(Theme.primary, 0.10)

                            GradientName {
                                anchors.fill: parent
                                text: modelData
                                fontPixelSize: 22
                            }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: resultCard.quote
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontCaption
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }

        // 底部动作
        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 34
            anchors.bottomMargin: 28
            spacing: 12

            CardButton {
                width: 116
                height: 44
                text: "关闭"
                primary: false
                onClicked: resultCard.close()
            }

            CardButton {
                width: 150
                height: 44
                text: "继续抽奖"
                primary: true
                onClicked: resultCard.continueDrawing()
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 渐变文字
    // ─────────────────────────────────────────────────────────────
    component GradientName: Canvas {
        id: gradientName

        property string text: ""
        property int fontPixelSize: 40
        property color startColor: Theme.primary
        property color endColor: Theme.primaryEnd

        onTextChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onFontPixelSizeChanged: requestPaint()
        onStartColorChanged: requestPaint()
        onEndColorChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            if (width <= 0 || height <= 0 || text.length === 0)
                return

            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var size = fontPixelSize
            var font = "bold " + size + "px sans-serif"
            ctx.font = font

            while (ctx.measureText(text).width > width - 12 && size > 12) {
                size -= 2
                ctx.font = "bold " + size + "px '" + Theme.fontFamily + "'"
            }

            var gradient = ctx.createLinearGradient(0, 0, width, 0)
            gradient.addColorStop(0, String(startColor))
            gradient.addColorStop(1, String(endColor))

            ctx.fillStyle = gradient
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            ctx.fillText(text, width / 2, height / 2 + 1)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 贺卡按钮
    // ─────────────────────────────────────────────────────────────
    component CardButton: Item {
        id: button

        property string text: ""
        property bool primary: true
        signal clicked()

        implicitWidth: 140
        implicitHeight: 44
        width: 140
        height: 44
        enabled: true
        opacity: enabled ? 1.0 : 0.45
        scale: mouse.pressed && enabled
               ? 0.95
               : (mouse.containsMouse && enabled ? 1.02 : 1.0)

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durationFast
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: Theme.durationFast
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: buttonShadowSource
            anchors.fill: parent
            radius: height / 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: button.primary ? Theme.primary : Theme.surface
                }
                GradientStop {
                    position: 1.0
                    color: button.primary ? Theme.primaryEnd : Theme.surface
                }
            }

            layer.enabled: button.primary
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.withAlpha(Theme.primary, 0.22)
                shadowBlur: 0.55
                shadowVerticalOffset: 6
                shadowHorizontalOffset: 0
                autoPaddingEnabled: true
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: button.primary ? Theme.primary : Theme.surface
                }
                GradientStop {
                    position: 1.0
                    color: button.primary ? Theme.primaryEnd : Theme.surface
                }
            }
            border.width: 1
            border.color: button.primary
                          ? Theme.withAlpha(Theme.white, 0.18)
                          : Theme.border
        }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: button.primary ? Theme.white : Theme.primarySoft
            opacity: mouse.containsMouse && button.enabled
                     ? (button.primary ? 0.10 : 0.45)
                     : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: button.text
            color: button.primary ? Theme.white : Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            font.weight: Font.DemiBold
            font.letterSpacing: 1
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: button.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (button.enabled)
                    button.clicked()
            }
        }
    }
}
