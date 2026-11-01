import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import ".."
import "../components/ExpressionParser.js" as Parser

/*!
    教学工具页。
    - 高级计算器：递归下降解析表达式，支持括号、乘方、三角与对数
    - 函数图像：直角坐标 / 参数方程 / 隐式方程，Canvas 网格 + 生长动画
*/
Item {
    id: page

    anchors.fill: parent

    readonly property bool reducedMotion: !backendBridge.motionEnabled
    readonly property int modeCalculator: 0
    readonly property int modePlotter: 1

    property int mode: modeCalculator

    // ─── 计算器状态 ───
    property string calcExpression: ""
    property string calcResult: "0"
    property bool calcEvaluated: false
    property string calcError: ""

    readonly property var calcKeys: [
        { "label": "AC", "action": "clear", "accent": true },
        { "label": "(", "action": "insert:(" },
        { "label": ")", "action": "insert:)" },
        { "label": "÷", "action": "insert:/", "accent": true },
        { "label": "7", "action": "insert:7" },
        { "label": "8", "action": "insert:8" },
        { "label": "9", "action": "insert:9" },
        { "label": "×", "action": "insert:*", "accent": true },
        { "label": "4", "action": "insert:4" },
        { "label": "5", "action": "insert:5" },
        { "label": "6", "action": "insert:6" },
        { "label": "−", "action": "insert:-", "accent": true },
        { "label": "1", "action": "insert:1" },
        { "label": "2", "action": "insert:2" },
        { "label": "3", "action": "insert:3" },
        { "label": "+", "action": "insert:+", "accent": true },
        { "label": "0", "action": "insert:0" },
        { "label": ".", "action": "insert:." },
        { "label": "⌫", "action": "back" },
        { "label": "=", "action": "equals", "accent": true }
    ]

    readonly property var calcFunctions: [
        { "label": "sin", "action": "insert:sin(" },
        { "label": "cos", "action": "insert:cos(" },
        { "label": "tan", "action": "insert:tan(" },
        { "label": "√", "action": "insert:sqrt(" },
        { "label": "log", "action": "insert:log(" },
        { "label": "ln", "action": "insert:ln(" },
        { "label": "^", "action": "insert:^" },
        { "label": "π", "action": "insert:pi" }
    ]

    // ─── 函数图像状态 ───
    property string plotText: "x = 16sin^3(t), y = 13cos(t) - 5cos(2t) - 2cos(3t) - cos(4t)"
    // 参数方程的参数 t 扫过几整圈：螺旋线、蝴蝶曲线需要多圈才能画完
    property int plotTurns: 1
    property var plotPaths: []
    property var plotBounds: ({ "xmin": -1.0, "xmax": 1.0, "ymin": -1.0, "ymax": 1.0,
                                "uniform": true })
    property real plotProgress: 0.0
    property bool hasPlot: false
    property string plotError: ""
    property bool aiBusy: false
    property string aiStatus: ""
    property string aiPrompt: ""

    function calcClear() {
        calcExpression = ""
        calcResult = "0"
        calcEvaluated = false
        calcError = ""
    }

    function calcInsert(token) {
        if (calcEvaluated) {
            // 等号之后再输入运算符表示接着算，输入数字或函数则开始新算式
            var continues = token.length === 1 && "+-*/^%".indexOf(token) >= 0
            calcExpression = continues ? calcResult : ""
            calcEvaluated = false
        }

        if (calcExpression.length >= 160)
            return

        calcExpression += token
        calcError = ""
    }

    function calcBackspace() {
        calcEvaluated = false
        calcError = ""
        if (calcExpression.length > 0)
            calcExpression = calcExpression.substring(0, calcExpression.length - 1)
    }

    function calcEquals() {
        if (calcExpression.length === 0)
            return

        var outcome = Parser.evaluate(calcExpression, {})
        calcEvaluated = true

        if (!outcome.ok) {
            calcError = outcome.error
            calcResult = "错误"
            return
        }
        if (!isFinite(outcome.value)) {
            calcError = "除数不能为 0"
            calcResult = "错误"
            return
        }

        calcError = ""
        calcResult = Parser.formatNumber(outcome.value)
    }

    function pressCalcKey(action) {
        if (action === "clear")
            calcClear()
        else if (action === "back")
            calcBackspace()
        else if (action === "equals")
            calcEquals()
        else if (action.indexOf("insert:") === 0)
            calcInsert(action.substring(7))
    }

    // ─────────────────────────────────────────────────────────────
    // 表达式解析：区分直角坐标、参数方程与隐式方程
    // ─────────────────────────────────────────────────────────────
    function splitTopLevel(text) {
        var parts = []
        var current = ""
        var depth = 0

        for (var i = 0; i < text.length; ++i) {
            var ch = text.charAt(i)
            if (ch === "(" || ch === "（")
                depth += 1
            else if (ch === ")" || ch === "）")
                depth = Math.max(0, depth - 1)

            if (depth === 0 && (ch === "," || ch === ";" || ch === "\n")) {
                parts.push(current)
                current = ""
                continue
            }
            current += ch
        }
        parts.push(current)

        var cleaned = []
        for (var j = 0; j < parts.length; ++j) {
            var part = parts[j].trim()
            if (part.length > 0)
                cleaned.push(part)
        }
        return cleaned
    }

    function parsePlotSpec(text) {
        var parts = splitTopLevel(text)
        if (parts.length === 0) {
            plotError = "先输入一个函数表达式"
            return null
        }

        if (parts.length === 2) {
            var first = /^([xy])\s*=(.*)$/i.exec(parts[0])
            var second = /^([xy])\s*=(.*)$/i.exec(parts[1])
            if (first && second && first[1].toLowerCase() !== second[1].toLowerCase()) {
                var byName = {}
                byName[first[1].toLowerCase()] = first[2].trim()
                byName[second[1].toLowerCase()] = second[2].trim()
                if (byName.x && byName.y)
                    return { "kind": "parametric", "xExpr": byName.x, "yExpr": byName.y }
            }
        }

        if (parts.length > 2) {
            plotError = "表达式太多啦，最多支持两条参数方程"
            return null
        }

        var body = parts[0]
        var equals = body.indexOf("=")

        if (equals >= 0) {
            var left = body.substring(0, equals).trim()
            var right = body.substring(equals + 1).trim()

            if (right.length === 0) {
                plotError = "等号右边不能为空"
                return null
            }
            if (/^y$/i.test(left))
                return { "kind": "explicit", "expr": right }
            if (/^x$/i.test(left)) {
                plotError = "参数方程需要同时给出 x = ... 与 y = ..."
                return null
            }
            return { "kind": "implicit", "lhs": left, "rhs": right }
        }

        return { "kind": "explicit", "expr": body }
    }

    function storePaths(paths, bounds) {
        if (paths.length === 0) {
            plotError = "这个表达式在可见范围内没有曲线"
            return
        }

        plotBounds = bounds
        plotPaths = paths
        hasPlot = true
        plotProgress = reducedMotion ? 1.0 : 0.0
        plotCanvas.requestPaint()
        if (!reducedMotion)
            growthAnimation.restart()
    }

    function padBounds(minimum, maximum) {
        var span = maximum - minimum
        if (!isFinite(span) || span <= 0)
            span = 1.0
        var pad = span * 0.12
        return [minimum - pad, maximum + pad]
    }

    function computeExplicit(spec) {
        var compiled = Parser.compile(spec.expr)
        if (!compiled.ok) {
            plotError = compiled.error
            return
        }
        for (var v = 0; v < compiled.variables.length; ++v) {
            if (compiled.variables[v] !== "x") {
                plotError = "直角坐标方程只能使用变量 x"
                return
            }
        }

        var samples = 600
        var paths = []
        var current = []
        var minimum = Infinity
        var maximum = -Infinity

        for (var i = 0; i < samples; ++i) {
            var x = -10.0 + 20.0 * i / (samples - 1)
            var y = compiled.fn({ "x": x })

            if (!isFinite(y) || Math.abs(y) > 1e4) {
                if (current.length > 1)
                    paths.push(current)
                current = []
                continue
            }

            current.push([x, y])
            minimum = Math.min(minimum, y)
            maximum = Math.max(maximum, y)
        }
        if (current.length > 1)
            paths.push(current)

        if (paths.length === 0) {
            plotError = "这个表达式在可见范围内没有曲线"
            return
        }

        var vertical = padBounds(minimum, maximum)
        storePaths(paths, { "xmin": -10.0, "xmax": 10.0,
                            "ymin": vertical[0], "ymax": vertical[1],
                            "uniform": false })
    }

    function computeParametric(spec) {
        var xCompiled = Parser.compile(spec.xExpr)
        var yCompiled = Parser.compile(spec.yExpr)
        if (!xCompiled.ok) {
            plotError = "x 表达式：" + xCompiled.error
            return
        }
        if (!yCompiled.ok) {
            plotError = "y 表达式：" + yCompiled.error
            return
        }

        var variables = xCompiled.variables.concat(yCompiled.variables)
        for (var v = 0; v < variables.length; ++v) {
            if (variables[v] !== "t") {
                plotError = "参数方程只能使用变量 t"
                return
            }
        }

        var samples = Math.min(3600, 720 * Math.max(1, page.plotTurns))
        var points = []
        var minX = Infinity
        var maxX = -Infinity
        var minY = Infinity
        var maxY = -Infinity

        for (var i = 0; i <= samples; ++i) {
            var t = 2 * Math.PI * Math.max(1, page.plotTurns) * i / samples
            var x = xCompiled.fn({ "t": t })
            var y = yCompiled.fn({ "t": t })

            if (!isFinite(x) || !isFinite(y) || Math.abs(x) > 1e4 || Math.abs(y) > 1e4)
                continue

            points.push([x, y])
            minX = Math.min(minX, x)
            maxX = Math.max(maxX, x)
            minY = Math.min(minY, y)
            maxY = Math.max(maxY, y)
        }

        if (points.length < 2) {
            plotError = "这个参数方程没有可绘制的点"
            return
        }

        var horizontal = padBounds(minX, maxX)
        var vertical = padBounds(minY, maxY)
        storePaths([points], { "xmin": horizontal[0], "xmax": horizontal[1],
                               "ymin": vertical[0], "ymax": vertical[1],
                               "uniform": true })
    }

    function computeImplicit(spec) {
        var leftCompiled = Parser.compile(spec.lhs)
        var rightCompiled = Parser.compile(spec.rhs)
        if (!leftCompiled.ok) {
            plotError = "等式左边：" + leftCompiled.error
            return
        }
        if (!rightCompiled.ok) {
            plotError = "等式右边：" + rightCompiled.error
            return
        }

        var variables = leftCompiled.variables.concat(rightCompiled.variables)
        for (var v = 0; v < variables.length; ++v) {
            if (variables[v] !== "x" && variables[v] !== "y") {
                plotError = "隐式方程只能使用变量 x 与 y"
                return
            }
        }

        // 等值线（marching squares）：把满足 F(x, y) = 0 的格子边连成线段
        var size = 132
        var xmin = -3.0
        var xmax = 3.0
        var ymin = -3.0
        var ymax = 3.0
        var dx = (xmax - xmin) / size
        var dy = (ymax - ymin) / size

        var field = []
        for (var j = 0; j <= size; ++j) {
            for (var i = 0; i <= size; ++i) {
                var x = xmin + i * dx
                var y = ymin + j * dy
                field.push(leftCompiled.fn({ "x": x, "y": y })
                           - rightCompiled.fn({ "x": x, "y": y }))
            }
        }

        var paths = []
        var rowStride = size + 1
        var minX = Infinity
        var maxX = -Infinity
        var minY = Infinity
        var maxY = -Infinity

        function keep(point) {
            minX = Math.min(minX, point[0])
            maxX = Math.max(maxX, point[0])
            minY = Math.min(minY, point[1])
            maxY = Math.max(maxY, point[1])
            return point
        }

        function edgePoint(a, b, ax, ay, bx, by) {
            if ((a >= 0) === (b >= 0))
                return null
            var t = Math.abs(a - b) < 1e-12 ? 0.5 : a / (a - b)
            return [ax + (bx - ax) * t, ay + (by - ay) * t]
        }

        for (var row = 0; row < size; ++row) {
            for (var column = 0; column < size; ++column) {
                var index = row * rowStride + column
                var v0 = field[index]
                var v1 = field[index + 1]
                var v2 = field[index + rowStride + 1]
                var v3 = field[index + rowStride]

                var x0 = xmin + column * dx
                var y0 = ymin + row * dy
                var x1 = x0 + dx
                var y1 = y0 + dy

                var crossings = []
                var edge

                edge = edgePoint(v0, v1, x0, y0, x1, y0)
                if (edge !== null) crossings.push(edge)
                edge = edgePoint(v1, v2, x1, y0, x1, y1)
                if (edge !== null) crossings.push(edge)
                edge = edgePoint(v2, v3, x1, y1, x0, y1)
                if (edge !== null) crossings.push(edge)
                edge = edgePoint(v3, v0, x0, y1, x0, y0)
                if (edge !== null) crossings.push(edge)

                if (crossings.length === 2) {
                    keep(crossings[0])
                    keep(crossings[1])
                    paths.push([crossings[0], crossings[1]])
                } else if (crossings.length === 4) {
                    for (var c = 0; c < 4; ++c)
                        keep(crossings[c])
                    paths.push([crossings[0], crossings[1]])
                    paths.push([crossings[2], crossings[3]])
                }
            }
        }

        if (paths.length === 0) {
            plotError = "这个方程在可见范围内没有曲线"
            return
        }

        // 视图跟着曲线走：按实际描出的点收拢坐标范围，小图形也能铺满画布
        var horizontal = padBounds(minX, maxX)
        var vertical = padBounds(minY, maxY)
        storePaths(paths, { "xmin": horizontal[0], "xmax": horizontal[1],
                            "ymin": vertical[0], "ymax": vertical[1],
                            "uniform": true })
    }

    function drawPlot() {
        plotError = ""
        hasPlot = false
        plotPaths = []
        plotProgress = 0.0

        var text = String(plotText).trim()
        var spec = parsePlotSpec(text)
        if (spec === null)
            return

        if (spec.kind === "explicit")
            computeExplicit(spec)
        else if (spec.kind === "parametric")
            computeParametric(spec)
        else
            computeImplicit(spec)
    }

    function applyPreset(text, turns) {
        plotText = text
        plotTurns = turns === undefined || turns === null ? 1 : turns
        plotField.text = text
        drawPlot()
    }

    function generateByAI() {
        if (aiBusy)
            return

        var prompt = String(aiPrompt).trim()
        if (prompt.length === 0) {
            plotError = "先描述一下想画的图形，例如「画个爱心」"
            return
        }

        aiBusy = true
        aiStatus = "AI 正在推导表达式..."
        plotError = ""
        backendBridge.aiManager.generateFunction(prompt)
    }

    // 启动时工具页不可见，推迟到首次切到函数图像再计算，避免启动阶段白算坐标
    onModeChanged: {
        if (mode === modePlotter && !hasPlot && plotProgress <= 0)
            Qt.callLater(drawPlot)
    }

    Connections {
        target: backendBridge.aiManager

        function onFunctionGenerated(expression) {
            page.aiBusy = false
            page.aiStatus = "已生成：" + expression
            page.plotText = expression
            plotField.text = expression
            page.drawPlot()
        }

        function onFunctionFailed(message) {
            page.aiBusy = false
            page.aiStatus = ""
            page.plotError = String(message)
        }

        function onTextAiKeyMissing() {
            page.aiBusy = false
            page.aiStatus = ""
            keyDialog.open()
        }
    }

    NumberAnimation {
        id: growthAnimation
        target: page
        property: "plotProgress"
        from: 0.0
        to: 1.0
        duration: 1600
        easing.type: Easing.InOutSine
    }

    Item {
        id: pageContent
        anchors.fill: parent
        anchors.margins: Theme.pagePadding

        // ─────────────────────────────────────────────────────────
        // 标题
        // ─────────────────────────────────────────────────────────
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
                    text: "教学工具"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontH0
                    font.weight: Font.Bold
                }

                Text {
                    text: "高级计算器与函数图像，随手可用"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }

            ToolSegment {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 260
                height: 44
                currentIndex: page.mode
                labels: ["计算器", "函数图像"]
                onSelected: function(index) {
                    page.mode = index
                    if (index === page.modePlotter && page.hasPlot
                            && page.plotProgress < 1.0)
                        growthAnimation.restart()
                }
            }
        }

        StackLayout {
            id: toolStack

            anchors.top: header.bottom
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            currentIndex: page.mode

            // ─────────────────────────────────────────────────────
            // 计算器
            // ─────────────────────────────────────────────────────
            Item {
                Flickable {
                    id: calcFlick

                    anchors.fill: parent
                    clip: true
                    contentWidth: width
                    contentHeight: calcColumn.height + 16
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        width: 0
                        policy: ScrollBar.AlwaysOff
                    }

                    Column {
                        id: calcColumn

                        width: Math.min(400, calcFlick.width)
                        x: Math.max(0, (calcFlick.width - width) / 2)
                        y: 4
                        spacing: 12

                        // 显示屏
                        Rectangle {
                            width: parent.width
                            height: 120
                            radius: Theme.radiusCard
                            color: Theme.surface
                            border.width: 1
                            border.color: Theme.withAlpha(Theme.textPrimary, 0.05)

                            Column {
                                anchors.fill: parent
                                anchors.margins: 18
                                spacing: 6

                                Item {
                                    width: parent.width
                                    height: 22

                                    Text {
                                        anchors.fill: parent
                                        text: page.calcExpression.length > 0
                                              ? page.calcExpression : "支持括号、乘方、sin/cos、log/ln"
                                        horizontalAlignment: Text.AlignRight
                                        verticalAlignment: Text.AlignVCenter
                                        color: Theme.textTertiary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontCaption
                                        elide: Text.ElideLeft
                                    }
                                }

                                Text {
                                    width: parent.width
                                    height: parent.height - 28
                                    text: page.calcError.length > 0 ? page.calcError
                                                                    : page.calcResult
                                    horizontalAlignment: Text.AlignRight
                                    verticalAlignment: Text.AlignVCenter
                                    color: page.calcError.length > 0
                                           ? Theme.danger : Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: page.calcResult.length > 12 ? 24 : 34
                                    font.weight: Font.Bold
                                    elide: Text.ElideLeft
                                }
                            }
                        }

                        // 函数键
                        GridLayout {
                            width: parent.width
                            columns: 4
                            columnSpacing: 8
                            rowSpacing: 8

                            Repeater {
                                model: page.calcFunctions

                                delegate: CalcKey {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 44
                                    label: modelData.label
                                    compact: true
                                    onTriggered: page.pressCalcKey(modelData.action)
                                }
                            }
                        }

                        // 数字与运算符
                        GridLayout {
                            width: parent.width
                            columns: 4
                            columnSpacing: 8
                            rowSpacing: 8

                            Repeater {
                                model: page.calcKeys

                                delegate: CalcKey {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 54
                                    label: modelData.label
                                    accent: modelData.accent === true
                                    onTriggered: page.pressCalcKey(modelData.action)
                                }
                            }
                        }
                    }
                }
            }

            // ─────────────────────────────────────────────────────
            // 函数图像
            // ─────────────────────────────────────────────────────
            RowLayout {
                spacing: 16

                // 左侧：表达式与 AI
                Rectangle {
                    Layout.preferredWidth: 320
                    Layout.fillHeight: true
                    radius: Theme.radiusCard
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.textPrimary, 0.045)

                    Flickable {
                        id: plotPanelFlick

                        anchors.fill: parent
                        anchors.margins: 18
                        clip: true
                        contentWidth: width
                        contentHeight: plotPanel.height
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            width: 0
                            policy: ScrollBar.AlwaysOff
                        }

                        Column {
                            id: plotPanel

                            width: plotPanelFlick.width
                            spacing: 10

                            Text {
                                text: "函数表达式"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }

                            Text {
                                width: parent.width
                                text: "支持 y = f(x)、参数方程 x = ..., y = ... 以及隐式方程 F(x, y) = G(x, y)"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontMicro
                                wrapMode: Text.WordWrap
                                lineHeight: 1.3
                            }

                            TextArea {
                                id: plotField

                                width: parent.width
                                height: 104
                                text: page.plotText
                                selectByMouse: true
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                wrapMode: TextArea.WrapAnywhere
                                leftPadding: 12
                                rightPadding: 12
                                topPadding: 10
                                bottomPadding: 10

                                background: Rectangle {
                                    radius: Theme.radiusControl
                                    color: plotField.activeFocus ? Theme.surface : Theme.surfaceAlt
                                    border.width: 1
                                    border.color: plotField.activeFocus
                                                  ? Theme.primary
                                                  : Theme.withAlpha(Theme.textPrimary, 0.06)
                                }

                                onTextChanged: page.plotText = text
                            }

                            Row {
                                spacing: 8

                                ToolAction {
                                    width: 110
                                    height: 40
                                    primary: true
                                    text: "绘制"
                                    onClicked: page.drawPlot()
                                }

                                ToolAction {
                                    width: 84
                                    height: 40
                                    text: "清空"
                                    onClicked: {
                                        page.plotText = ""
                                        plotField.text = ""
                                        page.hasPlot = false
                                        page.plotPaths = []
                                        page.plotError = ""
                                        plotCanvas.requestPaint()
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                visible: page.plotError.length > 0
                                text: page.plotError
                                color: Theme.danger
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontCaption
                                wrapMode: Text.WordWrap
                            }

                            Flow {
                                width: parent.width
                                spacing: 6

                                Repeater {
                                    model: [
                                        { "label": "爱心", "turns": 1,
                                          "text": "x = 16sin^3(t), y = 13cos(t) - 5cos(2t) - 2cos(3t) - cos(4t)" },
                                        { "label": "方程爱心", "turns": 1,
                                          "text": "x^2 + (y - (x^2)^(1/3))^2 = 1" },
                                        { "label": "玫瑰线", "turns": 1,
                                          "text": "x = 10cos(3t)cos(t), y = 10cos(3t)sin(t)" },
                                        { "label": "蝴蝶曲线", "turns": 6,
                                          "text": "x = sin(t)(exp(cos(t)) - 2cos(4t) - sin(t/12)^5), y = cos(t)(exp(cos(t)) - 2cos(4t) - sin(t/12)^5)" },
                                        { "label": "阿基米德螺旋线", "turns": 3,
                                          "text": "x = t cos(t), y = t sin(t)" },
                                        { "label": "莫比乌斯环", "turns": 2,
                                          "text": "x = (1 + 0.6cos(t/2))cos(t), y = (1 + 0.6cos(t/2))sin(t) + 0.6sin(t/2)" },
                                        { "label": "抛物线", "turns": 1,
                                          "text": "y = x^2" },
                                        { "label": "正弦波", "turns": 1,
                                          "text": "y = sin(x)" },
                                        { "label": "圆", "turns": 1,
                                          "text": "x^2 + y^2 = 9" }
                                    ]

                                    delegate: Rectangle {
                                        width: presetLabel.implicitWidth + 20
                                        height: 26
                                        radius: 13
                                        color: presetMouse.containsMouse
                                               ? Theme.primarySoft : Theme.surfaceAlt
                                        border.width: 1
                                        border.color: Theme.withAlpha(Theme.textPrimary, 0.05)

                                        Text {
                                            id: presetLabel
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            color: Theme.primary
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontMicro
                                        }

                                        MouseArea {
                                            id: presetMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: page.applyPreset(modelData.text, modelData.turns)
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Theme.withAlpha(Theme.textPrimary, 0.06)
                            }

                            Text {
                                text: "AI 生成"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }

                            TextField {
                                id: aiField

                                width: parent.width
                                height: 42
                                text: page.aiPrompt
                                placeholderText: "画个爱心 / 画个抛物线"
                                placeholderTextColor: Theme.textTertiary
                                selectByMouse: true
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                leftPadding: 12

                                background: Rectangle {
                                    radius: Theme.radiusControl
                                    color: aiField.activeFocus ? Theme.surface : Theme.surfaceAlt
                                    border.width: 1
                                    border.color: aiField.activeFocus
                                                  ? Theme.primary
                                                  : Theme.withAlpha(Theme.textPrimary, 0.06)
                                }

                                onTextChanged: page.aiPrompt = text
                                onAccepted: page.generateByAI()
                            }

                            ToolAction {
                                width: parent.width
                                height: 40
                                primary: true
                                enabled: !page.aiBusy
                                text: page.aiBusy ? "生成中…" : "AI 生成函数"
                                onClicked: page.generateByAI()
                            }

                            Text {
                                width: parent.width
                                visible: page.aiStatus.length > 0
                                text: page.aiStatus
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontMicro
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                // 右侧：白底网格画布
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusCard
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.textPrimary, 0.045)
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: parent.radius - 1
                        color: Theme.white
                    }

                    Canvas {
                        id: plotCanvas

                        anchors.fill: parent
                        anchors.margins: 14

                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                        onVisibleChanged: if (visible) requestPaint()

                        Connections {
                            target: page

                            function onPlotProgressChanged() {
                                plotCanvas.requestPaint()
                            }

                            function onHasPlotChanged() {
                                plotCanvas.requestPaint()
                            }

                            function onPlotPathsChanged() {
                                plotCanvas.requestPaint()
                            }
                        }

                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.setTransform(1, 0, 0, 1, 0, 0)
                            ctx.clearRect(0, 0, width, height)
                            if (!page.hasPlot || width <= 0 || height <= 0)
                                return

                            var bounds = page.plotBounds
                            var spanX = bounds.xmax - bounds.xmin
                            var spanY = bounds.ymax - bounds.ymin
                            if (spanX <= 0 || spanY <= 0)
                                return

                            var scaleX = width / spanX
                            var scaleY = height / spanY
                            if (bounds.uniform)
                                scaleX = scaleY = Math.min(scaleX, scaleY)

                            var offsetX = (width - spanX * scaleX) / 2
                            var offsetY = (height - spanY * scaleY) / 2

                            function mapX(value) {
                                return offsetX + (value - bounds.xmin) * scaleX
                            }

                            function mapY(value) {
                                return offsetY + (bounds.ymax - value) * scaleY
                            }

                            // 网格步长取 1 / 2 / 5 × 10^n，保证格子数量适中
                            var rawStep = spanX / 9
                            var step = Math.pow(10, Math.floor(Math.log(rawStep) / Math.LN10))
                            var multiple = rawStep / step
                            if (multiple >= 5)
                                step *= 10
                            else if (multiple >= 2)
                                step *= 5
                            else if (multiple >= 1)
                                step *= 2

                            ctx.lineWidth = 1
                            ctx.strokeStyle = "#EEF1F4"
                            ctx.beginPath()
                            var startX = Math.ceil(bounds.xmin / step) * step
                            for (var gx = startX; gx <= bounds.xmax; gx += step) {
                                var px = mapX(gx)
                                ctx.moveTo(px, 0)
                                ctx.lineTo(px, height)
                            }
                            var startY = Math.ceil(bounds.ymin / step) * step
                            for (var gy = startY; gy <= bounds.ymax; gy += step) {
                                var py = mapY(gy)
                                ctx.moveTo(0, py)
                                ctx.lineTo(width, py)
                            }
                            ctx.stroke()

                            // 坐标轴
                            ctx.strokeStyle = "#CAD0D8"
                            ctx.lineWidth = 1.2
                            ctx.beginPath()
                            if (bounds.xmin <= 0 && bounds.xmax >= 0) {
                                var axisX = mapX(0)
                                ctx.moveTo(axisX, 0)
                                ctx.lineTo(axisX, height)
                            }
                            if (bounds.ymin <= 0 && bounds.ymax >= 0) {
                                var axisY = mapY(0)
                                ctx.moveTo(0, axisY)
                                ctx.lineTo(width, axisY)
                            }
                            ctx.stroke()

                            // 曲线：按进度逐个点生长
                            var paths = page.plotPaths
                            var limit = Math.max(1, Math.ceil(paths.length * page.plotProgress))
                            var tipX = 0
                            var tipY = 0
                            var hasTip = false

                            ctx.strokeStyle = String(Theme.primary)
                            ctx.lineWidth = 2
                            ctx.lineJoin = "round"
                            ctx.lineCap = "round"

                            if (paths.length > 1) {
                                // 等值线由大量短线段组成，全部累积在同一个 path 里一次 stroke
                                ctx.beginPath()
                                for (var p = 0; p < paths.length && p < limit; ++p) {
                                    var segment = paths[p]
                                    if (segment.length < 2)
                                        continue
                                    ctx.moveTo(mapX(segment[0][0]), mapY(segment[0][1]))
                                    ctx.lineTo(mapX(segment[1][0]), mapY(segment[1][1]))
                                    tipX = mapX(segment[1][0])
                                    tipY = mapY(segment[1][1])
                                    hasTip = true
                                }
                                ctx.stroke()
                            } else if (paths.length === 1) {
                                // 单条长路径按进度截断，视觉上像从起点一点点描出来
                                var path = paths[0]
                                var count = Math.max(2, Math.ceil(path.length * page.plotProgress))

                                ctx.beginPath()
                                ctx.moveTo(mapX(path[0][0]), mapY(path[0][1]))
                                for (var k = 1; k < count; ++k)
                                    ctx.lineTo(mapX(path[k][0]), mapY(path[k][1]))
                                ctx.stroke()

                                var last = path[count - 1]
                                tipX = mapX(last[0])
                                tipY = mapY(last[1])
                                hasTip = true
                            }

                            if (hasTip && page.plotProgress < 1.0) {
                                ctx.beginPath()
                                ctx.arc(tipX, tipY, 3.2, 0, Math.PI * 2)
                                ctx.fillStyle = String(Theme.primary)
                                ctx.fill()
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !page.hasPlot
                        text: "在左侧输入表达式后点击「绘制」"
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: 14
                        anchors.bottomMargin: 12
                        width: legendText.implicitWidth + 20
                        height: 24
                        radius: 12
                        color: Theme.withAlpha(Theme.white, 0.86)

                        Text {
                            id: legendText
                            anchors.centerIn: parent
                            text: "x ∈ [" + page.plotBounds.xmin.toFixed(1) + ", "
                                  + page.plotBounds.xmax.toFixed(1) + "]"
                            color: Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 文本 AI 未配置密钥：引导去设置页
    // ─────────────────────────────────────────────────────────────
    Dialog {
        id: keyDialog

        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: 400
        padding: 26

        background: Rectangle {
            radius: Theme.radiusDialog
            color: Theme.surface
            border.width: 1
            border.color: Theme.withAlpha(Theme.textPrimary, 0.06)
        }

        contentItem: Column {
            width: 348
            spacing: 14

            Text {
                width: parent.width
                text: "请前往设置配置 API Key"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontH2
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                text: "AI 生成函数使用你在设置页填写的文本 API Key，当前还没有配置。图片识别不占用这个 Key。"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.35
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                ToolAction {
                    width: 104
                    height: 40
                    text: "稍后"
                    onClicked: keyDialog.close()
                }

                ToolAction {
                    width: 124
                    height: 40
                    primary: true
                    text: "前往设置"
                    onClicked: {
                        keyDialog.close()
                        if (Window.window && typeof Window.window.navigate === "function")
                            Window.window.navigate(6)
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 顶部模式切换
    // ─────────────────────────────────────────────────────────────
    component ToolSegment: Item {
        id: control

        property int currentIndex: 0
        property var labels: ["计算器", "函数图像"]
        readonly property real segmentWidth: Math.max(0, (width - 8) / control.labels.length)
        signal selected(int index)

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Theme.surfaceAlt
            border.width: 1
            border.color: Theme.withAlpha(Theme.textPrimary, 0.035)
        }

        Rectangle {
            x: 4 + control.currentIndex * control.segmentWidth
            y: 4
            width: control.segmentWidth
            height: control.height - 8
            radius: height / 2
            color: Theme.surface

            Behavior on x {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }
        }

        Row {
            x: 4
            width: Math.max(0, control.width - 8)
            height: control.height

            Repeater {
                model: control.labels

                delegate: Item {
                    id: tabRoot

                    property bool hovered: false
                    property bool down: false

                    width: control.segmentWidth
                    height: control.height
                    scale: down ? 0.95 : (hovered ? 1.01 : 1.0)

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.durationFast
                            easing.type: Easing.OutCubic
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: control.currentIndex === index
                               ? Theme.primary
                               : (tabRoot.hovered ? Theme.textPrimary : Theme.textSecondary)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        font.weight: control.currentIndex === index
                                     ? Font.DemiBold
                                     : Font.Normal

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.durationFast
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: tabRoot.hovered = true
                        onExited: tabRoot.hovered = false
                        onPressedChanged: tabRoot.down = pressed
                        onClicked: {
                            if (control.currentIndex !== index)
                                control.selected(index)
                        }
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 计算器按键
    // ─────────────────────────────────────────────────────────────
    component CalcKey: Item {
        id: key

        property string label: ""
        property bool accent: false
        property bool compact: false
        signal triggered()

        implicitWidth: 88
        implicitHeight: 52
        scale: mouse.pressed ? 0.94 : (mouse.containsMouse ? 1.02 : 1.0)

        Behavior on scale {
            NumberAnimation {
                duration: Theme.durationFast
                easing.type: Easing.OutCubic
            }
        }

        transform: Translate {
            y: mouse.pressed ? 1 : 0

            Behavior on y {
                NumberAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: key.accent
                   ? (mouse.containsMouse ? Theme.primarySoftGreen : Theme.primarySoft)
                   : (mouse.containsMouse ? Theme.surfaceAlt : Theme.surface)
            border.width: 1
            border.color: key.accent
                          ? Theme.withAlpha(Theme.primary, 0.22)
                          : Theme.withAlpha(Theme.textPrimary, 0.06)

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: Theme.black
            opacity: mouse.pressed ? 0.07 : 0.0
            visible: opacity > 0.001

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: key.label
            color: key.accent ? Theme.primary : Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: key.compact ? 14 : 20
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: key.triggered()
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 操作按钮
    // ─────────────────────────────────────────────────────────────
    component ToolAction: Item {
        id: button

        property string text: ""
        property bool primary: false
        signal clicked()

        implicitWidth: 150
        implicitHeight: 44
        width: 150
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
            border.width: button.primary ? 0 : 1
            border.color: Theme.border
        }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: button.primary ? Theme.white : Theme.primarySoft
            opacity: mouse.containsMouse && button.enabled
                     ? (button.primary ? 0.10 : 0.55)
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
