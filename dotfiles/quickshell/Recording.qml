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

    StdioCollector {
        id: stdoutCollector

        onStreamFinished: {
            var output = text.trim();
            console.log("[Recording] Script output:", output);
            try {
                var result = JSON.parse(output);
                root.isRecording = result.text && result.text.length > 0;
                console.log("[Recording] Parsed isRecording:", root.isRecording);
            } catch (e) {
                console.warn("[Recording] Failed to parse JSON:", e);
                root.isRecording = false;
            }
        }
    }

    Process {
        id: checkScriptProcess

        command: [Quickshell.env("HOME") + "/.config.jmmm.sh/bin/toggle-record-icon"]
        stdout: stdoutCollector
    }

    Timer {
        id: checkTimer

        interval: 100
        running: true
        repeat: true
        onTriggered: {
            checkScriptProcess.running = true;
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["omarchy-cmd-screenrecord"])
    }

}
