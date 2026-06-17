import QtQuick
import qs.Core

Item {
    id: root

    property real peak: 0
    readonly property color waveformColor: Config.foreground
    readonly property int bufferSize: 90
    property var ring: (function() {
        var a = [];
        for (var i = 0; i < 90; i++) a.push(0)
        return a;
    })()

    function reset() {
        var a = [];
        for (var i = 0; i < root.bufferSize; i++) a.push(0)
        ring = a;
    }

    Timer {
        interval: 33
        running: true
        repeat: true
        onTriggered: {
            var r = root.ring;
            r.push(root.peak);
            if (r.length > root.bufferSize)
                r.shift();

            waveCanvas.requestPaint();
        }
    }

    Canvas {
        id: waveCanvas

        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            var r = root.ring;
            if (r.length === 0)
                return ;

            var cy = height / 2;
            var maxHalf = height / 2 - 1;
            var cols = root.bufferSize;
            var colW = width / cols;
            var startIdx = cols - r.length;
            ctx.strokeStyle = root.waveformColor;
            ctx.lineWidth = Math.max(1, colW * 1.5);
            ctx.lineCap = "butt";
            ctx.beginPath();
            for (var i = 0; i < r.length; i++) {
                var x = (startIdx + i) * colW + colW / 2;
                var halfH = Math.max(1, r[i] * maxHalf);
                ctx.moveTo(x, cy - halfH);
                ctx.lineTo(x, cy + halfH);
            }
            ctx.stroke();
        }
    }

}
