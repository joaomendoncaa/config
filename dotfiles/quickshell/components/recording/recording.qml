import "../.."
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
        opacity: root.isRecording ? pulseOpacity : 0
        visible: true

        property real pulseOpacity: 1.0

        Behavior on opacity {
            enabled: !root.isRecording
            NumberAnimation {
                duration: 150
            }
        }

        SequentialAnimation {
            running: root.isRecording
            loops: Animation.Infinite

            NumberAnimation {
                target: recordingText
                property: "pulseOpacity"
                from: 1.0
                to: 0.5
                duration: 800
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                target: recordingText
                property: "pulseOpacity"
                from: 0.5
                to: 1.0
                duration: 800
                easing.type: Easing.InOutSine
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
        enabled: root.isRecording
        hoverEnabled: true
        cursorShape: root.isRecording ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: Quickshell.execDetached(["toggle-record-screen"])
    }
}
