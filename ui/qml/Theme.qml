pragma Singleton

import QtQuick

/*!
    撷签全局设计系统。
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
    readonly property color background: "#F2F3F5"
    readonly property color surface: "#FFFFFF"
    readonly property color surfaceAlt: "#F7F8FA"
    readonly property color surfaceMuted: "#F7F8FA"
    readonly property color surfaceHover: "#F2F3F5"
    readonly property color surfacePressed: "#ECEEF1"

    readonly property color textPrimary: "#1F2329"
    readonly property color textSecondary: "#8F959E"
    readonly property color textTertiary: "#B7BCC4"
    readonly property color textInverse: "#FFFFFF"

    readonly property color divider: "#E5E6EB"
    readonly property color border: "#E5E6EB"
    readonly property color borderStrong: "#D8DBE0"

    readonly property color success: "#2ED4A5"
    readonly property color warning: "#FFB020"
    readonly property color danger: "#F54A45"
    readonly property color dangerHover: "#E81123"
    readonly property color info: "#3B8BF6"

    readonly property color successSoft: "#E8F8F3"
    readonly property color warningSoft: "#FFF7E6"
    readonly property color dangerSoft: "#FFF0EF"

    readonly property color white: "#FFFFFF"
    readonly property color black: "#000000"
    readonly property color transparent: "#00000000"
    readonly property color overlay: "#66000000"
    readonly property color scrim: "#33000000"
    readonly property color switchOff: "#E5E6EB"

    // 转盘 / 翻牌 / 盲盒辅助色
    readonly property color wheelSectorA: "#E3F2FD"
    readonly property color wheelSectorB: "#E8F5E9"
    readonly property color wheelSectorC: "#FFF8E1"
    readonly property color wheelSectorD: "#F3E5F5"
    readonly property color wheelText: "#44505F"

    readonly property color cardBackA: "#FFFFFF"
    readonly property color cardBackB: "#F4F8FF"
    readonly property color cardBackC: "#EAF7F2"

    // ─────────────────────────────────────────────────────────────
    // 阴影
    // ─────────────────────────────────────────────────────────────
    readonly property color shadowColor: "#0A000000"
    readonly property color shadowColorStrong: "#1A000000"
    readonly property int shadowRadius: 12
    readonly property int shadowSamples: 17
    readonly property int shadowOffsetY: 4
    readonly property int shadowRadiusLarge: 24
    readonly property int shadowOffsetYLarge: 10

    // ─────────────────────────────────────────────────────────────
    // 圆角
    // ─────────────────────────────────────────────────────────────
    readonly property int radiusWindow: 12
    readonly property int radiusCard: 16
    readonly property int radiusListCard: 12
    readonly property int radiusDialog: 24
    readonly property int radiusControl: 8
    readonly property int radiusSmall: 6
    readonly property int radiusPill: 999

    // ─────────────────────────────────────────────────────────────
    // 字体与字号
    // ─────────────────────────────────────────────────────────────
    readonly property string fontFamily: "Microsoft YaHei UI"

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
    readonly property int titleBarHeight: 48
    readonly property int sidebarWidth: 72
    readonly property int pagePadding: 32

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
