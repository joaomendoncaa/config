import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import qs.Core

Rectangle {
    id: root

    Layout.preferredWidth: Config.buttonSize
    Layout.preferredHeight: Config.buttonSize
    radius: Config.buttonBorderRadius
    color: Config.zenMode ? Config.foreground : mouseArea.containsMouse ? Config.backgroundHovered : "transparent"

    Item {
        id: iconContainer

        anchors.centerIn: parent
        width: Config.buttonSize * 0.7 - 2
        height: Config.buttonSize * 0.7 - 2

        Image {
            id: maskImage

            anchors.fill: parent
            source: "../../../Assets/lamp-desk.svg"
            sourceSize.width: width
            sourceSize.height: height
            smooth: true
            visible: false
        }

        Rectangle {
            id: fgColor

            anchors.fill: parent
            color: Config.zenMode ? Config.backgroundColored : Config.foreground
            visible: false
        }

        OpacityMask {
            anchors.fill: parent
            source: fgColor
            maskSource: maskImage
        }

    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Config.zenMode = !Config.zenMode
    }

}
