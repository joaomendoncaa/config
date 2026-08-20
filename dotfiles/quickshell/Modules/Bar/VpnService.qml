import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core

// Non-visual service wrapping the Proton VPN CLI (`protonvpn`).
//
// Responsibilities:
//  - Poll `protonvpn status` to track connection state / current server.
//  - Drive `protonvpn connect` / `protonvpn disconnect` (async) with a busy
//    flag for loading feedback.
//  - Parse the CLI-cached server list (Tier filtering + plan detection)
//    so the panel can offer server selection.
Item {
    id: root

    property var notificationService: null

    // Connection state: "connected" | "disconnected" | "unknown"
    property string state: "unknown"
    property bool connected: state === "connected"

    // Details of the active connection (populated when connected).
    property string serverName: ""
    property string serverLocation: ""
    property int load: -1
    property string protocol: ""

    // True while a connect/disconnect is in flight.
    property bool busy: false

    // Free plan detection + free-tier server list, from the CLI's cached
    // server list, grouped by country. On the free plan the CLI rejects any
    // location/server pick, so country connects go through qs-vpn-connect
    // (which drives the Proton API directly) instead.
    property bool freePlan: true
    property bool serverListLoaded: false
    property var countries: []

    property bool _statusRunning: false
    property bool _serverListRunning: false
    property string _pendingGoal: ""
    property string _connectError: ""
    property string _disconnectError: ""
    property int _statusFails: 0

    // --- Public API -------------------------------------------------------

    function refresh() {
        if (root.busy || root._statusRunning || statusProcess.running)
            return
        root._statusRunning = true
        statusProcess.running = true
    }

    // Bypass the busy gate so a just-finished connect/disconnect can be
    // reflected immediately (we still need the status to settle the busy
    // flag via _pendingGoal).
    function pollNow() {
        if (root._statusRunning || statusProcess.running)
            return
        root._statusRunning = true
        statusProcess.running = true
    }

    // Start connecting to the fastest available (free) server, e.g. from the
    // bar toggle / connect button.
    function startConnect() {
        if (root.busy)
            return false
        root._pendingGoal = "connected"
        root.busy = true
        root._connectError = ""
        connectProcess.command = ["protonvpn", "connect"]
        connectProcess.running = true
        opWatchdog.restart()
        return true
    }

    // Start connecting to the best free server in a given country. This goes
    // through qs-vpn-connect (Proton Python API) because the protonvpn CLI
    // blocks location selection on the free plan.
    function startConnectCountry(code) {
        if (root.busy)
            return false
        root._pendingGoal = "connected"
        root.busy = true
        root._connectError = ""
        connectProcess.command = ["qs-vpn-connect", code]
        connectProcess.running = true
        opWatchdog.restart()
        return true
    }

    function startDisconnect() {
        if (root.busy)
            return false
        root._pendingGoal = "disconnected"
        root.busy = true
        root._disconnectError = ""
        disconnectProcess.command = ["protonvpn", "disconnect"]
        disconnectProcess.running = true
        opWatchdog.restart()
        return true
    }

    // Convenience toggle: connect (fastest free server) or disconnect.
    function toggle() {
        if (root.busy)
            return
        if (root.connected)
            root.startDisconnect()
        else
            root.startConnect()
    }

    // Connect to a country selected from the panel list.
    function selectCountry(code) {
        root.startConnectCountry(code)
    }

    function parseStatus(text) {
        var out = {
            state: "unknown",
            serverName: "",
            serverLocation: "",
            load: -1,
            protocol: ""
        }
        var lines = String(text || "").split('\n')
        for (var i = 0; i < lines.length; i++) {
            var line = (lines[i] || "").trim()
            if (line.indexOf("Status:") === 0) {
                out.state = line.substring(7).trim().toLowerCase()
            } else if (line.indexOf("Server:") === 0) {
                var serverPart = line.substring(7).trim()
                var inIdx = serverPart.indexOf(" in ")
                if (inIdx >= 0) {
                    out.serverName = serverPart.substring(0, inIdx).trim()
                    out.serverLocation = serverPart.substring(inIdx + 4).trim()
                } else {
                    out.serverName = serverPart
                }
            } else if (line.indexOf("Load:") === 0) {
                var loadMatch = line.match(/(\d+)/)
                if (loadMatch)
                    out.load = parseInt(loadMatch[1], 10)
            } else if (line.indexOf("Protocol:") === 0) {
                out.protocol = line.substring(9).trim()
            }
        }
        return out
    }

    function applyStatus(text) {
        var s = root.parseStatus(text)
        root.state = s.state
        root.serverName = s.serverName
        root.serverLocation = s.serverLocation
        root.load = s.load
        root.protocol = s.protocol
        if (root._pendingGoal && root.state === root._pendingGoal) {
            root._pendingGoal = ""
            root.busy = false
            opWatchdog.stop()
        }
    }

    function applyServerList(text) {
        var data = {}
        try {
            data = JSON.parse(String(text || ''))
        } catch (e) {
            return false
        }
        if (!data || data.loaded === false || !Array.isArray(data.countries))
            return false
        root.countries = data.countries
        root.freePlan = !!data.freePlan
        root.serverListLoaded = true
        return true
    }

    function refreshServers() {
        if (!root._serverListRunning && !listProcess.running) {
            root._serverListRunning = true
            listProcess.running = true
        }
    }

    // --- Status polling ------------------------------------------------------

    Process {
        id: statusProcess

        command: ["protonvpn", "status"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.applyStatus(statusProcess.stdout.text)
            }
        }

        onExited: (exitCode, exitStatus) => {
            root._statusRunning = false
            if (exitCode !== 0) {
                root._statusFails += 1
                if (root._statusFails > 2) {
                    // CLI is probably not signed in / daemon unavailable.
                    root.state = "unknown"
                }
            } else {
                root._statusFails = 0
            }
        }
    }

    // --- Connect / disconnect (async) ----------------------------------------

    Process {
        id: connectProcess

        command: ["protonvpn", "connect"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: { }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root._connectError = connectProcess.stderr.text.trim()
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.busy = false
                root._pendingGoal = ""
                opWatchdog.stop()
                var msg = String(root._connectError || "").trim()
                if (msg.length > 0 && root.notificationService) {
                    var lines = msg.split('\n')
                    var tail = lines.slice(-6).join('\n')
                    root.notificationService.fyi("VPN connect failed", tail, 4)
                }
            }
            root.pollNow()
        }
    }

    Process {
        id: disconnectProcess

        command: ["protonvpn", "disconnect"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: { }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root._disconnectError = disconnectProcess.stderr.text.trim()
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.busy = false
                root._pendingGoal = ""
                opWatchdog.stop()
                var msg = String(root._disconnectError || "").trim()
                if (msg.length > 0 && root.notificationService)
                    root.notificationService.fyi("VPN disconnect failed", msg, 4)
            }
            root.pollNow()
        }
    }

    // Safety net: clear the busy state even if the CLI hangs.
    Timer {
        id: opWatchdog

        interval: 45000
        running: false
        onTriggered: {
            root.busy = false
            root._pendingGoal = ""
        }
    }

    // Poll status every few seconds so the UI tracks external changes
    // (auto-reconnect, manual `protonvpn` usage, daemon events).
    Timer {
        id: statusTimer

        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // --- Server list -----------------------------------------------------------

    // The CLI keeps a possibly-large cache at ~/.cache/Proton/VPNerverlist.json.
    // Parsing it in-process is fragile (big file, partial writes), so delegate
    // the read/filter to a small helper that emits compact JSON instead.
    Process {
        id: listProcess

        command: ["qs-vpn-servers"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root._serverListRunning = false
                if (!root.applyServerList(listProcess.stdout.text))
                    serverListRetry.restart()
            }
        }

        onExited: (exitCode, exitStatus) => {
            root._serverListRunning = false
        }
    }

    // Retry quickly when the helper's read failed (e.g. file mid-write).
    Timer {
        id: serverListRetry

        interval: 3000
        running: false
        onTriggered: root.refreshServers()
    }

    // Periodic refresh so new/updated server data is picked up.
    Timer {
        id: serverListTimer

        interval: 30000
        running: true
        repeat: true
        onTriggered: root.refreshServers()
    }

    Component.onCompleted: {
        root.refresh()
        root.refreshServers()
    }
}