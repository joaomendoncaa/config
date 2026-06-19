//@ pragma EnableQtWebEngineQuick

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Core
import qs.Modules.Bar
import qs.Modules.DictationOSD
import qs.Modules.Lock
import qs.Modules.PowerMenu
import qs.Modules.Superbar

Scope {
    id: root

    property bool launcherOpen: false
    property bool powerMenuOpen: false
    property string launcherMode: "apps"

    Lock { id: lockService }

    DictationOSD { }

    IpcHandler {
        target: "launcher"

        function toggle() {
            launcherMode = "apps"
            launcherOpen = !launcherOpen
        }

        function open() {
            launcherMode = "apps"
            launcherOpen = true
        }

        function close() {
            launcherOpen = false
        }

        function openClipboard() {
            if (launcherOpen && launcherLoader.item) {
                launcherLoader.item.setSearchMode("clipboard")
            } else {
                launcherMode = "clipboard"
                launcherOpen = true
            }
        }

        function ping() {
            return "pong"
        }
    }

    IpcHandler {
        target: "power-menu"

        function toggle() {
            if (!powerMenuOpen)
                barComponent.updatePowerMenuPosition()
            powerMenuOpen = !powerMenuOpen
        }

        function open() {
            barComponent.updatePowerMenuPosition()
            powerMenuOpen = true
        }

        function close() {
            powerMenuOpen = false
        }

    }

    Bar {
        id: barComponent
        launcherOpen: root.launcherOpen
        powerMenuOpen: root.powerMenuOpen
        onToggleLauncher: root.launcherOpen = !root.launcherOpen
        onTogglePowerMenu: root.powerMenuOpen = !root.powerMenuOpen
    }

    ClipboardCapture {
        id: clipboardCapture
    }

    HyprlandFocusGrab {
        active: root.launcherOpen && launcherLoader.item !== null
        windows: launcherLoader.item ? [launcherLoader.item] : []
        onCleared: root.launcherOpen = false
    }

    LazyLoader {
        id: launcherLoader

        active: root.launcherOpen

        Superbar {
            initialMode: root.launcherMode
            onDismissed: root.launcherOpen = false
        }

    }

    LazyLoader {
        id: powerMenuLoader

        active: root.powerMenuOpen

        PowerMenu {
            popupX: barComponent.powerMenuX
            popupY: barComponent.powerMenuY
            onDismissed: root.powerMenuOpen = false
        }

    }

}
