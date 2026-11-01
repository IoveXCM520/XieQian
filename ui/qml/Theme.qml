pragma Singleton

import QtQuick

/*!
    撷签全局设计系统。
    iOS / macOS 设置页的设计语言：浅灰分组背景、纯白大圆角卡片、极细分割线。
    所有页面、组件只从这里取色、字号、圆角与动效时长。
*/
QtObject {
    id: theme

    // ─────────────────────────────────────────────────────────────
    // 品牌色
    // ─────────────────────────────────────────────────────────────
    readonly property color primary: "#3B8BF6"
    readonly property color primaryEnd: "#2ED4A5"
    readonly property color primaryPressed: "#2F7EE6"
    readonly property color primarySoft: "#EAF3FF"
    readonly property color primarySoftGreen: "#E8F8F3"

    readonly property Gradient primaryGradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: "#3B8BF6" }
        GradientStop { position: 1.0; color: "#2ED4A5" }
    }

    readonly property Gradient primaryGradientVertical: Gradient {
        orientation: Gradient.Vertical
        GradientStop { position: 0.0; color: "#3B8BF6" }
        GradientStop { position: 1.0; color: "#2ED4A5" }
    }

    // ─────────────────────────────────────────────────────────────
    // 中性色
    // ─────────────────────────────────────────────────────────────
    // 分组背景：iOS 设置页的浅灰
    readonly property color background: "#F2F2F7"
    readonly property color groupedBackground: "#F2F2F7"
    // 卡片与输入框
    readonly property color surface: "#FFFFFF"
    readonly property color surfaceAlt: "#F2F2F7"
    readonly property color surfaceMuted: "#F2F2F7"
    readonly property color surfaceHover: "#F5F5F7"
    readonly property color surfacePressed: "#EBEBF0"
    readonly property color fill: "#F2F2F7"

    readonly property color textPrimary: "#000000"
    readonly property color textSecondary: "#6E6E73"
    readonly property color textTertiary: "#8E8E93"
    readonly property color textInverse: "#FFFFFF"

    // 极细分割线：卡片内项与项之间用它，左侧留白不顶格
    readonly property color divider: "#E5E5EA"
    readonly property color hairline: "#E5E5EA"
    readonly property color separator: "#E5E5EA"
    readonly property color border: "#E5E5EA"
    readonly property color borderStrong: "#D1D1D6"

    readonly property color success: "#34C759"
    readonly property color warning: "#FF9F0A"
    readonly property color danger: "#FF3B30"
    readonly property color dangerHover: "#D70015"
    readonly property color info: "#007AFF"

    readonly property color successSoft: "#E8F8F3"
    readonly property color warningSoft: "#FFF7E6"
    readonly property color dangerSoft: "#FFEBEA"

    readonly property color white: "#FFFFFF"
    readonly property color black: "#000000"
    readonly property color transparent: "#00000000"
    readonly property color overlay: "#66000000"
    readonly property color scrim: "#33000000"
    // iOS 开关：开亮绿、关浅灰
    readonly property color switchOn: "#34C759"
    readonly property color switchOff: "#E5E5EA"

    // 大转盘辅助色（高饱和）
    readonly property color wheelSectorA: "#1E88FF"
    readonly property color wheelSectorB: "#00C853"
    readonly property color wheelSectorC: "#FFD600"
    readonly property color wheelSectorD: "#FF6D00"
    readonly property color wheelText: "#FFFFFF"

    // ─────────────────────────────────────────────────────────────
    // 阴影：iOS 卡片是柔和的大范围低透明度投影
    // ─────────────────────────────────────────────────────────────
    readonly property color shadowColor: "#14000000"
    readonly property color shadowColorStrong: "#1F000000"
    readonly property int shadowRadius: 14
    readonly property int shadowSamples: 17
    readonly property int shadowOffsetY: 4
    readonly property int shadowRadiusLarge: 28
    readonly property int shadowOffsetYLarge: 10

    // ─────────────────────────────────────────────────────────────
    // 圆角
    // ─────────────────────────────────────────────────────────────
    readonly property int radiusWindow: 12
    readonly property int radiusCard: 18
    readonly property int radiusListCard: 18
    readonly property int radiusDialog: 20
    readonly property int radiusControl: 14
    readonly property int radiusButton: 14
    readonly property int radiusSmall: 8
    readonly property int radiusPill: 999

    // ─────────────────────────────────────────────────────────────
    // 字体与字号
    // ─────────────────────────────────────────────────────────────
    readonly property string fontFamily: "Microsoft YaHei UI"

    // iOS Large Title
    readonly property int fontLargeTitle: 34
    readonly property int fontDisplay: 32
    readonly property int fontH0: 24
    readonly property int fontH1: 20
    readonly property int fontH2: 16
    readonly property int fontBody: 14
    readonly property int fontCaption: 12
    readonly property int fontMicro: 11

    readonly property int weightRegular: Font.Normal
    readonly property int weightMedium: Font.Medium
    readonly property int weightDemiBold: Font.DemiBold
    readonly property int weightBold: Font.Bold

    // ─────────────────────────────────────────────────────────────
    // 布局
    // ─────────────────────────────────────────────────────────────
    readonly property int titleBarHeight: 60
    readonly property int sidebarWidth: 96
    readonly property int pagePadding: 32
    // iOS 列表行高与主按钮高度
    readonly property int rowHeight: 60
    readonly property int buttonHeight: 48
    // 分组卡片的左右内缩，分割线左侧留白与文字对齐
    readonly property int cardPadding: 18
    readonly property int separatorInset: 18

    readonly property int space1: 4
    readonly property int space2: 8
    readonly property int space3: 12
    readonly property int space4: 16
    readonly property int space5: 24
    readonly property int space6: 32

    // ─────────────────────────────────────────────────────────────
    // 动效
    // ─────────────────────────────────────────────────────────────
    readonly property int durationFast: 120
    readonly property int durationNormal: 200
    readonly property int durationSlow: 320

    readonly property int easingOutCubic: Easing.OutCubic
    readonly property int easingInOutCubic: Easing.InOutCubic
    readonly property int easingOutBack: Easing.OutBack

    // ─────────────────────────────────────────────────────────────
    // 工具函数
    // ─────────────────────────────────────────────────────────────
    function withAlpha(sourceColor, alphaValue) {
        return Qt.rgba(sourceColor.r, sourceColor.g, sourceColor.b, alphaValue)
    }

    function mix(firstColor, secondColor, ratio) {
        var t = Math.max(0, Math.min(1, ratio))
        return Qt.rgba(
            firstColor.r + (secondColor.r - firstColor.r) * t,
            firstColor.g + (secondColor.g - firstColor.g) * t,
            firstColor.b + (secondColor.b - firstColor.b) * t,
            1.0
        )
    }
}
