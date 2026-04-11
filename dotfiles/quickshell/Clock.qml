import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    property color foreground: "white"
    property color backgroundHovered: "#40FFFFFF"
    property int buttonSize: 26
    property int buttonBorderRadius: 4
    property int fontSize: 16
    property int gapInner: 4
    property string fontFamily: "JetBrainsMonoNL Nerd Font"

    Layout.preferredWidth: clockText.implicitWidth + gapInner * 4
    Layout.preferredHeight: buttonSize
    radius: buttonBorderRadius
    color: mouseArea.containsMouse ? backgroundHovered : "transparent"

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

    Text {
        id: clockText

        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "dd MMM dddd hh:mm:ss")
        color: foreground
        font.pixelSize: fontSize
        font.family: fontFamily
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["notify-send", "TODO: integrate calendar"])
    }

}
