import QtQuick
import QtQuick.Controls
import QtQuick.Effects

import ".."

/*!
    中奖贺卡。
    - 全屏半透明遮罩 + 白色大圆角弹窗
    - 单人中奖大字号渐变姓名；多人中奖网格排列
    - AI 点评按钮与文本展示
    - “关闭”与“继续抽奖”两个动作
*/
Item {
    id: resultCard

    anchors.fill: parent

    property var winnerNames: []
    property bool opened: false
    property bool aiBusy: false
    property string aiSpeech: ""
    property string aiError: ""

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
        aiBusy = false
        aiSpeech = ""
        aiError = ""
        opened = true
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

    function requestAiSpeech() {
        if (aiBusy || firstWinner.length === 0)
            return

        aiBusy = true
        aiError = ""

        if (typeof backendBridge !== "undefined" && backendBridge
                && backendBridge.aiManager) {
            backendBridge.aiManager.generateAwardSpeech(firstWinner)
        } else {
            aiBusy = false
            aiError = "AI 服务暂不可用"
        }
    }

    onOpenedChanged: {
        if (!opened) {
            aiBusy = false
        }
    }

    Keys.onEscapePressed: resultCard.close()

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
                text: resultCard.multi
                      ? "愿这份好签，落到每一位幸运的人身上"
                      : "愿这份好签，带来课堂里的小小惊喜"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontCaption
                horizontalAlignment: Text.AlignHCenter
            }

            Item {
                width: parent.width
                height: 44

                CardButton {
                    anchors.centerIn: parent
                    width: 190
                    height: 40
                    primary: false
                    text: resultCard.aiBusy ? "AI 正在思考…" : "✨ 获取 AI 点评"
                    enabled: !resultCard.aiBusy && resultCard.firstWinner.length > 0
                    onClicked: resultCard.requestAiSpeech()
                }
            }

            Rectangle {
                width: parent.width
                height: 64
                radius: 12
                color: Theme.surfaceAlt
                visible: resultCard.aiBusy
                         || resultCard.aiSpeech.length > 0
                         || resultCard.aiError.length > 0

                Text {
                    anchors.fill: parent
                    anchors.margins: 14
                    text: resultCard.aiBusy
                          ? "AI 正在为这次中签写一句颁奖词…"
                          : (resultCard.aiError.length > 0
                             ? resultCard.aiError
                             : resultCard.aiSpeech)
                    color: resultCard.aiError.length > 0
                           ? Theme.danger
                           : (resultCard.aiBusy ? Theme.textSecondary : Theme.textPrimary)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                }
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

    Connections {
        target: backendBridge.aiManager
        ignoreUnknownSignals: true

        function onAwardSpeechReady(speech) {
            if (!resultCard.opened)
                return
            resultCard.aiBusy = false
            resultCard.aiSpeech = speech
        }

        function onAwardSpeechFailed(message) {
            if (!resultCard.opened)
                return
            resultCard.aiBusy = false
            resultCard.aiError = message
        }

        function onNetworkError(message) {
            if (!resultCard.opened)
                return
            resultCard.aiBusy = false
            resultCard.aiError = message
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
