import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    property int batteryPercent: 0
    property var batteryProcess

    Layout.preferredWidth: Config.buttonSize
    Layout.preferredHeight: Config.buttonSize
    radius: Config.buttonBorderRadius
    color: mouseArea.containsMouse ? Config.backgroundHovered : "transparent"

    Timer {
        id: batteryTimer

        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: batteryProcess.running = true
    }

    Item {
        anchors.fill: parent
        anchors.margins: 6

        Row {
            anchors.fill: parent
            spacing: 2

            // Stacked bars container
            Column {
                id: barsColumn

                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: parent.height
                spacing: 3

                // Top bar - battery fill
                Rectangle {
                    id: mouseBar

                    width: parent.width
                    height: (parent.height - parent.spacing) / 2
                    radius: 1
                    color: Config.foregroundSecondary

                    Rectangle {
                        width: parent.width * (root.batteryPercent / 100)
                        radius: 1
                        color: Config.foreground

                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }

                    }

                }

                // Bottom bar - outline only (placeholder for future device or just visual)
                Rectangle {
                    width: parent.width
                    height: (parent.height - parent.spacing) / 2
                    radius: 1
                    color: "transparent"
                    border.width: 1
                    border.color: Config.foregroundSecondary
                }

            }

        }

    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: Quickshell.execDetached(["notify-send", "Mouse battery: " + root.batteryPercent + "%"])
    }

    batteryProcess: Process {
        command: [Quickshell.env("HOME") + "/.config.jmmm.sh/bin/battery-mouse"]

        stdout: StdioCollector {
            onStreamFinished: {
                var output = batteryProcess.stdout.text.trim();
                var percent = parseInt(output, 10);
                if (!isNaN(percent))
                    root.batteryPercent = Math.max(0, Math.min(100, percent));

            }
        }

    }

}
