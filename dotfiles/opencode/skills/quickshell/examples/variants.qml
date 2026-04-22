import QtQuick
import Quickshell

// Multi-monitor panel using Variants.
// Creates one PanelWindow per connected screen.
// Run with: qs -p variants.qml

Variants {
    model: Quickshell.screens

    PanelWindow {
        property var modelData
        screen: modelData

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
            text: modelData.name
            color: "white"
        }
    }
}
