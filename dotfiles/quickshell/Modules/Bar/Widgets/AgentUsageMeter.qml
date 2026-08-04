import QtQuick
import QtQuick.Layouts
import qs.Core

ColumnLayout {
    id: root

    required property string label
    required property string resetText
    required property real actual
    required property real warning
    required property int hatchPhase

    spacing: 3

    RowLayout {
        Layout.fillWidth: true
        spacing: 0

        Text {
            text: root.label
            color: Config.foreground
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize - 2
            font.weight: Font.Medium
        }

        Item {
            Layout.fillWidth: true
        }

        Text {
            text: `⚡ ${root.resetText}`
            color: Config.foreground
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize - 2
            font.weight: Font.Medium
        }
    }

    Rectangle {
        id: track
        Layout.fillWidth: true
        Layout.preferredHeight: 20
        radius: 2
        color: Config.foregroundSecondary
        clip: true

        Item {
            id: fillArea
            anchors.fill: parent
            anchors.margins: 3
            clip: true

            Rectangle {
                width: fillArea.width * Math.max(0, Math.min(1, root.actual))
                height: parent.height
                radius: 1
                color: Config.foreground
            }

            Item {
                id: warningArea
                x: fillArea.width * Math.max(0, Math.min(1, root.actual))
                width: fillArea.width * Math.max(0, Math.min(1 - root.actual, root.warning))
                height: parent.height
                clip: true

                Canvas {
                    id: stripes
                    anchors.fill: parent

                    onPaint: {
                        var context = getContext('2d')
                        context.clearRect(0, 0, width, height)
                        context.fillStyle = Config.foreground
                        var period = 12
                        var stripeWidth = 5
                        var phase = root.hatchPhase % period
                        for (var x = -height - period + phase; x < width + height; x += period) {
                            context.beginPath()
                            context.moveTo(x, height)
                            context.lineTo(x + stripeWidth, height)
                            context.lineTo(x + stripeWidth + height, 0)
                            context.lineTo(x + height, 0)
                            context.closePath()
                            context.fill()
                        }
                    }

                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                }

                Connections {
                    target: root
                    function onHatchPhaseChanged() {
                        stripes.requestPaint()
                    }
                }
            }
        }
    }
}
