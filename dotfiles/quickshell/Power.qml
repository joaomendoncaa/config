import "."
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    Layout.preferredWidth: Config.buttonSize
    Layout.preferredHeight: Config.buttonSize
    radius: Config.buttonBorderRadius
    color: mouseArea.containsMouse ? Config.backgroundHovered : "transparent"

    Item {
        id: iconContainer

        anchors.centerIn: parent
        width: Config.buttonSize * 0.7
        height: Config.buttonSize * 0.7

        Image {
            id: maskImage

            anchors.fill: parent
            source: "assets/power-on_off.svg"
            sourceSize.width: width
            sourceSize.height: height
            smooth: true
            visible: false
        }

        Rectangle {
            id: bgColor

            anchors.fill: parent
            color: Config.foreground
            visible: false
        }

        OpacityMask {
            anchors.fill: parent
            source: bgColor
            maskSource: maskImage
        }

    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton)
                Quickshell.execDetached(["bash", "-c", "loginctl lock-session & omarchy-lock-screen"]);
            else
                Quickshell.execDetached(["omarchy-menu", "system"]);
        }
    }

}
