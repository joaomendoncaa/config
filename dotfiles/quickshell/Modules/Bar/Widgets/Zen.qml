import QtQuick
import QtQuick.Layouts
import qs.Core

Rectangle {
    id: root

    signal activated()

    Layout.preferredWidth: Config.buttonSize
    Layout.preferredHeight: Config.buttonSize
    radius: Config.buttonBorderRadius
    color: mouseArea.containsMouse ? Config.backgroundHovered : "transparent"

    Text {
        anchors.centerIn: parent
        text: "⧗"
        color: Config.foreground
        font.pixelSize: Config.fontSize
        font.family: Config.fontFamily
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: root.activated()
    }

}
