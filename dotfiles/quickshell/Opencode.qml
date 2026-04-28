import "."
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    Layout.preferredWidth: Config.buttonSize * 3
    Layout.preferredHeight: Config.buttonSize
    Layout.leftMargin: Config.gapOuter
    color: "transparent"

    Item {
        id: iconContainer

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Config.buttonSize * 0.7
        height: Config.buttonSize * 0.7

        Image {
            id: maskImage

            anchors.fill: parent
            source: "assets/opencode-logo.svg"
            sourceSize.width: width
            sourceSize.height: height
            smooth: true
            visible: false
        }

        Rectangle {
            id: fgColor

            anchors.fill: parent
            color: Config.foreground
            visible: false
        }

        OpacityMask {
            anchors.fill: parent
            source: fgColor
            maskSource: maskImage
        }

    }

}
