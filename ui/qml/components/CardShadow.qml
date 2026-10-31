import QtQuick
import QtQuick.Effects

import ".."

/*!
    卡片内部的柔和投影层。
    放在卡片 Rectangle 内、内容之前，z = -1；
    白色源与卡片同色，因此即使阴影效果降级也不会破坏卡片底色。
*/
Rectangle {
    anchors.fill: parent
    anchors.margins: 1
    radius: Math.max(0, (parent && parent.radius !== undefined
                         ? parent.radius
                         : Theme.radiusListCard) - 1)
    color: Theme.surface
    z: -1

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Theme.shadowColor
        shadowBlur: 0.55
        shadowVerticalOffset: 3
        shadowHorizontalOffset: 0
        autoPaddingEnabled: true
    }
}
