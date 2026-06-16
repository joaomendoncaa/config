import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Core

Item {
    id: root

    property bool enabled: true
    signal lockRequested()

    IdleMonitor {
        id: mon
        enabled: root.enabled
        timeout: Config.idleLockTimeout
        respectInhibitors: true
        onIsIdleChanged: {
            if (mon.isIdle && root.enabled) root.lockRequested()
        }
    }

    IpcHandler {
        target: "idle"
        function status(): string { return JSON.stringify({ enabled: root.enabled, idle: mon.isIdle, timeout: Config.idleLockTimeout }) }
        function enable(): string { root.enabled = true; return "ok" }
        function disable(): string { root.enabled = false; return "ok" }
    }
}
