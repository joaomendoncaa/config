import QtQuick
import qs.Core

Rectangle {
    id: root

    property var values: []

    color: Config.backgroundColoredTertiary
    radius: Math.max(1, Math.round(Config.buttonBorderRadius / 2))

    onValuesChanged: chart.requestPaint()

    Canvas {
        id: chart
        anchors.fill: parent
        anchors.margins: Math.max(2, Config.gapInner)

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var context = getContext('2d')
            context.reset()
            if (!root.values || root.values.length < 2)
                return

            var minimum = Number(root.values[0])
            var maximum = minimum
            for (var i = 1; i < root.values.length; i++) {
                minimum = Math.min(minimum, Number(root.values[i]))
                maximum = Math.max(maximum, Number(root.values[i]))
            }
            var range = Math.max(maximum - minimum, Math.abs(maximum) * 0.002, 0.00000001)

            function point(index) {
                return {
                    x: index * width / (root.values.length - 1),
                    y: height - ((Number(root.values[index]) - minimum) / range) * height
                }
            }

            var first = point(0)
            context.beginPath()
            context.moveTo(first.x, first.y)
            for (var j = 1; j < root.values.length; j++) {
                var next = point(j)
                context.lineTo(next.x, next.y)
            }
            context.lineTo(width, height)
            context.lineTo(0, height)
            context.closePath()
            var fill = context.createLinearGradient(0, 0, 0, height)
            fill.addColorStop(0, Config.hexWithAlpha(Config.foreground, '70'))
            fill.addColorStop(1, Config.hexWithAlpha(Config.foreground, '08'))
            context.fillStyle = fill
            context.fill()

            context.beginPath()
            context.moveTo(first.x, first.y)
            for (var k = 1; k < root.values.length; k++) {
                var linePoint = point(k)
                context.lineTo(linePoint.x, linePoint.y)
            }
            context.strokeStyle = Config.foreground
            context.lineWidth = Math.max(2, Config.borderSize)
            context.lineJoin = 'round'
            context.lineCap = 'round'
            context.stroke()
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !root.values || root.values.length < 2
        text: '\u00b7\u00b7\u00b7'
        color: Config.foregroundSecondary
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize
    }
}
