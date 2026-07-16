import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core

Rectangle {
    id: root

    required property var notificationService

    implicitWidth: clockText.implicitWidth + Config.gapInner * 4
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: Config.buttonSize
    radius: Config.buttonBorderRadius
    color: mouseArea.containsMouse ? Config.backgroundHovered : "transparent"

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

    Text {
        id: clockText

        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "dd MMM dddd hh:mm:ss")
        color: Config.foreground
        font.pixelSize: Config.fontSize
        font.family: Config.fontFamily
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.notificationService.fyi("Calendar integration coming soon", "", "low", 5)
    }

}
