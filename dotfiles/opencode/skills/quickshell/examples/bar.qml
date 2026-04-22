import QtQuick
import Quickshell

// Minimal top bar example.
// Run with: qs -p bar.qml

ShellRoot {
    PanelWindow {
        anchors {
            left: true
            top: true
            right: true
        }

        height: 30
        exclusiveZone: 30
        color: "#1e1e1e"

        Text {
            anchors.centerIn: parent
            text: "Hello Quickshell"
            color: "white"
        }
    }
}
