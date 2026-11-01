import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Window

import ".."
import "../components"

/*!
    新建转盘页。
    - 白色圆角卡片表单，四周 32px 留白
    - 顶部“名单数据导入”区：CSV / TXT 与图片识别
    - 动态选项列表：可增删选项（2–200 个）
    - “保存并生成”后进入结果预览，可直接前往抽奖页
*/
Item {
    id: page

    anchors.fill: parent

    property bool generated: false
    property string createdName: ""
    property var createdOptions: []
    property string errorMessage: ""

    property bool ocrBusy: false
    property string ocrStatus: ""
    property string importMessage: ""
    property bool importFailed: false
    // 本次导入得到的名字：只追加到选项，是否进名单池由保存后的弹窗决定
    property var importedNames: []

    readonly property int maxOptions: 200
    readonly property int minOptions: 2

    // 持久化 / 商业化接入点：C++ 侧可连接此信号保存自定义转盘
    signal wheelCreated(string name, var options)

    function optionValue(index) {
        if (index < 0 || index >= optionModel.count)
            return ""
        return String(optionModel.get(index).text)
    }

    function sampleFor(index) {
        var samples = ["奶茶", "火锅", "烧烤", "日料", "麻辣烫", "炸鸡", "沙拉", "面条"]
        return samples[index % samples.length]
    }

    function addOption() {
        if (optionModel.count >= page.maxOptions) {
            page.errorMessage = "最多支持 " + page.maxOptions + " 个选项"
            return
        }

        optionModel.append({ "text": "" })
        page.errorMessage = ""

        Qt.callLater(function() {
            var item = optionRepeater.itemAt(optionModel.count - 1)
            if (item && item.field) {
                item.field.forceActiveFocus()
                var pos = item.mapToItem(formFlick.contentItem, 0, 0)
                var maxY = Math.max(0, formFlick.contentHeight - formFlick.height)
                formFlick.contentY = Math.max(0, Math.min(maxY, pos.y + item.height + 24
                                                         - formFlick.height))
            }
        })
    }

    function removeOption(index) {
        if (optionModel.count <= page.minOptions)
            return

        optionModel.remove(index)
        page.errorMessage = ""
    }

    function resetForm() {
        page.generated = false
        page.createdName = ""
        page.createdOptions = []
        page.errorMessage = ""
        page.importedNames = []
        page.importMessage = ""
        page.importFailed = false
        nameField.text = ""
        optionModel.clear()
        optionModel.append({ "text": "" })
        optionModel.append({ "text": "" })

        Qt.callLater(function() {
            nameField.forceActiveFocus()
        })
    }

    function appendNamesToOptions(names) {
        if (names === undefined || names === null)
            return 0

        var known = []
        for (var i = 0; i < optionModel.count; ++i) {
            var value = optionValue(i).trim()
            if (value.length > 0)
                known.push(value)
        }

        var added = 0
        for (var j = 0; j < names.length; ++j) {
            var name = String(names[j]).trim()
            if (name.length === 0 || known.indexOf(name) >= 0)
                continue
            if (optionModel.count >= page.maxOptions)
                break

            // 先填掉空白选项，再追加新行，避免留下一堆空输入框
            var filled = false
            for (var k = 0; k < optionModel.count; ++k) {
                if (optionValue(k).trim().length === 0) {
                    optionModel.setProperty(k, "text", name)
                    filled = true
                    break
                }
            }
            if (!filled)
                optionModel.append({ "text": name })

            known.push(name)
            added += 1

            if (page.importedNames.indexOf(name) < 0)
                page.importedNames = page.importedNames.concat([name])
        }

        return added
    }

    function saveWheel() {
        var name = nameField.text.trim()
        if (name.length === 0) {
            page.errorMessage = "先给转盘起个名字吧，例如「今天吃什么」"
            nameShake.restart()
            nameField.forceActiveFocus()
            return
        }

        var options = []
        for (var i = 0; i < optionModel.count; ++i) {
            var value = optionValue(i).trim()
            if (value.length === 0)
                continue

            if (options.indexOf(value) !== -1) {
                page.errorMessage = "「" + value + "」重复了，换一个吧"
                return
            }

            options.push(value)
        }

        if (options.length < page.minOptions) {
            page.errorMessage = "至少添加 " + page.minOptions + " 个选项，转盘才转得起来"
            return
        }

        page.createdName = name
        page.createdOptions = options
        page.errorMessage = ""
        page.generated = true
        page.wheelCreated(name, options)
        successReveal.restart()

        if (page.importedNames.length > 0)
            rosterDialog.open()
    }

    function goDraw() {
        if (Window.window && typeof Window.window.navigate === "function")
            Window.window.navigate(0)
    }

    function importRosterFile() {
        if (ocrBusy)
            return

        var path = backendBridge.chooseRosterFilePath()
        if (!path || path.length === 0)
            return

        var names = backendBridge.readNamesFromFile(path)
        importFailed = names.length === 0
        if (names.length === 0) {
            importMessage = "没有从文件里读到名字，请检查文件内容"
            return
        }

        importMessage = "已导入 " + appendNamesToOptions(names) + " 个名字到选项"
    }

    function startImageImport() {
        if (ocrBusy)
            return

        var path = backendBridge.chooseRosterImagePath()
        if (!path || path.length === 0)
            return

        importMessage = ""
        importFailed = false
        ocrBusy = true
        ocrStatus = "AI 正在分析数据结构..."
        backendBridge.aiManager.ocrFromImage(path)
    }

    onVisibleChanged: {
        if (visible && !generated) {
            Qt.callLater(function() {
                nameField.forceActiveFocus()
            })
        }
    }

    Connections {
        target: backendBridge.aiManager

        function onOcrProgress(message) {
            if (!page.ocrBusy)
                return
            page.ocrStatus = String(message)
        }

        function onOcrRosterReady(names) {
            page.ocrBusy = false
            page.ocrStatus = ""
            page.importFailed = false
            var added = page.appendNamesToOptions(names)
            page.importMessage = added > 0
                                 ? "已从图片识别 " + added + " 个名字，已追加到选项"
                                 : "识别到的名字已在选项中"
        }

        function onOcrFailed(message) {
            if (!page.ocrBusy)
                return
            page.ocrBusy = false
            page.ocrStatus = ""
            page.importFailed = true
            page.importMessage = String(message)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 页面骨架
    // ─────────────────────────────────────────────────────────────
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
                    text: "创建新转盘"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontH0
                    font.weight: Font.Bold
                }

                Text {
                    text: "为课堂、聚会或选择困难时刻，做一只专属签盘"
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

            // ── 表单态 ──
            Item {
                id: formLayer
                anchors.fill: parent
                visible: !page.generated
                opacity: visible ? 1.0 : 0.0

                Flickable {
                    id: formFlick
                    anchors.top: parent.top
                    anchors.topMargin: 28
                    anchors.left: parent.left
                    anchors.leftMargin: 32
                    anchors.right: parent.right
                    anchors.rightMargin: 24
                    anchors.bottom: actionBar.top
                    anchors.bottomMargin: 16
                    contentWidth: width
                    contentHeight: formColumn.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        width: 6
                        policy: formFlick.contentHeight > formFlick.height
                                ? ScrollBar.AsNeeded
                                : ScrollBar.AlwaysOff
                    }

                    Column {
                        id: formColumn
                        // 内容列再收窄 14px，删除按钮与右侧滚动条之间留出空隙
                        width: Math.max(0, formFlick.width - 14)
                        spacing: 0

                        // ── 名单数据导入 ──
                        Rectangle {
                            width: parent.width
                            height: importColumn.implicitHeight + 32
                            radius: 12
                            color: Theme.surfaceAlt
                            border.width: 1
                            border.color: Theme.withAlpha(Theme.textPrimary, 0.045)

                            Column {
                                id: importColumn

                                x: 16
                                y: 16
                                width: parent.width - 32
                                spacing: 10

                                Text {
                                    text: "名单数据导入"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    width: parent.width
                                    text: "导入 CSV / TXT，或让 AI 识别名单截图；识别结果会追加到下面的选项，不会直接改动名单池"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontCaption
                                    wrapMode: Text.WordWrap
                                }

                                Row {
                                    spacing: 10

                                    ImportButton {
                                        width: 124
                                        height: 38
                                        text: "导入到选项"
                                        primary: true
                                        enabled: !page.ocrBusy
                                        onClicked: page.importRosterFile()
                                    }

                                    ImportButton {
                                        width: 124
                                        height: 38
                                        text: page.ocrBusy ? "识别中…" : "图片导入"
                                        enabled: !page.ocrBusy
                                        onClicked: page.startImageImport()
                                    }
                                }

                                Text {
                                    width: parent.width
                                    visible: page.ocrBusy
                                    text: page.ocrStatus
                                    color: Theme.primary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontCaption
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    visible: !page.ocrBusy && page.importMessage.length > 0
                                    text: page.importMessage
                                    color: page.importFailed ? Theme.danger : Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontCaption
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        Item { width: 1; height: 24 }

                        Row {
                            spacing: 8

                            Text {
                                text: "转盘名称"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }

                            Rectangle {
                                width: 34
                                height: 20
                                radius: 6
                                color: Theme.primarySoft

                                Text {
                                    anchors.centerIn: parent
                                    text: "必填"
                                    color: Theme.primary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        Item { width: 1; height: 10 }

                        TextField {
                            id: nameField
                            width: parent.width
                            height: 50
                            leftPadding: 16
                            rightPadding: 16
                            placeholderText: "例如：今天吃什么"
                            placeholderTextColor: Theme.textTertiary
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            selectByMouse: true
                            maximumLength: 24

                            background: Rectangle {
                                radius: 10
                                color: nameField.activeFocus ? Theme.surface : Theme.surfaceAlt
                                border.width: nameField.activeFocus ? 1.5 : 1
                                border.color: nameField.activeFocus
                                              ? Theme.primary
                                              : Theme.border

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.durationFast
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: Theme.durationFast
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }

                            onTextEdited: page.errorMessage = ""
                        }

                        Item { width: 1; height: 24 }

                        RowLayout {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: "选项"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }

                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: optionCountText.implicitWidth + 18
                                Layout.preferredHeight: 22
                                width: optionCountText.implicitWidth + 18
                                height: 22
                                radius: 11
                                color: Theme.primarySoft

                                Text {
                                    id: optionCountText
                                    anchors.centerIn: parent
                                    text: optionModel.count + " / " + page.maxOptions
                                    color: Theme.primary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                text: "至少 " + page.minOptions + " 个，最多 " + page.maxOptions + " 个"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                            }
                        }

                        Item { width: 1; height: 12 }

                        Column {
                            id: optionList
                            width: parent.width
                            spacing: 10

                            Repeater {
                                id: optionRepeater
                                model: optionModel

                                delegate: Item {
                                    id: optionRow

                                    width: optionList.width
                                    height: 50

                                    property alias field: optionField

                                    Rectangle {
                                        id: indexBadge
                                        width: 28
                                        height: 28
                                        radius: 9
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: Theme.primarySoft

                                        Text {
                                            anchors.centerIn: parent
                                            text: index + 1
                                            color: Theme.primary
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    TextField {
                                        id: optionField
                                        anchors.left: indexBadge.right
                                        anchors.leftMargin: 10
                                        anchors.right: removeButton.left
                                        anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 46
                                        text: model.text
                                        placeholderText: "选项 " + (index + 1) + "，例如：" + page.sampleFor(index)
                                        placeholderTextColor: Theme.textTertiary
                                        color: Theme.textPrimary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontBody
                                        selectByMouse: true
                                        maximumLength: 16

                                        background: Rectangle {
                                            radius: 10
                                            color: optionField.activeFocus ? Theme.surface : Theme.surfaceAlt
                                            border.width: optionField.activeFocus ? 1.5 : 1
                                            border.color: optionField.activeFocus
                                                          ? Theme.primary
                                                          : Theme.border

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Theme.durationFast
                                                    easing.type: Easing.OutCubic
                                                }
                                            }

                                            Behavior on border.color {
                                                ColorAnimation {
                                                    duration: Theme.durationFast
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }

                                        onTextEdited: {
                                            optionModel.setProperty(index, "text", optionField.text)
                                            page.errorMessage = ""
                                        }
                                    }

                                    Item {
                                        id: removeButton
                                        width: optionModel.count > page.minOptions ? 32 : 0
                                        height: 32
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: optionModel.count > page.minOptions

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 9
                                            color: removeMouse.containsMouse
                                                   ? Theme.dangerSoft
                                                   : Theme.transparent

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Theme.durationFast
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }

                                        Canvas {
                                            width: 14
                                            height: 14
                                            anchors.centerIn: parent
                                            opacity: removeMouse.containsMouse ? 1.0 : 0.62
                                            onWidthChanged: requestPaint()
                                            onHeightChanged: requestPaint()
                                            Component.onCompleted: requestPaint()

                                            onPaint: {
                                                var ctx = getContext("2d")
                                                ctx.clearRect(0, 0, width, height)
                                                ctx.strokeStyle = removeMouse.containsMouse
                                                                 ? String(Theme.danger)
                                                                 : String(Theme.textSecondary)
                                                ctx.lineWidth = 1.5
                                                ctx.lineCap = "round"
                                                ctx.beginPath()
                                                ctx.moveTo(2.5, 2.5)
                                                ctx.lineTo(11.5, 11.5)
                                                ctx.moveTo(11.5, 2.5)
                                                ctx.lineTo(2.5, 11.5)
                                                ctx.stroke()
                                            }
                                        }

                                        MouseArea {
                                            id: removeMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: page.removeOption(index)
                                        }
                                    }
                                }
                            }
                        }

                        Item { width: 1; height: 12 }

                        Rectangle {
                            id: addButton
                            width: parent.width
                            height: 46
                            radius: 10
                            color: addMouse.containsMouse && optionModel.count < page.maxOptions
                                   ? Theme.primarySoft
                                   : Theme.surfaceAlt
                            border.width: 1
                            border.color: addMouse.containsMouse && optionModel.count < page.maxOptions
                                          ? Theme.withAlpha(Theme.primary, 0.30)
                                          : Theme.border
                            opacity: optionModel.count < page.maxOptions ? 1.0 : 0.55
                            scale: addMouse.pressed
                                   ? 0.95
                                   : (addMouse.containsMouse ? 1.01 : 1.0)

                            Behavior on color {
                                ColorAnimation {
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

                            Text {
                                anchors.centerIn: parent
                                text: optionModel.count < page.maxOptions
                                      ? "+ 添加选项"
                                      : "已达到 " + page.maxOptions + " 个选项上限"
                                color: optionModel.count < page.maxOptions
                                       ? Theme.primary
                                       : Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                id: addMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: optionModel.count < page.maxOptions
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: page.addOption()
                            }
                        }

                        Item { width: 1; height: 14 }

                        Text {
                            width: parent.width
                            text: page.errorMessage
                            visible: text.length > 0
                            color: Theme.danger
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                            wrapMode: Text.WordWrap
                        }

                        Item { width: 1; height: 4 }
                    }
                }

                Rectangle {
                    id: actionBar
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 88
                    color: Theme.surface

                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: Theme.divider
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 32
                        anchors.verticalCenter: parent.verticalCenter
                        text: "保存后会立即生成专属转盘"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                    }

                    PrimaryButton {
                        anchors.right: parent.right
                        anchors.rightMargin: 32
                        anchors.verticalCenter: parent.verticalCenter
                        width: 208
                        height: 50
                        text: "保存并生成"
                        onClicked: page.saveWheel()
                    }
                }
            }

            // ── 生成成功态 ──
            Item {
                id: successLayer
                anchors.fill: parent
                visible: page.generated
                opacity: 0.0

                Flickable {
                    id: successFlick
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: successColumn.height + 64
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AlwaysOff
                    }

                    Column {
                        id: successColumn
                        width: Math.max(0, Math.min(520, successFlick.width - 64))
                        x: (successFlick.width - width) / 2
                        y: 32
                        spacing: 0

                        Item {
                            width: parent.width
                            height: 60

                            Rectangle {
                                anchors.centerIn: parent
                                width: 60
                                height: 60
                                radius: 30
                                color: Theme.successSoft

                                Text {
                                    anchors.centerIn: parent
                                    text: "✓"
                                    color: Theme.success
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 26
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        Item { width: 1; height: 14 }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: "转盘创建成功"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 24
                            font.weight: Font.Bold
                        }

                        Item { width: 1; height: 6 }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: "「" + page.createdName + "」已经准备好了"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            elide: Text.ElideRight
                        }

                        Item { width: 1; height: 18 }

                        Item {
                            width: parent.width
                            height: 250

                            WheelPreview {
                                anchors.centerIn: parent
                                width: 240
                                height: 240
                                labels: page.createdOptions
                            }
                        }

                        Item { width: 1; height: 18 }

                        Text {
                            width: parent.width
                            text: "包含 " + page.createdOptions.length + " 个选项"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.DemiBold
                        }

                        Item { width: 1; height: 8 }

                        Flow {
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: page.createdOptions

                                delegate: Rectangle {
                                    height: 28
                                    width: optionChipText.implicitWidth + 20
                                    radius: 14
                                    color: Theme.surfaceAlt
                                    border.width: 1
                                    border.color: Theme.border

                                    Text {
                                        id: optionChipText
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: Theme.textPrimary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontCaption
                                    }
                                }
                            }
                        }

                        Item { width: 1; height: 24 }

                        Item {
                            width: parent.width
                            height: 48

                            Row {
                                anchors.centerIn: parent
                                spacing: 12

                                GhostButton {
                                    width: 118
                                    height: 48
                                    text: "再建一个"
                                    onClicked: page.resetForm()
                                }

                                PrimaryButton {
                                    width: 156
                                    height: 48
                                    text: "去抽奖"
                                    onClicked: page.goDraw()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 保存后询问：导入的名字是否同时进名单池
    // ─────────────────────────────────────────────────────────────
    Dialog {
        id: rosterDialog

        property bool addToRoster: true

        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: 400
        padding: 24

        background: Rectangle {
            radius: Theme.radiusCard
            color: Theme.surface

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.withAlpha(Theme.textPrimary, 0.18)
                shadowBlur: 0.65
                shadowVerticalOffset: 12
                shadowHorizontalOffset: 0
                autoPaddingEnabled: true
            }
        }

        contentItem: Column {
            width: 352
            spacing: 14

            Text {
                width: parent.width
                text: "转盘「" + page.createdName + "」已保存"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontH2
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: "还有 " + page.importedNames.length + " 个导入的名字，要一起放进抽奖名单池吗？"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                wrapMode: Text.WordWrap
                lineHeight: 1.35
            }

            Rectangle {
                width: parent.width
                height: 46
                radius: 10
                color: rosterCheckMouse.containsMouse ? Theme.primarySoft : Theme.surfaceAlt
                border.width: 1
                border.color: rosterDialog.addToRoster
                              ? Theme.withAlpha(Theme.primary, 0.32)
                              : Theme.withAlpha(Theme.textPrimary, 0.05)

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Rectangle {
                        width: 20
                        height: 20
                        radius: 6
                        color: rosterDialog.addToRoster ? Theme.primary : Theme.surface
                        border.width: 1
                        border.color: rosterDialog.addToRoster
                                      ? Theme.primary
                                      : Theme.withAlpha(Theme.textPrimary, 0.18)

                        Text {
                            anchors.centerIn: parent
                            visible: rosterDialog.addToRoster
                            text: "✓"
                            color: Theme.white
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }
                    }

                    Text {
                        text: "同时将这些名字加入抽奖名单池"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                    }
                }

                MouseArea {
                    id: rosterCheckMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rosterDialog.addToRoster = !rosterDialog.addToRoster
                }
            }

            Item {
                width: parent.width
                height: 40

                Row {
                    anchors.right: parent.right
                    height: parent.height
                    spacing: 10

                    ImportButton {
                        width: 92
                        height: 40
                        text: "暂不"
                        onClicked: rosterDialog.reject()
                    }

                    ImportButton {
                        width: 104
                        height: 40
                        text: "确定"
                        primary: true
                        onClicked: rosterDialog.accept()
                    }
                }
            }
        }

        onOpened: addToRoster = true

        onAccepted: {
            if (addToRoster)
                backendBridge.appendNamesToRoster(page.importedNames)
            page.importedNames = []
        }

        onRejected: page.importedNames = []
    }

    // ─────────────────────────────────────────────────────────────
    // 数据模型 + 动效
    // ─────────────────────────────────────────────────────────────
    ListModel {
        id: optionModel

        ListElement { text: "" }
        ListElement { text: "" }
    }

    SequentialAnimation {
        id: nameShake

        NumberAnimation {
            target: nameField
            property: "x"
            to: -6
            duration: 50
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: nameField
            property: "x"
            to: 6
            duration: 70
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: nameField
            property: "x"
            to: -4
            duration: 60
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: nameField
            property: "x"
            to: 0
            duration: 60
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: successReveal

        NumberAnimation {
            target: successLayer
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: 260
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: successColumn
            property: "y"
            from: 42
            to: 32
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 导入区按钮
    // ─────────────────────────────────────────────────────────────
    component ImportButton: Item {
        id: button

        property string text: ""
        property bool primary: false
        signal clicked()

        width: 124
        height: 38
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
            font.pixelSize: Theme.fontCaption
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

    // ─────────────────────────────────────────────────────────────
    // 主按钮
    // ─────────────────────────────────────────────────────────────
    component PrimaryButton: Item {
        id: button

        property string text: "保存并生成"
        signal clicked()

        width: 208
        height: 50
        enabled: true
        opacity: enabled ? 1.0 : 0.45
        scale: mouse.pressed ? 0.95 : (mouse.containsMouse ? 1.02 : 1.0)

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.durationNormal
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
            id: bodyShadow
            anchors.fill: parent
            radius: height / 2
            gradient: Theme.primaryGradient
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.withAlpha(Theme.primary, 0.30)
                shadowBlur: 0.65
                shadowVerticalOffset: 7
                shadowHorizontalOffset: 0
                autoPaddingEnabled: true
            }
        }

        Rectangle {
            id: body
            anchors.fill: parent
            radius: height / 2
            gradient: Theme.primaryGradient
            border.width: 1
            border.color: Theme.withAlpha(Theme.white, 0.18)
        }

        Rectangle {
            anchors.fill: body
            radius: body.radius
            color: Theme.white
            opacity: mouse.containsMouse ? 0.10 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            anchors.fill: body
            radius: body.radius
            color: Theme.black
            opacity: mouse.pressed ? 0.06 : 0.0

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
            color: Theme.white
            font.family: Theme.fontFamily
            font.pixelSize: 15
            font.weight: Font.DemiBold
            font.letterSpacing: 1.2
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

    component GhostButton: Item {
        id: button

        property string text: ""
        signal clicked()

        width: 118
        height: 48
        scale: mouse.pressed ? 0.95 : (mouse.containsMouse ? 1.02 : 1.0)

        Behavior on scale {
            NumberAnimation {
                duration: Theme.durationFast
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: mouse.containsMouse ? Theme.surfaceAlt : Theme.surface
            border.width: 1
            border.color: mouse.containsMouse
                          ? Theme.withAlpha(Theme.primary, 0.22)
                          : Theme.border

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: button.text
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontCaption
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 生成结果里的小转盘预览
    // ─────────────────────────────────────────────────────────────
    component WheelPreview: Item {
        id: preview

        property var labels: []

        onLabelsChanged: previewCanvas.requestPaint()

        Canvas {
            id: previewCanvas
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
                var radius = Math.min(width, height) / 2 - 12
                var labels = preview.labels || []
                var count = Math.max(1, labels.length)
                var step = Math.PI * 2 / count
                var start = -Math.PI / 2

                var colors = [
                    String(Theme.wheelSectorA),
                    String(Theme.wheelSectorB),
                    String(Theme.wheelSectorC),
                    String(Theme.wheelSectorD)
                ]

                // 外圈柔光
                var halo = ctx.createRadialGradient(cx, cy, Math.max(0, radius - 14),
                                                    cx, cy, radius + 8)
                halo.addColorStop(0, "rgba(59,139,246,0)")
                halo.addColorStop(0.72, "rgba(59,139,246,0.055)")
                halo.addColorStop(1, "rgba(46,212,165,0)")
                ctx.fillStyle = halo
                ctx.beginPath()
                ctx.arc(cx, cy, radius + 8, 0, Math.PI * 2)
                ctx.fill()

                for (var i = 0; i < count; ++i) {
                    ctx.beginPath()
                    ctx.moveTo(cx, cy)
                    ctx.arc(cx, cy, radius,
                            start + i * step,
                            start + (i + 1) * step)
                    ctx.closePath()
                    ctx.fillStyle = colors[i % colors.length]
                    ctx.fill()
                    ctx.strokeStyle = "#FFFFFF"
                    ctx.lineWidth = 2
                    ctx.stroke()

                    if (labels.length === 0)
                        continue

                    var mid = start + (i + 0.5) * step
                    var labelRadius = radius * 0.64
                    var lx = cx + Math.cos(mid) * labelRadius
                    var ly = cy + Math.sin(mid) * labelRadius
                    var label = String(labels[i])
                    if (label.length > 6)
                        label = label.substring(0, 6) + "…"

                    ctx.font = "600 12px '" + Theme.fontFamily + "'"
                    ctx.fillStyle = String(Theme.wheelText)
                    ctx.shadowColor = "rgba(15,23,42,0.55)"
                    ctx.shadowBlur = 3
                    ctx.shadowOffsetY = 1.5
                    ctx.textAlign = "center"
                    ctx.textBaseline = "middle"
                    ctx.fillText(label, lx, ly, radius * 0.52)
                }

                ctx.shadowColor = "transparent"
                ctx.shadowBlur = 0
                ctx.shadowOffsetY = 0
                ctx.strokeStyle = "rgba(255,255,255,0.92)"
                ctx.lineWidth = 5
                ctx.beginPath()
                ctx.arc(cx, cy, radius, 0, Math.PI * 2)
                ctx.stroke()
            }
        }

        // 中心轴
        Rectangle {
            width: 54
            height: 54
            radius: 27
            anchors.centerIn: parent
            color: Theme.surface
            border.width: 1
            border.color: Theme.withAlpha(Theme.textPrimary, 0.06)

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.shadowColorStrong
                shadowBlur: 0.55
                shadowVerticalOffset: 4
                shadowHorizontalOffset: 0
                autoPaddingEnabled: true
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 5
                radius: width / 2
                gradient: Theme.primaryGradient
                border.width: 1
                border.color: Theme.withAlpha(Theme.white, 0.35)

                Text {
                    anchors.centerIn: parent
                    text: "签"
                    color: Theme.white
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.Bold
                }
            }
        }

        // 顶部指针
        Canvas {
            width: 24
            height: 30
            anchors.horizontalCenter: parent.horizontalCenter
            y: 4

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var fill = ctx.createLinearGradient(0, 0, 0, height)
                fill.addColorStop(0, String(Theme.primary))
                fill.addColorStop(1, String(Theme.primaryEnd))

                ctx.fillStyle = fill
                ctx.shadowColor = "rgba(31,35,41,0.18)"
                ctx.shadowBlur = 6
                ctx.shadowOffsetY = 3

                ctx.beginPath()
                ctx.moveTo(width / 2, height - 2)
                ctx.lineTo(3, 3)
                ctx.quadraticCurveTo(width / 2, -2, width - 3, 3)
                ctx.closePath()
                ctx.fill()

                ctx.shadowBlur = 0
                ctx.shadowColor = "transparent"

                ctx.strokeStyle = "rgba(255,255,255,0.55)"
                ctx.lineWidth = 1
                ctx.stroke()
            }
        }
    }
}
