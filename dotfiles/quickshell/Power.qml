import "."
import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    Layout.preferredWidth: Config.buttonSize
    Layout.preferredHeight: Config.buttonSize
    radius: Config.buttonBorderRadius
    color: mouseArea.containsMouse ? Config.backgroundHovered : "transparent"

    Text {
        anchors.centerIn: parent
        text: "\uF011"
        color: Config.foreground
        font.pixelSize: Config.fontSize
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["omarchy-menu", "system"])
    }

}
