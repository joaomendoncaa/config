import QtQuick
import qs.Core

Item {
    id: root

    implicitWidth: 20
    implicitHeight: 20

    property color color: Config.foreground
    property real lineWidth: 3
    property int duration: 900

    Canvas {
        id: canvas

        anchors.fill: parent
        antialiasing: true
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = root.color;
            ctx.lineWidth = root.lineWidth;
            ctx.lineCap = "round";
            ctx.beginPath();
            var r = Math.min(width, height) / 2 - root.lineWidth / 2 - 1;
            ctx.arc(width / 2, height / 2, r, -Math.PI / 2, Math.PI);
            ctx.stroke();
        }
    }

    RotationAnimation on rotation {
        from: 0
        to: 360
        duration: root.duration
        loops: Animation.Infinite
        running: root.visible
    }

}
