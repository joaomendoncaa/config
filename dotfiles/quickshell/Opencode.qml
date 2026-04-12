import "."
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell

Canvas {
    id: root

    property real rotationAngle: 0

    Layout.leftMargin: Config.gapOuter
    Layout.preferredWidth: Config.buttonSize
    Layout.preferredHeight: Config.buttonSize
    onPaint: {
        var ctx = getContext('2d');
        ctx.clearRect(0, 0, width, height);
        ctx.save();
        ctx.translate(width / 2, height / 2);
        ctx.rotate(rotationAngle * Math.PI / 180);
        ctx.strokeStyle = Config.foreground;
        ctx.lineWidth = 3;
        ctx.setLineDash([0.5, 0.5]);
        ctx.beginPath();
        ctx.arc(0, 0, 10, 0, Math.PI * 2);
        ctx.stroke();
        ctx.restore();
    }

    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: {
            root.rotationAngle = (root.rotationAngle + 2) % 360;
            root.requestPaint();
        }
    }

}
