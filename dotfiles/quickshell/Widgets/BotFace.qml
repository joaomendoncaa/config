import QtQuick

// Idle bot face: breathing, wandering gaze, blinks, and expression changes.
Item {
    id: root

    property color fillColor: "white"
    property real gazeX: 0
    property real gazeY: 0
    property real eyeOpen: 1
    property string expressionName: "neutral"
    property string pendingExpression: "neutral"

    implicitWidth: 16
    implicitHeight: implicitWidth

    function setExpression(name) {
        if (name === expressionName)
            return

        pendingExpression = name
        blink.stop()
        expressionBlink.restart()
    }

    // Eye capsules are stroked centerlines with round caps. A straight line is a
    // cylinder, a zero-length line is a circle, and a curved line is an arch.
    function eyeShape(name, side) {
        var gap = 0.18
        var ex = side === 0 ? -gap : gap
        var ey = 0
        var width = 0.17
        var x0 = 0
        var y0 = -0.105
        var x1 = 0
        var y1 = 0.105
        var qx = 0
        var qy = 0

        if (name === "happy") {
            width = 0.10
            x0 = -0.075
            y0 = 0.03
            x1 = 0.075
            y1 = 0.03
            qx = 0
            qy = -0.15
        } else if (name === "inspecting") {
            width = side === 0 ? 0.11 : 0.20
            y0 = -0.0005
            y1 = 0.0005
        } else if (name === "sad") {
            var angle = (side === 0 ? -14 : 14) * Math.PI / 180
            var half = 0.085
            var dx = Math.sin(angle) * half
            var dy = Math.cos(angle) * half
            x0 = -dx
            y0 = dy
            x1 = dx
            y1 = -dy
        } else if (name === "surprised") {
            width = 0.22
            y0 = -0.14
            y1 = 0.14
        }

        return {
            "ex": ex,
            "ey": ey,
            "width": width,
            "x0": x0,
            "y0": y0,
            "x1": x1,
            "y1": y1,
            "qx": qx,
            "qy": qy
        }
    }

    Behavior on gazeX {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutCubic
        }
    }

    Behavior on gazeY {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation on scale {
        running: root.visible
        loops: Animation.Infinite

        NumberAnimation {
            from: 1
            to: 1.04
            duration: 3200
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            from: 1.04
            to: 1
            duration: 3200
            easing.type: Easing.InOutSine
        }
    }

    Timer {
        interval: 1400 + Math.floor(Math.random() * 1200)
        running: root.visible
        repeat: true
        onTriggered: {
            // Sample inside a unit disk so diagonal glances stay within the face.
            var angle = Math.random() * Math.PI * 2
            var distance = Math.sqrt(Math.random())
            root.gazeX = Math.cos(angle) * distance
            root.gazeY = Math.sin(angle) * distance
            interval = 1400 + Math.floor(Math.random() * 1200)
        }
    }

    Timer {
        interval: 1800 + Math.floor(Math.random() * 1400)
        running: root.visible
        repeat: true
        onTriggered: {
            if (!expressionBlink.running)
                blink.restart()
            interval = 1800 + Math.floor(Math.random() * 1400)
        }
    }

    Timer {
        interval: 3000 + Math.floor(Math.random() * 2000)
        running: root.visible
        repeat: true
        onTriggered: {
            if (root.expressionName === "neutral") {
                var names = ["happy", "inspecting", "sad", "surprised"]
                root.setExpression(names[Math.floor(Math.random() * names.length)])
                interval = 1200 + Math.floor(Math.random() * 700)
            } else {
                root.setExpression("neutral")
                interval = 3000 + Math.floor(Math.random() * 2000)
            }
        }
    }

    SequentialAnimation {
        id: blink

        NumberAnimation {
            target: root
            property: "eyeOpen"
            to: 0.08
            duration: 80
            easing.type: Easing.InQuad
        }

        NumberAnimation {
            target: root
            property: "eyeOpen"
            to: 1
            duration: 120
            easing.type: Easing.OutQuad
        }
    }

    SequentialAnimation {
        id: expressionBlink

        NumberAnimation {
            target: root
            property: "eyeOpen"
            to: 0.08
            duration: 80
            easing.type: Easing.InQuad
        }

        ScriptAction {
            script: root.expressionName = root.pendingExpression
        }

        NumberAnimation {
            target: root
            property: "eyeOpen"
            to: 1
            duration: 120
            easing.type: Easing.OutQuad
        }
    }

    Canvas {
        id: face

        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var d = Math.min(width, height)
            if (d <= 0)
                return

            // Keep the circle inset from the canvas edge so it never clips.
            var faceSize = d - 1
            var cx = width / 2
            var cy = height / 2
            var radius = faceSize / 2

            ctx.globalCompositeOperation = "source-over"
            ctx.fillStyle = root.fillColor
            ctx.beginPath()
            ctx.arc(cx, cy, radius, 0, Math.PI * 2)
            ctx.fill()

            ctx.save()
            ctx.translate(cx, cy)
            ctx.scale(faceSize, faceSize)
            ctx.globalCompositeOperation = "destination-out"
            ctx.strokeStyle = "#000000"
            ctx.lineCap = "round"

            for (var side = 0; side < 2; side++) {
                var shape = root.eyeShape(root.expressionName, side)

                ctx.save()
                ctx.translate(shape.ex + root.gazeX * 0.08, shape.ey + root.gazeY * 0.08)
                ctx.scale(1, root.eyeOpen)
                ctx.beginPath()
                ctx.moveTo(shape.x0, shape.y0)
                ctx.quadraticCurveTo(shape.qx, shape.qy, shape.x1, shape.y1)
                ctx.lineWidth = shape.width
                ctx.stroke()
                ctx.restore()
            }

            ctx.restore()
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    Connections {
        target: root

        function onGazeXChanged() {
            face.requestPaint()
        }

        function onGazeYChanged() {
            face.requestPaint()
        }

        function onEyeOpenChanged() {
            face.requestPaint()
        }

        function onFillColorChanged() {
            face.requestPaint()
        }

        function onExpressionNameChanged() {
            face.requestPaint()
        }
    }
}
