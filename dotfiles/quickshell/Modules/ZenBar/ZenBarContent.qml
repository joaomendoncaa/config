import QtQuick
import QtQuick.Layouts
import qs.Core

Item {
    id: root

    property bool active: false
    property int countdownInitial: 60 * 60 * 3
    property real countdownCurrent: 0

    signal dismissed()

    function start() {
        root.countdownCurrent = root.countdownInitial;
        zenTimer.start();
    }

    function stop() {
        zenTimer.stop();
        root.countdownCurrent = root.countdownInitial;
    }

    function formatCountdown(seconds) {
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        var s = seconds % 60;
        return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    onActiveChanged: {
        if (active)
            start();
        else
            stop();
    }

    Timer {
        id: zenTimer

        interval: 16
        repeat: true
        onTriggered: {
            root.countdownCurrent = Math.max(0, root.countdownCurrent - 0.016);
            if (root.countdownCurrent <= 0)
                root.dismissed();

        }
    }

    Item {
        id: countdownLineWrapper

        property real lineWidth: Math.max(0, (root.countdownCurrent / root.countdownInitial) * width)
        property real contentLeft: clockText.x
        property real contentRight: buttonRow.x + buttonRow.width

        anchors.centerIn: parent
        width: parent.width
        height: Config.borderSize

        Rectangle {
            id: countdownLineLeft

            width: Math.min(parent.lineWidth, parent.contentLeft)
            color: Config.accent
            radius: 100

            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }

        }

        Rectangle {
            id: countdownLineRight

            x: parent.contentRight
            width: Math.max(0, parent.lineWidth - parent.contentRight)
            color: Config.accent
            radius: 100

            anchors {
                top: parent.top
                bottom: parent.bottom
            }

        }

    }

    Text {
        id: clockText

        anchors.centerIn: parent
        text: root.formatCountdown(Math.ceil(root.countdownCurrent))
        color: Config.foreground
        font.pixelSize: Config.fontSize
        font.family: Config.fontFamily
        font.bold: true
    }

    Row {
        id: buttonRow

        anchors.left: clockText.right
        anchors.leftMargin: Config.gapInner * 3
        anchors.verticalCenter: clockText.verticalCenter

        Rectangle {
            width: stopLabel.implicitWidth + Config.gapInner * 3
            height: Config.buttonSize
            radius: Config.buttonBorderRadius
            color: stopArea.containsMouse ? Config.backgroundHovered : "transparent"

            Text {
                id: stopLabel

                anchors.centerIn: parent
                text: "×"
                color: Config.foreground
                font.pixelSize: Config.fontSize * 2
                font.family: Config.fontFamily
            }

            MouseArea {
                id: stopArea

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: root.dismissed()
            }

        }

    }

}
