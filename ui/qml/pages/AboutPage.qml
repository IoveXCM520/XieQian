import QtQuick
import QtQuick.Layouts

Item {
    id: page

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16

        Image {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 128
            Layout.preferredHeight: 128
            source: "qrc:/ui/assets/app-icon-512.png"
            sourceSize.width: 512
            sourceSize.height: 512
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            asynchronous: true
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "撷签 XieQian"
            color: "#2D3E50"
            font.pixelSize: 44
            font.letterSpacing: 6
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 80
            Layout.preferredHeight: 1
            color: "#D4AF37"
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "v1.0.0 (Build 2026)"
            color: "#8A97A5"
            font.pixelSize: 14
            font.letterSpacing: 2
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "妙择一签，落定心安"
            color: "#3F5A4E"
            font.pixelSize: 18
            font.letterSpacing: 4
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "开源协议：MIT License"
            color: "#8A97A5"
            font.pixelSize: 13
            font.letterSpacing: 1
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        text: "面向教育场景的离线抽奖系统"
        color: "#A6AFB8"
        font.pixelSize: 12
        font.letterSpacing: 2
    }
}
