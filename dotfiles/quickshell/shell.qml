//@ pragma EnableQtWebEngineQuick

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
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

    property bool zenActive: false
    property bool isRecording: false

    property var priceLabels: solanaService

    SolanaService {
        id: solanaService
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
    }

    function toggleLauncher(mode) {
        if (root.launcherOpen && root.launcherMode === mode) {
            root.launcherOpen = false
            return
        }
        root.closePanelsExcept('launcher')
        root.launcherMode = mode
        root.launcherOpen = true
    }

    function togglePowerMenu() {
        if (root.powerMenuOpen) {
            root.powerMenuOpen = false
            return
        }
        root.closePanelsExcept('power')
        barComponent.updatePowerMenuPosition()
        root.powerMenuOpen = true
    }

    IpcHandler {
        target: "launcher"

        function toggle() {
            root.toggleLauncher('apps')
        }

        function open() {
            root.closePanelsExcept('launcher')
            root.launcherMode = 'apps'
            root.launcherOpen = true
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
            root.closePanelsExcept('power')
            barComponent.updatePowerMenuPosition()
            root.powerMenuOpen = true
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
                root.closePanelsExcept('notifications')
                barComponent.notificationCenterOpen = true
            }
        }

        function open() {
            root.closePanelsExcept('notifications')
            barComponent.notificationCenterOpen = true
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

    BlurMask {
        visible: root.launcherOpen || root.powerMenuOpen || barComponent.notificationCenterOpen || barComponent.solanaPanelOpen
    }

    Bar {
        id: barComponent
        zenActive: root.zenActive
        isRecording: root.isRecording
        contentVisible: !root.fullscreen || root.launcherOpen || root.powerMenuOpen || barComponent.notificationCenterOpen || barComponent.solanaPanelOpen
        onToggleLauncher: root.toggleLauncher('apps')
        onTogglePowerMenu: root.togglePowerMenu()
        onSolanaPanelOpening: root.closePanelsExcept('solana')
        onNotificationPanelOpening: root.closePanelsExcept('notifications')
        onToggleZen: root.zenActive = true
        onZenDismissed: root.zenActive = false
        priceLabels: root.priceLabels
        notificationService: notificationService
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

}
