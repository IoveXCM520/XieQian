import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import ".."
import "../components"

/*!
    历史记录页。
    - 中奖记录卡片流
    - 空状态使用 Canvas 绘制极简时钟线稿
*/
Item {
    id: page

    property var records: []

    readonly property int recordCount: records.length

    function refresh() {
        records = backendBridge.getHistory()
    }

    function initialOf(name) {
        if (!name || name.length === 0)
            return "签"
        return name.charAt(0)
    }

    Component.onCompleted: refresh()

    Connections {
        target: backendBridge

        function onHistoryUpdated() {
            page.refresh()
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
                    text: "抽取历史"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontH0
                    font.weight: Font.Bold
                }

                Text {
                    text: "每一次中签，都值得被记住"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 32
                width: historyCount.implicitWidth + 22
                radius: 16
                color: Theme.surface
                border.width: 1
                border.color: Theme.withAlpha(Theme.primary, 0.10)

                Text {
                    id: historyCount
                    anchors.centerIn: parent
                    text: page.recordCount + " 条"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                    font.weight: Font.DemiBold
                }
            }
        }

        ListView {
            id: listView

            anchors.top: header.bottom
            anchors.topMargin: 16
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            spacing: 8
            cacheBuffer: 2000
            boundsBehavior: Flickable.StopAtBounds
            model: page.records

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AlwaysOff
            }

            add: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Theme.durationNormal
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "y"
                    from: 8
                    to: 0
                    duration: Theme.durationNormal
                    easing.type: Easing.OutCubic
                }
            }

            delegate: Rectangle {
                id: card

                CardShadow {}

                width: ListView.view ? ListView.view.width : 0
                height: 68
                radius: Theme.radiusListCard
                color: Theme.surface
                border.width: 1
                border.color: cardMouse.containsMouse
                              ? Theme.withAlpha(Theme.primary, 0.18)
                              : Theme.withAlpha(Theme.textPrimary, 0.045)
                scale: cardMouse.containsMouse ? 1.002 : 1.0

                Behavior on border.color {
                    ColorAnimation {
                        duration: Theme.durationFast
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.durationFast
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.ArrowCursor
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 14

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 20
                        color: Theme.primarySoft

                        Text {
                            anchors.centerIn: parent
                            text: page.initialOf(modelData.name)
                            color: Theme.primary
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        Text {
                            width: parent.width
                            text: modelData.name
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: modelData.studentId && modelData.studentId.length > 0
                                  ? modelData.studentId
                                  : "中签记录"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 54
                        Layout.preferredHeight: 24
                        radius: 12
                        color: Theme.primarySoft

                        Text {
                            anchors.centerIn: parent
                            text: "中签"
                            color: Theme.primary
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 132
                        text: modelData.time
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                    }
                }
            }

            // 空状态
            Item {
                anchors.centerIn: parent
                width: Math.min(360, listView.width - 40)
                height: 240
                visible: listView.count === 0

                Column {
                    width: parent.width
                    anchors.centerIn: parent
                    spacing: 14

                    Item {
                        width: parent.width
                        height: 132

                        Canvas {
                            width: 132
                            height: 132
                            anchors.centerIn: parent
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)

                                var cx = width / 2
                                var cy = height / 2
                                var radius = 43
                                var pi2 = Math.PI * 2

                                var halo = ctx.createRadialGradient(cx, cy, 4, cx, cy, 64)
                                halo.addColorStop(0, "rgba(59,139,246,0.075)")
                                halo.addColorStop(0.62, "rgba(46,212,165,0.03)")
                                halo.addColorStop(1, "rgba(59,139,246,0)")
                                ctx.fillStyle = halo
                                ctx.beginPath()
                                ctx.arc(cx, cy, 64, 0, pi2)
                                ctx.fill()

                                ctx.strokeStyle = "#D7DCE4"
                                ctx.lineWidth = 1.8
                                ctx.lineCap = "round"
                                ctx.beginPath()
                                ctx.arc(cx, cy, radius, 0, pi2)
                                ctx.stroke()

                                for (var i = 0; i < 12; ++i) {
                                    var a = i * Math.PI / 6
                                    var inner = (i % 3 === 0) ? radius - 8 : radius - 4
                                    ctx.strokeStyle = (i % 3 === 0) ? "#C4CBD6" : "#E2E6EC"
                                    ctx.lineWidth = (i % 3 === 0) ? 1.6 : 1
                                    ctx.beginPath()
                                    ctx.moveTo(cx + Math.cos(a) * inner,
                                               cy + Math.sin(a) * inner)
                                    ctx.lineTo(cx + Math.cos(a) * (radius - 1),
                                               cy + Math.sin(a) * (radius - 1))
                                    ctx.stroke()
                                }

                                ctx.strokeStyle = "#8FBBF8"
                                ctx.lineWidth = 3
                                ctx.beginPath()
                                ctx.moveTo(cx, cy)
                                ctx.lineTo(cx, cy - 23)
                                ctx.moveTo(cx, cy)
                                ctx.lineTo(cx + 16, cy + 8)
                                ctx.stroke()

                                ctx.beginPath()
                                ctx.arc(cx, cy, 3.2, 0, pi2)
                                ctx.fillStyle = "#3B8BF6"
                                ctx.fill()
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: "还没有抽取记录"
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: "完成一次抽签后，中签记录会出现在这里"
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                    }
                }
            }
        }
    }
}
