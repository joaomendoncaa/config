import QtQuick
import Quickshell
import Quickshell.Io
import "Adapters"

Item {
    id: root

    property var adapter: openCodeAdapter
    property var agents: []
    property bool pinsHidden: false
    property bool panelOpen: false
    property real nowMs: Date.now()
    property int runningFrame: 0
    property int blockedFrame: 0
    property int hatchPhase: 0

    readonly property var runningFrames: ['⣶', '⣧', '⣏', '⡟', '⠿', '⢻', '⣹', '⣼']
    readonly property var blockedFrames: ['·', '·', '·', '·', '⚠', '·', '·', '⚠', '·']
    readonly property bool agentLoading: root.adapter ? root.adapter.agentLoading : false
    readonly property bool agentAvailable: root.adapter ? root.adapter.agentAvailable : false
    readonly property string agentError: root.adapter ? root.adapter.agentError : 'agent adapter unavailable'
    readonly property string activeAgentId: root.adapter && root.adapter.activeAgentId ? root.adapter.activeAgentId : ''
    readonly property bool usageLoading: root.adapter ? root.adapter.usageLoading : false
    readonly property bool usageAvailable: root.adapter ? root.adapter.usageAvailable : false
    readonly property string usageError: root.adapter ? root.adapter.usageError : 'usage adapter unavailable'
    readonly property var usageWindows: root.adapter && Array.isArray(root.adapter.usageWindows) ? root.adapter.usageWindows : []
    readonly property string providerName: root.adapter && root.adapter.providerName ? root.adapter.providerName : ''
    readonly property url iconSource: root.adapter && root.adapter.iconSource ? root.adapter.iconSource : ''
    readonly property bool usageSupported: root.adapter ? Boolean(root.adapter.usageSupported) : false
    readonly property string dashboardLabel: root.adapter && root.adapter.dashboardLabel ? root.adapter.dashboardLabel : ''
    readonly property bool dashboardAvailable: root.adapter && root.dashboardLabel.length > 0
    readonly property int agentCount: root.agentAvailable ? root.agents.length : 0
    readonly property int runningCount: root.countState('running')
    readonly property int blockedCount: root.countState('blocked')
    readonly property int pendingCount: root.countState('pending')
    readonly property var pinnedAgents: root.collectPinnedAgents()
    readonly property real primaryUsageRemaining: root.usageAvailable && root.usageWindows.length > 0 ? Number(root.usageWindows[0].actual) || 0 : 0
    readonly property bool usageWarning: root.hasUsageWarning()
    readonly property bool blockedWarningFrame: root.blockedCount > 0 && root.blockedFrames[root.blockedFrame % root.blockedFrames.length] === '⚠'

    OpenCodeAgentAdapter {
        id: openCodeAdapter
    }

    function countState(state) {
        var count = 0
        for (var i = 0; i < root.agents.length; i++) {
            if (root.agents[i].state === state)
                count++
        }
        return count
    }

    function stateRank(state) {
        if (state === 'blocked')
            return 0
        if (state === 'running')
            return 1
        if (state === 'pending')
            return 2
        if (state === 'idle')
            return 3
        return 4
    }

    function sortAgents(items) {
        var sorted = items.slice()
        sorted.sort(function(left, right) {
            var stateDifference = root.stateRank(left.state) - root.stateRank(right.state)
            if (stateDifference !== 0)
                return stateDifference
            return (Number(right.activityAt) || 0) - (Number(left.activityAt) || 0)
        })
        return sorted
    }

    function syncAgents() {
        var source = root.adapter && Array.isArray(root.adapter.agents) ? root.adapter.agents : []
        var sorted = root.sortAgents(source)
        if (JSON.stringify(sorted) !== JSON.stringify(root.agents))
            root.agents = sorted
    }

    function collectPinnedAgents() {
        if (!root.agentAvailable)
            return []
        return root.agents
    }

    function togglePinsHidden() {
        root.pinsHidden = !root.pinsHidden
        persistTimer.restart()
    }

    function focusAgent(agentId) {
        if (root.adapter)
            root.adapter.focusAgent(agentId)
    }

    function refreshAgents() {
        if (root.adapter)
            root.adapter.refreshAgents()
    }

    function refreshUsage() {
        if (root.adapter && root.usageSupported)
            root.adapter.refreshUsage()
    }

    function openDashboard() {
        if (root.adapter && root.dashboardAvailable)
            root.adapter.openDashboard()
    }

    function formatReset(resetAt) {
        if (!root.usageAvailable || resetAt <= 0)
            return '?'
        var totalMinutes = Math.max(0, Math.ceil((resetAt - root.nowMs) / 60000))
        var days = Math.floor(totalMinutes / 1440)
        var hours = Math.floor((totalMinutes % 1440) / 60)
        var minutes = totalMinutes % 60
        if (days > 0)
            return `${days}d ${hours}h`
        if (hours > 0)
            return `${hours}h ${minutes}m`
        return `${minutes}m`
    }

    function hasUsageWarning() {
        for (var i = 0; i < root.usageWindows.length; i++) {
            if ((Number(root.usageWindows[i].warning) || 0) > 0)
                return true
        }
        return false
    }

    function loadPins(raw) {
        try {
            var data = JSON.parse(String(raw || '{}'))
            root.pinsHidden = data.pinsHidden === true
        } catch (error) {
            root.pinsHidden = false
        }
        root.syncAgents()
    }

    Connections {
        target: root.adapter

        function onAgentsChanged() {
            root.syncAgents()
        }
    }

    FileView {
        id: storageFile
        path: root.adapter && root.adapter.settingsPath ? root.adapter.settingsPath : `${Quickshell.env('HOME')}/.config/quickshell/agents.json`
        atomicWrites: true
        printErrors: false
        onLoaded: root.loadPins(storageFile.text())
        onLoadFailed: root.loadPins('{}')
    }

    Timer {
        id: persistTimer
        interval: 250
        onTriggered: storageFile.setText(JSON.stringify({ pinsHidden: root.pinsHidden }, null, 2) + '\n')
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.nowMs = Date.now()
    }

    Timer {
        interval: 100
        running: root.runningCount > 0
        repeat: true
        onTriggered: root.runningFrame = (root.runningFrame + 1) % root.runningFrames.length
    }

    Timer {
        interval: 180
        running: root.blockedCount > 0
        repeat: true
        onTriggered: root.blockedFrame = (root.blockedFrame + 1) % root.blockedFrames.length
    }

    Timer {
        interval: 80
        running: root.panelOpen && root.usageAvailable && root.usageWarning
        repeat: true
        onTriggered: root.hatchPhase = (root.hatchPhase + 1) % 12
    }

    onAdapterChanged: {
        if (root.adapter)
            root.adapter.panelOpen = root.panelOpen
        root.syncAgents()
    }

    onPanelOpenChanged: {
        if (root.adapter)
            root.adapter.panelOpen = root.panelOpen
    }

    Component.onCompleted: {
        root.adapter.panelOpen = root.panelOpen
        root.syncAgents()
    }
}
