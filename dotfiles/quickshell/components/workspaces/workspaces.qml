import "../.."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

RowLayout {
    id: root

    spacing: Config.gapInner

    Repeater {
        model: Hyprland.workspaces

        delegate: Rectangle {
            required property var modelData

            Layout.preferredWidth: Config.buttonSize
            Layout.preferredHeight: Config.buttonSize
            radius: Config.buttonBorderRadius
            color: modelData.focused ? Config.foreground : mouseArea.containsMouse ? Config.backgroundHovered : Config.background

            Text {
                anchors.centerIn: parent
                text: modelData.id
                color: modelData.focused ? Config.foregroundSelected : Config.foreground
                font.pixelSize: Config.fontSize
                font.family: Config.fontFamily
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

    Rectangle {
        Layout.preferredWidth: Config.buttonSize
        Layout.preferredHeight: Config.buttonSize
        radius: Config.buttonBorderRadius
        color: plusMouseArea.containsMouse ? Config.backgroundHovered : Config.background

        Text {
            anchors.centerIn: parent
            text: "+"
            color: Config.foreground
            font.pixelSize: Config.fontSize
        }

        MouseArea {
            id: plusMouseArea

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Hyprland.dispatch("workspace empty")
            hoverEnabled: true
        }

    }

}
