import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Window

import ".."
import "../components"

/*!
    全局设置页。
    iOS 设置页结构：大标题 + 分组卡片，卡片内用极细分割线隔开每一项；
    音效与动效使用 iOS 开关，数据管理收在同一张卡片里。
*/
Item {
    id: page

    anchors.fill: parent

    property string pendingRestorePath: ""
    property string developerError: ""
    readonly property string developerPassword: "LuvXcm080511"

    function reloadAIConfig() {
        var config = backendBridge.getAIConfig()
        // 留空的项不写回输入框，让 placeholder 展示内置默认值
        apiKeyRow.text = config && config.apiKey !== undefined ? String(config.apiKey) : ""
        apiBaseRow.text = config && config.baseUrl !== undefined ? String(config.baseUrl) : ""
        modelRow.text = config && config.model !== undefined ? String(config.model) : ""
    }

    function showToast(message) {
        toast.show(message)
    }

    function openDeveloperConsole() {
        developerError = ""
        passwordField.text = ""
        developerDialog.open()
        Qt.callLater(function() {
            passwordField.forceActiveFocus()
        })
    }

    function confirmDeveloperPassword() {
        if (passwordField.text !== developerPassword) {
            developerError = "密码不对，再想想"
            passwordField.text = ""
            passwordField.forceActiveFocus()
            return
        }

        developerDialog.close()
        if (Window.window && typeof Window.window.navigate === "function")
            Window.window.navigate(7)
    }

    function saveAIConfig() {
        backendBridge.saveAIConfig(apiKeyRow.text, apiBaseRow.text, modelRow.text)
        page.showToast("配置已保存")
    }

    Component.onCompleted: reloadAIConfig()

    Connections {
        target: backendBridge

        function onAiConfigChanged() {
            page.reloadAIConfig()
        }
    }

    Item {
        id: pageContent
        anchors.fill: parent
        anchors.margins: Theme.pagePadding

        // ─────────────────────────────────────────────────────────
        // iOS 大标题
        // ─────────────────────────────────────────────────────────
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
                    text: "设置"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLargeTitle
                    font.weight: Font.Bold
                }

                Text {
                    text: "让撷签更贴合你的课堂习惯"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }
        }

        Flickable {
            id: flick

            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            contentWidth: width
            contentHeight: settingsColumn.height + 8
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 2600

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOff
            }

            Column {
                id: settingsColumn

                width: flick.width
                spacing: 0

                GroupLabel { text: "偏好设置" }

                Rectangle {
                    width: parent.width
                    height: preferenceColumn.height
                    radius: Theme.radiusCard
                    color: Theme.surface

                    CardShadow {}

                    Column {
                        id: preferenceColumn
                        width: parent.width

                        Item {
                            width: parent.width
                            height: 64

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.cardPadding
                                anchors.right: soundSwitch.left
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3

                                Text {
                                    text: "音效"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                }

                                Text {
                                    width: parent.width
                                    text: "抽取与揭晓时播放提示音"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontCaption
                                    elide: Text.ElideRight
                                }
                            }

                            IosSwitch {
                                id: soundSwitch
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.cardPadding
                                anchors.verticalCenter: parent.verticalCenter
                                checked: backendBridge.soundEnabled
                                onToggled: function(value) {
                                    backendBridge.soundEnabled = value
                                }
                            }
                        }

                        Sep {}

                        Item {
                            width: parent.width
                            height: 64

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.cardPadding
                                anchors.right: motionSwitch.left
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3

                                Text {
                                    text: "动效"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                }

                                Text {
                                    width: parent.width
                                    text: "转盘旋转与揭晓的完整动画"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontCaption
                                    elide: Text.ElideRight
                                }
                            }

                            IosSwitch {
                                id: motionSwitch
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.cardPadding
                                anchors.verticalCenter: parent.verticalCenter
                                checked: backendBridge.motionEnabled
                                onToggled: function(value) {
                                    backendBridge.motionEnabled = value
                                }
                            }
                        }
                    }
                }

                GroupLabel {
                    text: "AI 配置"
                    topPadding: 22
                }

                Rectangle {
                    width: parent.width
                    height: aiColumn.height
                    radius: Theme.radiusCard
                    color: Theme.surface

                    CardShadow {}

                    Column {
                        id: aiColumn
                        width: parent.width

                        Item {
                            width: parent.width
                            height: 68

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.cardPadding
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.cardPadding
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3

                                Text {
                                    text: "接口配置"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    width: parent.width
                                    text: "高级计算、函数解析与颁奖词会用到这里的 Key"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontCaption
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        Sep {}

                        FieldRow {
                            id: apiKeyRow
                            label: "API Key"
                            placeholder: "sk-..."
                            password: true
                            maximumLength: 256
                        }

                        Sep {}

                        FieldRow {
                            id: apiBaseRow
                            label: "Base URL"
                            placeholder: "https://api.deepseek.com"
                            smallFont: true
                            maximumLength: 512
                        }

                        Sep {}

                        FieldRow {
                            id: modelRow
                            label: "模型"
                            placeholder: "deepseek-flash"
                            maximumLength: 128
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 14
                }

                MainButton {
                    width: parent.width
                    height: Theme.buttonHeight
                    label: "保存 AI 配置"
                    onClicked: page.saveAIConfig()
                }

                GroupLabel {
                    text: "数据管理"
                    topPadding: 22
                }

                Rectangle {
                    width: parent.width
                    height: dataColumn.height
                    radius: Theme.radiusCard
                    color: Theme.surface

                    CardShadow {}

                    Column {
                        id: dataColumn
                        width: parent.width

                        ActionRow {
                            title: "备份数据"
                            subtitle: "把名单、历史与设置导出为 JSON"
                            actionLabel: "备份"
                            onTriggered: {
                                var path = backendBridge.chooseBackupPath()
                                if (path && path.length > 0) {
                                    backendBridge.exportData(path)
                                    page.showToast("备份已导出")
                                }
                            }
                        }

                        Sep {}

                        ActionRow {
                            title: "恢复数据"
                            subtitle: "从 JSON 备份还原全部内容"
                            actionLabel: "恢复"
                            onTriggered: {
                                var path = backendBridge.chooseRestorePath()
                                if (path && path.length > 0) {
                                    page.pendingRestorePath = path
                                    restoreDialog.open()
                                }
                            }
                        }

                        Sep {}

                        ActionRow {
                            title: "抹除全部记录"
                            subtitle: "名单与历史会一起消失，且不可撤销"
                            actionLabel: "抹除"
                            destructive: true
                            onTriggered: clearDialog.open()
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 26
                }

                // 隐藏入口：不显眼的小字，点开后需要输入密码
                Item {
                    width: parent.width
                    height: 30

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "开发者选项"
                        color: Theme.withAlpha(Theme.textTertiary, 0.55)
                        font.family: Theme.fontFamily
                        font.pixelSize: 10

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.openDeveloperConsole()
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 16
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 开发者验证：320 宽 iOS 弹窗
    // ─────────────────────────────────────────────────────────────
    Dialog {
        id: developerDialog

        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: 320
        // 固定高度：弹窗里不随输入状态跳动，和 iOS 警示框一致
        height: 237
        padding: 0

        background: Rectangle {
            radius: Theme.radiusDialog
            color: Theme.surface

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.withAlpha(Theme.textPrimary, 0.22)
                shadowBlur: 0.7
                shadowVerticalOffset: 16
                shadowHorizontalOffset: 0
                autoPaddingEnabled: true
            }
        }

        contentItem: Column {
            width: 320

            Item {
                width: parent.width
                height: 190

                Column {
                    id: dialogBody

                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    anchors.topMargin: 22
                    anchors.bottomMargin: 14
                    spacing: 10

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "开发者验证"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "输入密码后进入权重控制台"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontCaption
                    }

                    // 自定义密码框：浅灰圆角底，靠大字号与字距把系统圆点撑开
                    TextField {
                        id: passwordField

                        width: parent.width
                        height: 48
                        leftPadding: 14
                        rightPadding: 14
                        horizontalAlignment: TextInput.AlignHCenter
                        placeholderText: "密码"
                        placeholderTextColor: Theme.textTertiary
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        selectByMouse: true
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 21
                        font.letterSpacing: 6
                        maximumLength: 64

                        background: Rectangle {
                            radius: 12
                            color: Theme.fill
                            border.width: passwordField.activeFocus ? 1 : 0
                            border.color: Theme.primary
                        }

                        onAccepted: page.confirmDeveloperPassword()
                    }

                    Text {
                        width: parent.width
                        height: 16
                        visible: page.developerError.length > 0
                        text: page.developerError
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.danger
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontCaption
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.separator
            }

            Row {
                width: parent.width
                height: 46

                AlertButton {
                    width: parent.width / 2
                    height: parent.height
                    label: "取消"
                    onClicked: developerDialog.close()
                }

                Rectangle {
                    width: 1
                    height: parent.height
                    color: Theme.separator
                }

                AlertButton {
                    width: parent.width / 2 - 1
                    height: parent.height
                    label: "进入"
                    strong: true
                    onClicked: page.confirmDeveloperPassword()
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 轻量 Toast
    // ─────────────────────────────────────────────────────────────
    Rectangle {
        id: toast

        property string message: ""

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        width: toastText.implicitWidth + 40
        height: 40
        radius: 20
        color: Theme.withAlpha(Theme.textPrimary, 0.9)
        opacity: 0.0
        visible: opacity > 0
        z: 100

        Text {
            id: toastText
            anchors.centerIn: parent
            text: toast.message
            color: Theme.white
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontCaption
            font.weight: Font.DemiBold
        }

        function show(text) {
            message = text
            toastAnimation.restart()
        }

        SequentialAnimation {
            id: toastAnimation

            NumberAnimation {
                target: toast
                property: "opacity"
                to: 1.0
                duration: 160
                easing.type: Easing.OutCubic
            }

            PauseAnimation { duration: 1600 }

            NumberAnimation {
                target: toast
                property: "opacity"
                to: 0.0
                duration: 260
                easing.type: Easing.OutCubic
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 恢复确认
    // ─────────────────────────────────────────────────────────────
    Dialog {
        id: restoreDialog

        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: 340
        height: 203
        padding: 0

        background: Rectangle {
            radius: Theme.radiusDialog
            color: Theme.surface

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.withAlpha(Theme.textPrimary, 0.22)
                shadowBlur: 0.7
                shadowVerticalOffset: 16
                shadowHorizontalOffset: 0
                autoPaddingEnabled: true
            }
        }

        contentItem: Column {
            width: 340

            Item {
                width: parent.width
                height: 156

                Column {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    anchors.topMargin: 24
                    anchors.bottomMargin: 16
                    spacing: 10

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "恢复这份备份？"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "当前的名单、历史与设置会被整份覆盖。"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontCaption
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.separator
            }

            Row {
                width: parent.width
                height: 46

                AlertButton {
                    width: parent.width / 2
                    height: parent.height
                    label: "取消"
                    onClicked: restoreDialog.close()
                }

                Rectangle {
                    width: 1
                    height: parent.height
                    color: Theme.separator
                }

                AlertButton {
                    width: parent.width / 2 - 1
                    height: parent.height
                    label: "恢复"
                    strong: true
                    onClicked: {
                        backendBridge.importData(page.pendingRestorePath)
                        restoreDialog.close()
                        page.showToast("已恢复备份")
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 抹除确认
    // ─────────────────────────────────────────────────────────────
    Dialog {
        id: clearDialog

        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: 340
        height: 203
        padding: 0

        background: Rectangle {
            radius: Theme.radiusDialog
            color: Theme.surface

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.withAlpha(Theme.textPrimary, 0.22)
                shadowBlur: 0.7
                shadowVerticalOffset: 16
                shadowHorizontalOffset: 0
                autoPaddingEnabled: true
            }
        }

        contentItem: Column {
            width: 340

            Item {
                width: parent.width
                height: 156

                Column {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    anchors.topMargin: 24
                    anchors.bottomMargin: 16
                    spacing: 10

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "抹除全部记录？"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "名单与抽取历史会被永久删除，无法找回。"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontCaption
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.separator
            }

            Row {
                width: parent.width
                height: 46

                AlertButton {
                    width: parent.width / 2
                    height: parent.height
                    label: "取消"
                    onClicked: clearDialog.close()
                }

                Rectangle {
                    width: 1
                    height: parent.height
                    color: Theme.separator
                }

                AlertButton {
                    width: parent.width / 2 - 1
                    height: parent.height
                    label: "抹除"
                    destructive: true
                    onClicked: {
                        backendBridge.clearAllData()
                        clearDialog.close()
                        page.showToast("记录已抹除")
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 分组标题
    // ─────────────────────────────────────────────────────────────
    component GroupLabel: Text {
        width: parent ? parent.width : 0
        leftPadding: 4
        topPadding: 8
        bottomPadding: 7
        color: Theme.textTertiary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontCaption
    }

    // ─────────────────────────────────────────────────────────────
    // 卡片内分割线：左侧留白，不顶到卡片边缘
    // ─────────────────────────────────────────────────────────────
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

    // ─────────────────────────────────────────────────────────────
    // 开关行
    // ─────────────────────────────────────────────────────────────
    // 输入行：左侧标题，右侧浅灰圆角输入框
    // ─────────────────────────────────────────────────────────────
    component FieldRow: Item {
        id: row

        width: parent ? parent.width : 0
        height: 60

        property string label: ""
        property string placeholder: ""
        property bool password: false
        property bool smallFont: false
        property int maximumLength: 256
        property alias text: fieldInput.text

        Text {
            anchors.left: parent.left
            anchors.leftMargin: Theme.cardPadding
            anchors.verticalCenter: parent.verticalCenter
            text: row.label
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
        }

        TextField {
            id: fieldInput

            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(300, Math.max(120, row.width * 0.56))
            height: 38
            leftPadding: 12
            rightPadding: 12
            placeholderText: row.placeholder
            placeholderTextColor: Theme.textTertiary
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: row.smallFont ? Theme.fontCaption : Theme.fontBody
            horizontalAlignment: TextInput.AlignRight
            selectByMouse: true
            echoMode: row.password ? TextInput.Password : TextInput.Normal
            maximumLength: row.maximumLength

            background: Rectangle {
                radius: 10
                color: Theme.fill
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 操作行：标题 + 右侧文字按钮
    // ─────────────────────────────────────────────────────────────
    component ActionRow: Item {
        id: row

        width: parent ? parent.width : 0
        height: 62

        property string title: ""
        property string subtitle: ""
        property string actionLabel: ""
        property bool destructive: false
        signal triggered()

        Column {
            anchors.left: parent.left
            anchors.leftMargin: Theme.cardPadding
            anchors.right: linkText.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                width: parent.width
                text: row.title
                color: row.destructive ? Theme.danger : Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: row.subtitle
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontCaption
                elide: Text.ElideRight
            }
        }

        Text {
            id: linkText

            anchors.right: parent.right
            anchors.rightMargin: Theme.cardPadding
            anchors.verticalCenter: parent.verticalCenter
            text: row.actionLabel
            color: row.destructive ? Theme.danger : Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            opacity: rowMouse.pressed ? 0.55 : 1.0

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }
        }

        MouseArea {
            id: rowMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.triggered()
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 主按钮：品牌渐变、14px 圆角、按下回弹
    // ─────────────────────────────────────────────────────────────
    component MainButton: Item {
        id: button

        property string label: ""
        signal clicked()

        scale: mouse.pressed ? 0.96 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: Theme.durationFast
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            id: buttonShadow

            anchors.fill: parent
            radius: Theme.radiusButton
            gradient: Theme.primaryGradient

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.withAlpha(Theme.primary, 0.28)
                shadowBlur: 0.6
                shadowVerticalOffset: 6
                shadowHorizontalOffset: 0
                autoPaddingEnabled: true
            }
        }

        Rectangle {
            id: buttonBody

            anchors.fill: parent
            radius: Theme.radiusButton
            gradient: Theme.primaryGradient
            border.width: 1
            border.color: Theme.withAlpha(Theme.white, 0.18)
        }

        Text {
            anchors.centerIn: parent
            text: button.label
            color: Theme.white
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontH2
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
    // 弹窗按钮：iOS 警示框里的左右并排文字按钮
    // ─────────────────────────────────────────────────────────────
    component AlertButton: Item {
        id: button

        property string label: ""
        property bool strong: false
        property bool destructive: false
        signal clicked()

        Rectangle {
            anchors.fill: parent
            color: mouse.pressed
                   ? Theme.fill
                   : (mouse.containsMouse ? Theme.surfaceHover : Theme.transparent)

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: button.label
            color: button.destructive
                   ? Theme.danger
                   : (button.strong ? Theme.primary : Theme.textPrimary)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            font.weight: button.strong || button.destructive ? Font.DemiBold : Font.Normal
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}
