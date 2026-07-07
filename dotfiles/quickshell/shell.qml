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

    property bool zenActive: false

    property var priceLabels: priceLabelsItem

    Item {
        id: priceLabelsItem

        property var trackedTokens: []
        property var tokenData: ({})

        property int _retryDelay: 2000

        onTrackedTokensChanged: {
            if (root.priceLabels.trackedTokens.length > 0)
                root.priceLabels._kick()
        }

        function addToken(mint: string): void {
            if (root.priceLabels.trackedTokens.indexOf(mint) !== -1) return
            var arr = root.priceLabels.trackedTokens.slice()
            arr.push(mint)
            root.priceLabels.trackedTokens = arr
        }

        function removeToken(mint: string): void {
            var idx = root.priceLabels.trackedTokens.indexOf(mint)
            if (idx === -1) return
            var arr = root.priceLabels.trackedTokens.slice()
            arr.splice(idx, 1)
            root.priceLabels.trackedTokens = arr
            var data = JSON.parse(JSON.stringify(root.priceLabels.tokenData))
            delete data[mint]
            root.priceLabels.tokenData = data
        }

        function loadTokens(arr: var): void {
            root.priceLabels.trackedTokens = Array.isArray(arr) ? arr : []
        }

        function getList(): string {
            return JSON.stringify(root.priceLabels.trackedTokens.map(function(m) {
                return { mint: m, data: root.priceLabels.tokenData[m] || null }
            }))
        }

        function _kick(): void {
            root.priceLabels.pollTokenPrices()
            root.priceLabels.fetchMissingSymbols()
        }

        function handleFetch(proc, handler, backoff) {
            var text = proc.stdout.text.trim()
            if (!text) {
                if (backoff) root.priceLabels._backoff()
                return
            }
            try {
                handler(JSON.parse(text))
                if (backoff) root.priceLabels._resetBackoff()
            } catch (e) {
                console.warn("[token] fetch:", e)
                if (backoff) root.priceLabels._backoff()
            }
        }

        function _backoff() {
            root.priceLabels._retryDelay = Math.min(root.priceLabels._retryDelay * 2, 60000)
        }

        function _resetBackoff() {
            root.priceLabels._retryDelay = 2000
        }

        function pollTokenPrices() {
            var mints = root.priceLabels.trackedTokens.join(',')
            if (!mints) return
            tokenFetcher.command = ["curl", "-s", "https://api.jup.ag/price/v3?ids=" + mints]
            tokenFetcher.running = true
        }

        function fetchMissingSymbols() {
            var missing = []
            for (var i = 0; i < root.priceLabels.trackedTokens.length; i++) {
                var mint = root.priceLabels.trackedTokens[i]
                if (!root.priceLabels.tokenData[mint] || !root.priceLabels.tokenData[mint].symbol)
                    missing.push(mint)
            }
            if (missing.length === 0) return
            symbolFetcher.command = ["curl", "-s", "https://api.dexscreener.com/latest/dex/tokens/" + missing.join(",")]
            symbolFetcher.running = true
        }

        Process {
            id: tokenFetcher
            command: ["true"]
            running: false

            stdout: StdioCollector {
                onStreamFinished: root.priceLabels.handleFetch(tokenFetcher, function(json) {
                    var data = JSON.parse(JSON.stringify(root.priceLabels.tokenData))
                    var found = false
                    for (var mint in json) {
                        if (json[mint] && json[mint].usdPrice !== undefined) {
                            found = true
                            var sym = data[mint] && data[mint].symbol
                            data[mint] = json[mint]
                            if (sym) data[mint].symbol = sym
                        }
                    }
                    if (!found) throw new Error('no data')
                    root.priceLabels.tokenData = data
                }, true)
            }
        }

        Process {
            id: symbolFetcher
            command: ["true"]
            running: false

            stdout: StdioCollector {
                onStreamFinished: root.priceLabels.handleFetch(symbolFetcher, function(json) {
                    if (!json.pairs) return
                    var byMint = {}
                    for (var i = 0; i < json.pairs.length; i++) {
                        var p = json.pairs[i]
                        if (!byMint[p.baseToken.address] || byMint[p.baseToken.address].liq < (p.liquidity.usd || 0))
                            byMint[p.baseToken.address] = { sym: p.baseToken.symbol, liq: p.liquidity.usd || 0 }
                    }
                    var data = JSON.parse(JSON.stringify(root.priceLabels.tokenData))
                    for (var mint in byMint)
                        (data[mint] || (data[mint] = {})).symbol = byMint[mint].sym
                    root.priceLabels.tokenData = data
                }, false)
            }
        }

        Timer {
            id: tokenPollTimer
            interval: root.priceLabels._retryDelay
            running: root.priceLabels.trackedTokens.length > 0
            repeat: true
            onTriggered: {
                root.priceLabels.pollTokenPrices()
                root.priceLabels.fetchMissingSymbols()
            }
        }
    }

    FileView {
        id: storageFile
        path: Quickshell.env('HOME') + '/.config/quickshell/data.json'
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try { storage._data = JSON.parse(String(storageFile.text() || '{}')) }
            catch (e) { storage._data = {} }
            storage.loaded()
        }
        onLoadFailed: {
            storage._data = {}
            storage.loaded()
        }
    }

    QtObject {
        id: storage
        property var _data: ({})

        signal loaded()

        function get(key) { return _data[key] }
        function set(key, value) {
            var d = JSON.parse(JSON.stringify(_data))
            d[key] = value
            _data = d
            storageFile.setText(JSON.stringify(d, null, 2) + '\n')
        }
        function remove(key) {
            var d = JSON.parse(JSON.stringify(_data))
            delete d[key]
            _data = d
            storageFile.setText(JSON.stringify(d, null, 2) + '\n')
        }

        onLoaded: {
            root.priceLabels.loadTokens(storage.get('tokens'))
        }
    }

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

    IpcHandler {
        target: "token"

        function add(mint: string): void {
            root.priceLabels.addToken(mint)
            root.persistTokens()
        }

        function remove(mint: string): void {
            root.priceLabels.removeToken(mint)
            root.persistTokens()
        }

        function list(): string {
            return root.priceLabels.getList()
        }
    }

    function persistTokens() {
        storage.set('tokens', root.priceLabels.trackedTokens)
    }

    BlurMask {
        visible: root.launcherOpen || root.powerMenuOpen || root.updatePanelOpen
    }

    Bar {
        id: barComponent
        zenActive: root.zenActive
        contentVisible: !root.fullscreen || root.launcherOpen || root.powerMenuOpen || root.updatePanelOpen
        onToggleLauncher: root.launcherOpen = !root.launcherOpen
        onTogglePowerMenu: root.powerMenuOpen = !root.powerMenuOpen
        onToggleUpdatePanel: root.updatePanelOpen = !root.updatePanelOpen
        onToggleZen: root.zenActive = true
        onZenDismissed: root.zenActive = false
        priceLabels: root.priceLabels
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
