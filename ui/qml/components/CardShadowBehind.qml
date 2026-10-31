import QtQuick
import QtQuick.Effects

import ".."

/*!
    放在卡片后方、用于给 clip: true 的大卡片提供外投影。
    用法：CardShadowBehind { target: stageCard }，放在 stageCard 之前。
*/
Rectangle {
    id: shadowRoot

    property Item target
    property real shadowBlur: 0.65
    property real shadowOffsetY: 5
    property color shadowColor: Theme.withAlpha(Theme.textPrimary, 0.10)

    anchors.fill: target
    radius: target && target.radius !== undefined
            ? target.radius
            : Theme.radiusCard
    color: Theme.surface
    z: -1

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: shadowRoot.shadowColor
        shadowBlur: shadowRoot.shadowBlur
        shadowVerticalOffset: shadowRoot.shadowOffsetY
        shadowHorizontalOffset: 0
        autoPaddingEnabled: true
    }
}
