import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Core

Scope {
    id: root

    // Main monitor: black backdrop below the windows, above the wallpaper,
    // so only the open windows stay visible.
    PanelWindow {
        id: backdrop

        screen: {
            for (let i = 0; i < Quickshell.screens.length; ++i)
                if (Quickshell.screens[i].name === Config.mainMonitor)
                    return Quickshell.screens[i];
            return null;
        }
        visible: Config.zenMode
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "#000000"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "zen-backdrop"

        // Click-through: windows above still get input, the backdrop is visual only.
        mask: Region {}
    }

    // Every other monitor: black cover above the windows that swallows input.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData

            screen: modelData
            visible: Config.zenMode && modelData.name !== Config.mainMonitor
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "#000000"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "zen-cover"

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                preventStealing: true
                onWheel: function(wheel) {
                    wheel.accepted = true;
                }
            }

        }

    }

}
