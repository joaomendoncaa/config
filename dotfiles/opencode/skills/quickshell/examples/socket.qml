import QtQuick
import Quickshell
import Quickshell.Io

// Listen to Hyprland IPC socket and move a panel to the focused monitor.
// Run with: qs -p socket.qml

ShellRoot {
    Socket {
        path: `/tmp/hypr/${Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")}/.socket2.sock`
        connected: true

        parser: SplitParser {
            property var regex: new RegExp("focusedmon>>(.+),.*")

            onRead: msg => {
                const match = regex.exec(msg);
                if (match != null) {
                    panel.screen = Quickshell.screens.filter(
                        s => s.name == match[1]
                    )[0];
                }
            }
        }
    }

    PanelWindow {
        id: panel

        anchors {
            left: true
            top: true
            bottom: true
        }

        width: 50
        exclusiveZone: 50
        color: "#1e1e1e"

        Text {
            anchors.centerIn: parent
            text: "Follow"
            color: "white"
            rotation: 90
        }
    }
}
