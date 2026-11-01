import QtQuick

import ".."

/*!
    iOS 风格开关。
    开启：轨道亮绿 #34C759；关闭：轨道浅灰 #E5E5EA；滑块纯白带轻投影。
*/
Item {
    id: control

    width: 51
    height: 31

    property bool checked: false
    property bool interactive: true
    signal toggled(bool value)

    scale: mouse.pressed && interactive ? 0.94 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: Theme.durationFast
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: track

        anchors.fill: parent
        radius: height / 2
        color: control.checked ? Theme.switchOn : Theme.switchOff

        Behavior on color {
            ColorAnimation {
                duration: Theme.durationNormal
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        id: knobShadow

        y: 3
        x: control.checked ? control.width - width - 3 : 3
        width: 27
        height: 27
        radius: width / 2
        color: "#1F000000"

        Behavior on x {
            NumberAnimation {
                duration: Theme.durationNormal
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        id: knob

        y: 2
        x: control.checked ? control.width - width - 2 : 2
        width: 27
        height: 27
        radius: width / 2
        color: Theme.white

        Behavior on x {
            NumberAnimation {
                duration: Theme.durationNormal
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: control.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (control.interactive)
                control.toggled(!control.checked)
        }
    }
}
