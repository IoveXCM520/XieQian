import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: page

    property string drawResult: ""

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 28

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("抽奖主界面")
            color: "#2D3E50"
            font.pixelSize: 48
            font.letterSpacing: 8
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 120
            Layout.preferredHeight: 1
            color: "#D9D2C2"
        }

        Button {
            id: drawButton

            Layout.alignment: Qt.AlignHCenter
            text: qsTr("开始抽奖")
            hoverEnabled: true

            onClicked: {
                page.drawResult = backendBridge.drawWinner()
                resultDialog.open()
            }

            background: Rectangle {
                implicitWidth: 180
                implicitHeight: 52
                radius: 2
                color: drawButton.hovered ? "#3A4E63" : "#2D3E50"
            }

            contentItem: Text {
                text: drawButton.text
                color: "#F8F6F0"
                font.pixelSize: 18
                font.letterSpacing: 4
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Dialog {
        id: resultDialog

        anchors.centerIn: Overlay.overlay
        modal: true
        title: qsTr("抽奖结果")
        standardButtons: Dialog.Close

        contentItem: Label {
            text: page.drawResult
            color: "#2D3E50"
            font.pixelSize: 28
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            padding: 32
        }
    }
}
