//@ pragma EnableQtWebEngineQuick

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Core
import qs.Modules.BlurMask
import qs.Modules.Bar
import qs.Modules.DictationOSD
import qs.Modules.VolumeOSD
import qs.Modules.Lock
import qs.Modules.PowerMenu
import qs.Modules.UpdatePanel
import qs.Modules.Superbar

Scope {
    id: root

    property bool launcherOpen: false
    property bool powerMenuOpen: false
    property bool updatePanelOpen: false
    property string launcherMode: "apps"

    readonly property bool fullscreen: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.hasFullscreen

    Lock { id: lockService }

    DictationOSD { }

    VolumeOSD { }

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

    IpcHandler {
        target: "update-panel"

        function toggle() {
            if (!updatePanelOpen)
                barComponent.updateUpdatePanelPosition()
            updatePanelOpen = !updatePanelOpen
        }

        function open() {
            barComponent.updateUpdatePanelPosition()
            updatePanelOpen = true
        }

        function close() {
            updatePanelOpen = false
        }

    }

    BlurMask {
        visible: root.launcherOpen || root.powerMenuOpen || root.updatePanelOpen
    }

    Bar {
        id: barComponent
        contentVisible: !root.fullscreen || root.launcherOpen || root.powerMenuOpen || root.updatePanelOpen
        onToggleLauncher: root.launcherOpen = !root.launcherOpen
        onTogglePowerMenu: root.powerMenuOpen = !root.powerMenuOpen
        onToggleUpdatePanel: root.updatePanelOpen = !root.updatePanelOpen
    }

    ClipboardCapture {
        id: clipboardCapture
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

    LazyLoader {
        id: updatePanelLoader

        active: root.updatePanelOpen

        UpdatePanel {
            popupX: barComponent.updatePanelX
            popupY: barComponent.updatePanelY
            updatesItem: barComponent.updatePanelButtonItem
            onDismissed: root.updatePanelOpen = false
        }

    }

}
