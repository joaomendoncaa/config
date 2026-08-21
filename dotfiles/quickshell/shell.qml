//@ pragma EnableQtWebEngineQuick

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Core
import "Modules/BlurMask"
import "Modules/Bar"
import "Modules/DictationOSD"
import "Modules/VolumeOSD"
import "Modules/Lock"
import "Modules/PowerMenu"
import "Modules/Superbar"
import "Modules/Notifications"

Scope {
    id: root

    property bool launcherOpen: false
    property bool powerMenuOpen: false
    property string launcherMode: "apps"

    property bool isRecording: false

    // Prewarm the pipewire service so the connection and registry
    // enumeration start before the bar renders, not when the Sink widget instantiates
    readonly property bool pipewirePrewarm: Pipewire.ready

    property var priceLabels: solanaService

    SolanaService {
        id: solanaService
    }

    AgentService {
        id: agentService
    }

    VpnService {
        id: vpnService

        notificationService: notificationService
    }

    Timer {
        interval: 5000
        running: Profiler.enabled
        repeat: true
        onTriggered: Profiler.flush()
    }

    readonly property bool fullscreen: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.hasFullscreen

    Lock { id: lockService }

    DictationOSD { }

    VolumeOSD { }

    NotificationService { id: notificationService }

    function closePanelsExcept(panel) {
        if (panel !== 'launcher')
            root.launcherOpen = false
        if (panel !== 'power')
            root.powerMenuOpen = false
        if (panel !== 'notifications')
            barComponent.notificationCenterOpen = false
        if (panel !== 'solana')
            barComponent.solanaPanelOpen = false
        if (panel !== 'agents')
            barComponent.agentPanelOpen = false
        if (panel !== 'vpn')
            barComponent.vpnPanelOpen = false
    }

    function toggleLauncher(mode) {
        if (root.launcherOpen && root.launcherMode === mode) {
            root.launcherOpen = false
            return
        }
        root.launcherMode = mode
        root.launcherOpen = true
        root.closePanelsExcept('launcher')
    }

    function togglePowerMenu() {
        if (root.powerMenuOpen) {
            root.powerMenuOpen = false
            return
        }
        barComponent.updatePowerMenuPosition()
        root.powerMenuOpen = true
        root.closePanelsExcept('power')
    }

    IpcHandler {
        target: "launcher"

        function toggle() {
            root.toggleLauncher('apps')
        }

        function open() {
            root.launcherMode = 'apps'
            root.launcherOpen = true
            root.closePanelsExcept('launcher')
        }

        function close() {
            launcherOpen = false
        }

        function openClipboard() {
            if (launcherOpen && launcherLoader.item) {
                launcherLoader.item.setSearchMode("clipboard")
            } else {
                root.toggleLauncher('clipboard')
            }
        }

        function ping() {
            return "pong"
        }
    }

    IpcHandler {
        target: "recording"

        function setRecording(active: bool): void {
            root.isRecording = active
        }
    }

    IpcHandler {
        target: "power-menu"

        function toggle() {
            root.togglePowerMenu()
        }

        function open() {
            barComponent.updatePowerMenuPosition()
            root.powerMenuOpen = true
            root.closePanelsExcept('power')
        }

        function close() {
            powerMenuOpen = false
        }

    }

    IpcHandler {
        target: "update-panel"

        function toggle() {
            if (barComponent.notificationCenterOpen) {
                barComponent.notificationCenterOpen = false
            } else {
                barComponent.notificationCenterOpen = true
                root.closePanelsExcept('notifications')
            }
        }

        function open() {
            barComponent.notificationCenterOpen = true
            root.closePanelsExcept('notifications')
        }

        function close() {
            barComponent.notificationCenterOpen = false
        }

    }

    IpcHandler {
        target: "token"

        function add(mint: string): void {
            root.priceLabels.addToken(mint)
        }

        function remove(mint: string): void {
            root.priceLabels.removeToken(mint)
        }

        function list(): string {
            return root.priceLabels.getList()
        }

    }

    IpcHandler {
        target: "submap"

        function set(name: string): void {
            barComponent.submapName = name
        }

        function clear(): void {
            barComponent.submapName = ""
        }

    }

    // Direct Hyprland submap event - more reliable than lua IPC push
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "submap") {
                // Hyprland sends "" for reset / default, otherwise submap name
                barComponent.submapName = event.data
            }
        }
    }

    // On quickshell startup, query current submap (in case hyprland is already in a submap)
    Process {
        id: submapInitProcess
        command: ["hyprctl", "submap"]
        running: true
        stdout: StdioCollector {
            id: submapCollector
            onStreamFinished: {
                var raw = String(submapCollector.text).trim()
                // hyprctl returns "default" for no submap, quotes stripped
                raw = raw.replace(/^"+|"+$/g, "")
                if (raw === "" || raw === "default")
                    barComponent.submapName = ""
                else
                    barComponent.submapName = raw
            }
        }
    }

    BlurMask {
        visible: root.launcherOpen || root.powerMenuOpen || barComponent.notificationCenterOpen || barComponent.solanaPanelOpen || barComponent.agentPanelOpen || barComponent.vpnPanelOpen
    }

    Bar {
        id: barComponent
        isRecording: root.isRecording
        contentVisible: !root.fullscreen || root.launcherOpen || root.powerMenuOpen || barComponent.notificationCenterOpen || barComponent.solanaPanelOpen || barComponent.agentPanelOpen || barComponent.vpnPanelOpen
        onToggleLauncher: root.toggleLauncher('apps')
        onTogglePowerMenu: root.togglePowerMenu()
        onDismissPanels: root.closePanelsExcept('')
        onSolanaPanelOpening: root.closePanelsExcept('solana')
        onNotificationPanelOpening: root.closePanelsExcept('notifications')
        onAgentPanelOpening: root.closePanelsExcept('agents')
        onVpnPanelOpening: root.closePanelsExcept('vpn')
        priceLabels: root.priceLabels
        agentService: agentService
        notificationService: notificationService
        vpnService: vpnService
    }

    ClipboardCapture {
        id: clipboardCapture
    }

    LazyLoader {
        id: launcherLoader

        active: root.launcherOpen || item !== null

        Superbar {
            visible: root.launcherOpen
            initialMode: root.launcherMode
            onDismissed: root.launcherOpen = false
        }

    }

    LazyLoader {
        id: powerMenuLoader

        active: root.powerMenuOpen || item !== null

        PowerMenu {
            visible: root.powerMenuOpen
            popupX: barComponent.powerMenuX
            popupY: barComponent.powerMenuY
            onDismissed: root.powerMenuOpen = false
        }

    }

}
