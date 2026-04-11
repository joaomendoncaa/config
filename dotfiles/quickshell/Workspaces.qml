import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Repeater {
    id: root

    property color foreground: "white"
    property color foregroundSelected: "black"
    property color background: "transparent"
    property color backgroundHovered: "#40FFFFFF"
    property int buttonSize: 26
    property int buttonBorderRadius: 4
    property int fontSize: 16

    model: Hyprland.workspaces

    delegate: Rectangle {
        required property var modelData

        Layout.preferredWidth: root.buttonSize
        Layout.preferredHeight: root.buttonSize
        radius: root.buttonBorderRadius
        color: modelData.focused ? root.foreground : mouseArea.containsMouse ? root.backgroundHovered : root.background

        Text {
            anchors.centerIn: parent
            text: modelData.id
            color: modelData.focused ? root.foregroundSelected : root.foreground
            font.pixelSize: root.fontSize
        }

        MouseArea {
            id: mouseArea

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: modelData.activate()
            hoverEnabled: true
        }

    }

}
