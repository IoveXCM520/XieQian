import QtQuick

Item {
    id: wheelRoot

    property color paperColor: "#F8F6F0"
    property color daiColor: "#2D3E50"
    property color bambooColor: "#3F5A4E"
    property color goldColor: "#D4AF37"

    // 扇区渐变的两端色，比底色略亮/略暗
    property string daiLightColor: "#3A5068"
    property string daiDarkColor: "#22303F"
    property string bambooLightColor: "#4E6E60"
    property string bambooDarkColor: "#2F473D"

    // 旋转角度由外部动画驱动，指针与外环保持静止
    property real angle: 0

    property bool showPointer: true

    implicitWidth: 420
    implicitHeight: 420

    // 金色边框的发光：两层半透明金色矩形向外扩散
    Rectangle {
        anchors.fill: parent
        anchors.margins: -14
        radius: width / 2
        color: wheelRoot.goldColor
        opacity: 0.07
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -7
        radius: width / 2
        color: wheelRoot.goldColor
        opacity: 0.12
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: wheelRoot.paperColor
        border.width: 2
        border.color: wheelRoot.goldColor
    }

    Item {
        id: disc

        anchors.fill: parent
        anchors.margins: 14
        antialiasing: true
        rotation: wheelRoot.angle

        Canvas {
            anchors.fill: parent

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();

                var sectors = 8;
                var cx = width / 2;
                var cy = height / 2;
                var radius = Math.min(width, height) / 2;
                var step = Math.PI * 2 / sectors;
                var startAngle = -Math.PI / 2;

                ctx.lineWidth = 1;
                ctx.strokeStyle = wheelRoot.goldColor;

                for (var i = 0; i < sectors; i++) {
                    ctx.beginPath();
                    ctx.moveTo(cx, cy);
                    ctx.arc(cx, cy, radius, startAngle + i * step, startAngle + (i + 1) * step);
                    ctx.closePath();

                    var even = i % 2 === 0;
                    var shade = ctx.createRadialGradient(cx, cy, radius * 0.08, cx, cy, radius);
                    shade.addColorStop(0, even ? wheelRoot.daiLightColor : wheelRoot.bambooLightColor);
                    shade.addColorStop(0.62, even ? wheelRoot.daiColor : wheelRoot.bambooColor);
                    shade.addColorStop(1, even ? wheelRoot.daiDarkColor : wheelRoot.bambooDarkColor);
                    ctx.fillStyle = shade;
                    ctx.fill();
                    ctx.stroke();
                }
            }
        }

        Repeater {
            model: 8

            delegate: Text {
                readonly property real sectorAngle: -Math.PI / 2 + (index + 0.5) * Math.PI / 4
                readonly property real distance: Math.min(disc.width, disc.height) / 2 * 0.68

                x: disc.width / 2 + Math.cos(sectorAngle) * distance - width / 2
                y: disc.height / 2 + Math.sin(sectorAngle) * distance - height / 2
                text: ["壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌"][index]
                color: wheelRoot.paperColor
                font.pixelSize: 22
                opacity: 0.85
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 92
        height: 92
        radius: width / 2
        color: wheelRoot.paperColor
        border.width: 1
        border.color: wheelRoot.goldColor

        Text {
            anchors.centerIn: parent
            text: "签"
            color: wheelRoot.daiColor
            font.pixelSize: 34
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 2
        width: 16
        height: 16
        rotation: 45
        visible: wheelRoot.showPointer
        color: wheelRoot.goldColor
    }
}
