import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    property bool isRecording: false

    Layout.preferredWidth: recordingText.implicitWidth + Config.gapInner * 4
    Layout.preferredHeight: Config.buttonSize
    radius: Config.buttonBorderRadius
    color: mouseArea.containsMouse && root.isRecording ? Config.backgroundHovered : "transparent"

    Text {
        id: recordingText

        anchors.centerIn: parent
        text: "\u25CF"
        color: Config.foreground
        font.pixelSize: Config.fontSize
        font.family: Config.fontFamily
        opacity: root.isRecording ? 1 : 0
        visible: true

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }
    }

    IpcHandler {
        target: "recording"

        function setRecording(active: bool): void {
            root.isRecording = active;
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["toggle-record-screen"])
    }
}
