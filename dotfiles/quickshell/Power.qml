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

    Layout.preferredWidth: buttonSize
    Layout.preferredHeight: buttonSize
    radius: buttonBorderRadius
    color: mouseArea.containsMouse ? backgroundHovered : "transparent"

    Text {
        anchors.centerIn: parent
        text: ""
        color: foreground
        font.pixelSize: fontSize
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["omarchy-menu", "system"])
    }

}
