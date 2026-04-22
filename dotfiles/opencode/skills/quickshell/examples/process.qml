import QtQuick
import Quickshell
import Quickshell.Io

// Run a shell command from QML.
// Run with: qs -p process.qml

ShellRoot {
    PanelWindow {
        anchors.centerIn: undefined // let compositor pick position
        width: 200
        height: 100
        color: "#1e1e1e"

        Process {
            id: notifyProc
            command: ["notify-send", "Hello from Quickshell"]
        }

        MouseArea {
            anchors.fill: parent
            onClicked: notifyProc.startDetached()

            Text {
                anchors.centerIn: parent
                text: "Click me"
                color: "white"
            }
        }
    }
}
