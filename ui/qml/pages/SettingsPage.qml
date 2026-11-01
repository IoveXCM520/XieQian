import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Window

import ".."
import "../components"

/*!
    全局设置页。
    - 音效、动效 iOS 风格滑动开关
    - 备份 / 恢复 / 清空数据
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
        apiKeyField.text = config && config.apiKey !== undefined ? String(config.apiKey) : ""
        apiBaseField.text = config && config.baseUrl !== undefined ? String(config.baseUrl) : ""
        modelField.text = config && config.model !== undefined ? String(config.model) : ""
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
                    text: "设置"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontH0
                    font.weight: Font.Bold
                }

                Text {
                    text: "让撷签更符合你的课堂习惯"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }
        }

        Flickable {
            id: flick

            anchors.top: header.bottom
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            contentWidth: width
            contentHeight: settingsColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOff
            }

            ColumnLayout {
                id: settingsColumn

                width: flick.width
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "偏好设置"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.DemiBold
                    topPadding: 4
                    bottomPadding: 2
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    radius: Theme.radiusListCard
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.textPrimary, 0.045)

                    CardShadow {}

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 16

                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4

                            Text {
                                text: "音效"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "抽取与中签时播放提示音"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                            }
                        }

                        IosSwitch {
                            Layout.alignment: Qt.AlignVCenter
                            checked: backendBridge.soundEnabled
                            onToggled: function(value) {
                                backendBridge.soundEnabled = value
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    radius: Theme.radiusListCard
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.textPrimary, 0.045)

                    CardShadow {}

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 16

                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4

                            Text {
                                text: "动效"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "转盘旋转与揭晓的完整动画"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                            }
                        }

                        IosSwitch {
                            Layout.alignment: Qt.AlignVCenter
                            checked: backendBridge.motionEnabled
                            onToggled: function(value) {
                                backendBridge.motionEnabled = value
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "AI 助手配置"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.DemiBold
                    topPadding: 14
                    bottomPadding: 2
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: aiColumn.implicitHeight + 40
                    radius: Theme.radiusListCard
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.textPrimary, 0.045)

                    CardShadow {}

                    Column {
                        id: aiColumn

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 20
                        spacing: 12

                        RowLayout {
                            width: parent.width
                            spacing: 12

                            Column {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: "接口配置"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    width: parent.width
                                    text: "* 此处的 API 用于高级计算器、函数解析及颁奖词生成。图片导入功能的 AI 识别使用独立内置通道，不消耗您此处的 Key。"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontMicro
                                    wrapMode: Text.WordWrap
                                    lineHeight: 1.3
                                }
                            }

                            Rectangle {
                                Layout.alignment: Qt.AlignTop
                                Layout.preferredWidth: builtinChipText.implicitWidth + 18
                                Layout.preferredHeight: 24
                                radius: 12
                                color: Theme.successSoft

                                Text {
                                    id: builtinChipText
                                    anchors.centerIn: parent
                                    text: "OCR 内置通道"
                                    color: Theme.success
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.withAlpha(Theme.textPrimary, 0.045)
                        }

                        Row {
                            width: parent.width
                            height: 18

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "API Key"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: "文本 AI 必填"
                                color: Theme.textTertiary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontMicro
                            }
                        }

                        TextField {
                            id: apiKeyField

                            width: parent.width
                            height: 44
                            leftPadding: 14
                            rightPadding: 14
                            placeholderText: "sk-..."
                            placeholderTextColor: Theme.textTertiary
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            selectByMouse: true
                            echoMode: TextInput.Password
                            maximumLength: 256

                            background: Rectangle {
                                radius: Theme.radiusControl
                                color: apiKeyField.activeFocus ? Theme.surface : Theme.surfaceAlt
                                border.width: 1
                                border.color: apiKeyField.activeFocus
                                              ? Theme.primary
                                              : Theme.withAlpha(Theme.textPrimary, 0.06)
                            }
                        }

                        Row {
                            width: parent.width
                            height: 18

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "API Base URL"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: "默认 https://api.deepseek.com"
                                color: Theme.textTertiary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontMicro
                            }
                        }

                        TextField {
                            id: apiBaseField

                            width: parent.width
                            height: 44
                            leftPadding: 14
                            rightPadding: 14
                            placeholderText: "https://api.deepseek.com"
                            placeholderTextColor: Theme.textTertiary
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            selectByMouse: true
                            maximumLength: 512

                            background: Rectangle {
                                radius: Theme.radiusControl
                                color: apiBaseField.activeFocus ? Theme.surface : Theme.surfaceAlt
                                border.width: 1
                                border.color: apiBaseField.activeFocus
                                              ? Theme.primary
                                              : Theme.withAlpha(Theme.textPrimary, 0.06)
                            }
                        }

                        Row {
                            width: parent.width
                            height: 18

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "模型名称"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: "默认 deepseek-flash"
                                color: Theme.textTertiary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontMicro
                            }
                        }

                        TextField {
                            id: modelField

                            width: parent.width
                            height: 44
                            leftPadding: 14
                            rightPadding: 14
                            placeholderText: "deepseek-flash"
                            placeholderTextColor: Theme.textTertiary
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            selectByMouse: true
                            maximumLength: 128

                            background: Rectangle {
                                radius: Theme.radiusControl
                                color: modelField.activeFocus ? Theme.surface : Theme.surfaceAlt
                                border.width: 1
                                border.color: modelField.activeFocus
                                              ? Theme.primary
                                              : Theme.withAlpha(Theme.textPrimary, 0.06)
                            }
                        }

                        Item {
                            width: parent.width
                            height: 38

                            Text {
                                width: parent.width - 128
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "支持 DeepSeek、硅基流动等 OpenAI 兼容接口"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontMicro
                                elide: Text.ElideRight
                            }

                            SettingButton {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 112
                                height: 38
                                text: "保存配置"
                                soft: true
                                onClicked: {
                                    backendBridge.saveAIConfig(apiKeyField.text,
                                                               apiBaseField.text,
                                                               modelField.text)
                                    page.showToast("配置已保存")
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "数据管理"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.DemiBold
                    topPadding: 14
                    bottomPadding: 2
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 76
                    radius: Theme.radiusListCard
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.textPrimary, 0.045)

                    CardShadow {}

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 16

                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4

                            Text {
                                text: "备份数据"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "将名单、历史与设置导出为 JSON 文件"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                            }
                        }

                        SettingButton {
                            Layout.alignment: Qt.AlignVCenter
                            width: 96
                            height: 38
                            text: "备份"
                            soft: true
                            onClicked: {
                                var path = backendBridge.chooseBackupPath()
                                if (path && path.length > 0)
                                    backendBridge.exportData(path)
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 76
                    radius: Theme.radiusListCard
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.textPrimary, 0.045)

                    CardShadow {}

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 16

                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4

                            Text {
                                text: "恢复数据"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "从 JSON 备份恢复名单、历史与设置"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                            }
                        }

                        SettingButton {
                            Layout.alignment: Qt.AlignVCenter
                            width: 96
                            height: 38
                            text: "恢复"
                            soft: false
                            onClicked: {
                                var path = backendBridge.chooseRestorePath()
                                if (path && path.length > 0) {
                                    page.pendingRestorePath = path
                                    restoreDialog.open()
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "危险操作"
                    color: Theme.danger
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.DemiBold
                    topPadding: 14
                    bottomPadding: 2
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 86
                    radius: Theme.radiusListCard
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.danger, 0.18)

                    CardShadow {}

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 16

                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4

                            Text {
                                text: "清空所有数据"
                                color: Theme.danger
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: "名单与中奖记录将被永久删除，不可撤销"
                                color: Theme.withAlpha(Theme.danger, 0.72)
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                            }
                        }

                        SettingButton {
                            Layout.alignment: Qt.AlignVCenter
                            width: 106
                            height: 38
                            text: "清空数据"
                            danger: true
                            onClicked: clearDialog.open()
                        }
                    }
                }

                // 隐藏入口：不显眼的小字，点开后需要输入密码
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "开发者选项"
                        color: Theme.withAlpha(Theme.textTertiary, 0.55)
                        font.family: Theme.fontFamily
                        font.pixelSize: 10

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.openDeveloperConsole()
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 开发者验证
    // ─────────────────────────────────────────────────────────────
    Dialog {
        id: developerDialog

        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: 400
        height: 200
        padding: 0

        background: Rectangle {
            radius: Theme.radiusDialog
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

        contentItem: Item {
            ColumnLayout {
                anchors.centerIn: parent
                width: 336
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "开发者验证"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontH1
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: "输入密码后进入权重调校控制台"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                }

                TextField {
                    id: passwordField

                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    leftPadding: 16
                    rightPadding: 16
                    horizontalAlignment: TextInput.AlignHCenter
                    placeholderText: "密码"
                    placeholderTextColor: Theme.textTertiary
                    echoMode: TextInput.Password
                    selectByMouse: true
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    maximumLength: 64

                    background: Rectangle {
                        radius: Theme.radiusControl
                        color: passwordField.activeFocus ? Theme.surface : Theme.surfaceAlt
                        border.width: 1
                        border.color: passwordField.activeFocus
                                      ? Theme.primary
                                      : Theme.withAlpha(Theme.textPrimary, 0.08)
                    }

                    onAccepted: page.confirmDeveloperPassword()
                }

                Text {
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? implicitHeight : 0
                    visible: page.developerError.length > 0
                    text: page.developerError
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.danger
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    SettingButton {
                        Layout.preferredWidth: 116
                        Layout.preferredHeight: 40
                        text: "取消"
                        onClicked: developerDialog.close()
                    }

                    SettingButton {
                        Layout.preferredWidth: 126
                        Layout.preferredHeight: 40
                        text: "进入"
                        soft: true
                        onClicked: page.confirmDeveloperPassword()
                    }
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
        width: 400
        padding: 24

        background: Rectangle {
            radius: Theme.radiusDialog
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
            spacing: 16

            Text {
                width: parent.width
                text: "确认恢复数据？"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontH2
                font.weight: Font.DemiBold
            }

            Text {
                width: parent.width
                text: "恢复后将覆盖当前名单、历史与设置，请确认已选择正确的备份文件。"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                wrapMode: Text.WordWrap
                lineHeight: 1.35
            }

            Item {
                width: parent.width
                height: 40

                Row {
                    anchors.right: parent.right
                    height: parent.height
                    spacing: 10

                    SettingButton {
                        width: 92
                        height: 40
                        text: "取消"
                        onClicked: restoreDialog.close()
                    }

                    SettingButton {
                        width: 110
                        height: 40
                        text: "确认恢复"
                        danger: true
                        onClicked: {
                            backendBridge.importData(page.pendingRestorePath)
                            restoreDialog.close()
                        }
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 清空确认
    // ─────────────────────────────────────────────────────────────
    Dialog {
        id: clearDialog

        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        width: 400
        padding: 24

        background: Rectangle {
            radius: Theme.radiusDialog
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
            spacing: 16

            Text {
                width: parent.width
                text: "清空所有数据？"
                color: Theme.danger
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontH2
                font.weight: Font.DemiBold
            }

            Text {
                width: parent.width
                text: "名单与中奖记录将被永久删除，此操作不可撤销。"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                wrapMode: Text.WordWrap
                lineHeight: 1.35
            }

            Item {
                width: parent.width
                height: 40

                Row {
                    anchors.right: parent.right
                    height: parent.height
                    spacing: 10

                    SettingButton {
                        width: 92
                        height: 40
                        text: "取消"
                        onClicked: clearDialog.close()
                    }

                    SettingButton {
                        width: 110
                        height: 40
                        text: "确认清空"
                        danger: true
                        onClicked: {
                            backendBridge.clearAllData()
                            clearDialog.close()
                        }
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // iOS 风格开关
    // ─────────────────────────────────────────────────────────────
    component IosSwitch: Item {
        id: control

        width: 50
        height: 30

        property bool checked: false
        signal toggled(bool value)

        Rectangle {
            id: track
            anchors.fill: parent
            radius: height / 2
            color: control.checked ? Theme.success : Theme.switchOff

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationNormal
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            id: knob
            y: 2
            x: control.checked ? control.width - width - 2 : 2
            width: 26
            height: 26
            radius: 13
            color: Theme.white
            border.width: 1
            border.color: Theme.withAlpha(Theme.textPrimary, 0.08)

            Behavior on x {
                NumberAnimation {
                    duration: Theme.durationNormal
                    easing.type: Easing.OutCubic
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: control.toggled(!control.checked)
        }
    }

    // ─────────────────────────────────────────────────────────────
    // 设置按钮
    // ─────────────────────────────────────────────────────────────
    component SettingButton: Item {
        id: button

        property string text: ""
        property bool soft: false
        property bool danger: false
        signal clicked()

        width: 100
        height: 40
        enabled: true
        opacity: enabled ? 1.0 : 0.45
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
            color: button.danger
                   ? (mouse.containsMouse ? Theme.dangerHover : Theme.danger)
                   : (button.soft
                      ? (mouse.containsMouse ? Theme.primarySoft : Theme.surfaceAlt)
                      : Theme.surface)
            border.width: button.danger ? 0 : 1
            border.color: button.soft
                          ? Theme.withAlpha(Theme.primary, 0.10)
                          : Theme.border

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationFast
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: button.text
            color: button.danger
                   ? Theme.white
                   : (button.soft ? Theme.primary : Theme.textPrimary)
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
}
