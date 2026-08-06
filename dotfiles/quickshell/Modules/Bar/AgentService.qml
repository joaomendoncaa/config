import QtQuick
import Quickshell
import Quickshell.Io
import "Adapters"

Item {
    id: root

    property var adapter: openCodeAdapter
    property var agents: []
    property var pinnedAgentIds: []
    property var autoPinnedAgentIds: []
    property bool pinsHidden: false
    property bool panelOpen: false
    property real nowMs: Date.now()
    property int runningFrame: 0
    property int blockedFrame: 0
    property int hatchPhase: 0

    readonly property int autoPinLimit: 3

    readonly property var runningFrames: ['⣶', '⣧', '⣏', '⡟', '⠿', '⢻', '⣹', '⣼']
    readonly property var blockedFrames: ['·', '·', '·', '·', '⚠', '·', '·', '⚠', '·']
    readonly property bool agentLoading: root.adapter ? root.adapter.agentLoading : false
    readonly property bool agentAvailable: root.adapter ? root.adapter.agentAvailable : false
    readonly property string agentError: root.adapter ? root.adapter.agentError : 'agent adapter unavailable'
    readonly property bool usageLoading: root.adapter ? root.adapter.usageLoading : false
    readonly property bool usageAvailable: root.adapter ? root.adapter.usageAvailable : false
    readonly property string usageError: root.adapter ? root.adapter.usageError : 'usage adapter unavailable'
    readonly property var usageWindows: root.adapter && Array.isArray(root.adapter.usageWindows) ? root.adapter.usageWindows : []
    readonly property string providerName: root.adapter && root.adapter.providerName ? root.adapter.providerName : ''
    readonly property url iconSource: root.adapter && root.adapter.iconSource ? root.adapter.iconSource : ''
    readonly property bool usageSupported: root.adapter ? Boolean(root.adapter.usageSupported) : false
    readonly property string dashboardLabel: root.adapter && root.adapter.dashboardLabel ? root.adapter.dashboardLabel : ''
    readonly property string balanceLabel: root.adapter && root.adapter.balanceLabel ? root.adapter.balanceLabel : ''
    readonly property string balance: root.adapter && root.adapter.balance ? root.adapter.balance : ''
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

    function isPinned(agentId) {
        return root.pinnedAgentIds.indexOf(agentId) !== -1
    }

    function isAutoPinned(agentId) {
        return root.autoPinnedAgentIds.indexOf(agentId) !== -1
    }

    function agentCreatedAt(agent) {
        return Number(agent.createdAt) || Number(agent.activityAt) || 0
    }

    function ensureFirstPins() {
        var agents = root.adapter && Array.isArray(root.adapter.agents) ? root.adapter.agents : []

        var liveIds = {}
        var candidates = []
        for (var k = 0; k < agents.length; k++) {
            var agent = agents[k]
            if (!agent || !agent.id)
                continue
            liveIds[agent.id] = true
            candidates.push(agent)
        }

        candidates.sort(function(left, right) {
            return root.agentCreatedAt(left) - root.agentCreatedAt(right)
        })

        var autoPins = []
        for (var i = 0; i < root.autoPinnedAgentIds.length; i++) {
            var persisted = root.autoPinnedAgentIds[i]
            if (liveIds[persisted] && autoPins.indexOf(persisted) === -1)
                autoPins.push(persisted)
        }

        for (var j = 0; j < candidates.length && autoPins.length < root.autoPinLimit; j++) {
            var id = candidates[j].id
            if (autoPins.indexOf(id) === -1)
                autoPins.push(id)
        }

        var pins = autoPins.slice()
        for (var m = 0; m < root.pinnedAgentIds.length; m++) {
            var existing = root.pinnedAgentIds[m]
            if (pins.indexOf(existing) === -1)
                pins.push(existing)
        }

        if (JSON.stringify(autoPins) !== JSON.stringify(root.autoPinnedAgentIds)) {
            root.autoPinnedAgentIds = autoPins
            persistTimer.restart()
        }
        if (JSON.stringify(pins) !== JSON.stringify(root.pinnedAgentIds))
            root.pinnedAgentIds = pins
    }

    function sortAgents(items) {
        var sorted = items.slice()
        sorted.sort(function(left, right) {
            var leftPinned = root.isPinned(left.id) ? 0 : 1
            var rightPinned = root.isPinned(right.id) ? 0 : 1
            if (leftPinned !== rightPinned)
                return leftPinned - rightPinned
            var stateDifference = root.stateRank(left.state) - root.stateRank(right.state)
            if (stateDifference !== 0)
                return stateDifference
            return (Number(right.activityAt) || 0) - (Number(left.activityAt) || 0)
        })
        return sorted
    }

    function syncAgents() {
        root.ensureFirstPins()
        var source = root.adapter && Array.isArray(root.adapter.agents) ? root.adapter.agents : []
        var sorted = root.sortAgents(source)
        if (JSON.stringify(sorted) !== JSON.stringify(root.agents))
            root.agents = sorted
    }

    function collectPinnedAgents() {
        var result = []
        if (!root.agentAvailable)
            return result
        for (var i = 0; i < root.agents.length; i++) {
            if (root.isPinned(root.agents[i].id))
                result.push(root.agents[i])
        }
        return result
    }

    function togglePin(agentId) {
        if (!agentId || root.isAutoPinned(agentId))
            return
        var pins = root.pinnedAgentIds.slice()
        var index = pins.indexOf(agentId)
        if (index === -1)
            pins.push(agentId)
        else
            pins.splice(index, 1)
        root.pinnedAgentIds = pins
        root.syncAgents()
        persistTimer.restart()
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
            root.pinnedAgentIds = Array.isArray(data.pinnedAgentIds) ? data.pinnedAgentIds : []
            root.autoPinnedAgentIds = Array.isArray(data.autoPinnedAgentIds) ? data.autoPinnedAgentIds : []
            root.pinsHidden = data.pinsHidden === true
        } catch (error) {
            root.pinnedAgentIds = []
            root.autoPinnedAgentIds = []
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
        onTriggered: storageFile.setText(JSON.stringify({ pinnedAgentIds: root.pinnedAgentIds, autoPinnedAgentIds: root.autoPinnedAgentIds, pinsHidden: root.pinsHidden }, null, 2) + '\n')
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

    onPinnedAgentIdsChanged: root.syncAgents()
    onAutoPinnedAgentIdsChanged: root.syncAgents()

    Component.onCompleted: {
        root.adapter.panelOpen = root.panelOpen
        root.syncAgents()
    }
}
