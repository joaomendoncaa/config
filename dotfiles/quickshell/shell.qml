//@ pragma EnableQtWebEngineQuick

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Core
import qs.Modules.Bar
import qs.Modules.Superbar
import qs.Services

Scope {
    id: root

    property bool launcherOpen: false

    Lock { id: lockService }

    Idle {
        onLockRequested: lockService.lock()
    }

    IpcHandler {
        target: "launcher"

        function toggle() {
            launcherOpen = !launcherOpen
        }

        function open() {
            launcherOpen = true
        }

        function close() {
            launcherOpen = false
        }

        function ping() {
            return "pong"
        }
    }

    Bar {
        launcherOpen: root.launcherOpen
        onToggleLauncher: root.launcherOpen = !root.launcherOpen
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
            onDismissed: root.launcherOpen = false
        }

    }

}
