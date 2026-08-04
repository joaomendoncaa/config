import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core

Item {
    id: root

    property var agents: []
    property bool agentLoading: true
    property bool agentAvailable: false
    property bool agentRequestPending: false
    property string agentError: ''
    property bool usageLoading: true
    property bool usageAvailable: false
    property bool usageRequestPending: false
    property string usageError: ''
    property bool panelOpen: false
    property string balance: ''
    property string dashboardUrl: ''
    property var usageWindows: []
    property real used5h: 0
    property real usedWeekly: 0
    property real usedMonthly: 0
    property real reset5hAt: 0
    property real resetWeeklyAt: 0
    property real resetMonthlyAt: 0
    property real nowMs: Date.now()

    readonly property string providerName: 'OpenCode'
    readonly property url iconSource: Qt.resolvedUrl('../../../Assets/opencode-logo.svg')
    readonly property bool usageSupported: true
    readonly property string dashboardLabel: 'OPEN DASHBOARD ↗'
    readonly property string balanceLabel: 'BALANCE'
    readonly property string settingsPath: `${Quickshell.env('HOME')}/.config/quickshell/opencode.json`
    readonly property string workspaceId: Config.env.QUICKSHELL_OPENCODE_WORKSPACE_ID || 'wrk_01KEYSE6SWHFGJ2DB8C2690QJ2'
    readonly property string dashboardTarget: root.dashboardUrl || `https://opencode.ai/workspace/${root.workspaceId}/go`
    readonly property string agentsCommand: `${Quickshell.env('HOME')}/.config.jmmm.sh/bin/opencode-agents`
    readonly property string usageCommand: `${Quickshell.env('HOME')}/.config.jmmm.sh/bin/opencode-usage`

    function clamp(value, minimum, maximum) {
        return Math.min(maximum, Math.max(minimum, value))
    }

    function remaining(used) {
        return root.clamp(1 - (Number(used) || 0) / 100, 0, 1)
    }

    function expectedRemaining(resetAt, windowSeconds) {
        if (!root.usageAvailable || resetAt <= 0)
            return 0
        return root.clamp((resetAt - root.nowMs) / (windowSeconds * 1000), 0, 1)
    }

    function rebuildUsageWindows() {
        if (!root.usageAvailable) {
            root.usageWindows = []
            return
        }

        var actual5h = root.remaining(root.used5h)
        var actualWeekly = root.remaining(root.usedWeekly)
        var actualMonthly = root.remaining(root.usedMonthly)
        root.usageWindows = [
            {
                id: '5h',
                label: '5H',
                resetAt: root.reset5hAt,
                actual: actual5h,
                warning: Math.max(0, root.expectedRemaining(root.reset5hAt, 5 * 60 * 60) - actual5h)
            },
            {
                id: 'weekly',
                label: '1W',
                resetAt: root.resetWeeklyAt,
                actual: actualWeekly,
                warning: Math.max(0, root.expectedRemaining(root.resetWeeklyAt, 7 * 24 * 60 * 60) - actualWeekly)
            },
            {
                id: 'monthly',
                label: '1M',
                resetAt: root.resetMonthlyAt,
                actual: actualMonthly,
                warning: Math.max(0, root.expectedRemaining(root.resetMonthlyAt, 30 * 24 * 60 * 60) - actualMonthly)
            }
        ]
    }

    function focusAgent(sessionId) {
        if (!sessionId || focusProc.running)
            return
        focusProc.command = [root.agentsCommand, 'focus', sessionId]
        focusProc.running = true
    }

    function refreshAgents() {
        if (root.agentRequestPending || agentProc.running)
            return
        root.agentRequestPending = true
        agentWatchdog.restart()
        agentProc.running = true
    }

    function parseAgents(output) {
        try {
            var data = JSON.parse(String(output || '{}'))
            if (!data.ok || !Array.isArray(data.agents))
                throw new Error(data.error || 'invalid collector response')

            var normalized = []
            for (var i = 0; i < data.agents.length; i++) {
                var agent = data.agents[i] || {}
                if (!agent.id)
                    continue
                normalized.push({
                    id: agent.id,
                    title: agent.title || 'New session',
                    repo: agent.repo || '',
                    branch: agent.branch || '',
                    state: ['running', 'idle', 'blocked', 'pending', 'unknown'].indexOf(agent.state) === -1 ? 'unknown' : agent.state,
                    additions: Number(agent.additions) || 0,
                    deletions: Number(agent.deletions) || 0,
                    activityAt: Number(agent.activityAt) || 0
                })
            }

            if (JSON.stringify(normalized) !== JSON.stringify(root.agents))
                root.agents = normalized
            root.agentAvailable = true
            root.agentLoading = false
            root.agentRequestPending = false
            root.agentError = ''
            agentWatchdog.stop()
        } catch (error) {
            root.agents = []
            root.agentAvailable = false
            root.agentLoading = false
            root.agentRequestPending = false
            root.agentError = String(error)
            agentWatchdog.stop()
        }
    }

    function refreshUsage() {
        if (root.usageRequestPending || usageProc.running)
            return
        root.usageRequestPending = true
        root.usageLoading = true
        usageWatchdog.restart()
        usageProc.running = true
    }

    function parseUsage(output) {
        try {
            var data = JSON.parse(String(output || '{}'))
            if (!data.ok || !data.usage)
                throw new Error(data.error || 'invalid usage response')

            var fetchedAt = Number(data.fetchedAt) || Date.now()
            var shortWindow = data.usage['5h'] || {}
            var weeklyWindow = data.usage.weekly || {}
            var monthlyWindow = data.usage.monthly || {}
            root.used5h = Number(shortWindow.used) || 0
            root.usedWeekly = Number(weeklyWindow.used) || 0
            root.usedMonthly = Number(monthlyWindow.used) || 0
            root.reset5hAt = fetchedAt + (Number(shortWindow.resetSeconds) || 0) * 1000
            root.resetWeeklyAt = fetchedAt + (Number(weeklyWindow.resetSeconds) || 0) * 1000
            root.resetMonthlyAt = fetchedAt + (Number(monthlyWindow.resetSeconds) || 0) * 1000
            root.balance = data.billing && data.billing.balance ? data.billing.balance : ''
            root.dashboardUrl = data.dashboardUrl || ''
            root.nowMs = Date.now()
            root.usageAvailable = true
            root.usageLoading = false
            root.usageRequestPending = false
            root.usageError = ''
            root.rebuildUsageWindows()
            usageWatchdog.stop()
        } catch (error) {
            root.usageAvailable = false
            root.usageLoading = false
            root.usageRequestPending = false
            root.usageError = String(error)
            root.rebuildUsageWindows()
            usageWatchdog.stop()
        }
    }

    function openDashboard() {
        Quickshell.execDetached(['xdg-open', root.dashboardTarget])
    }

    Process {
        id: agentProc
        command: [root.agentsCommand, 'snapshot']

        stdout: StdioCollector {
            onStreamFinished: root.parseAgents(text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.warn('[OpenCode] collector:', text.trim())
            }
        }

        onExited: function(exitCode) {
            agentWatchdog.stop()
            root.agentRequestPending = false
            if (exitCode !== 0) {
                root.agents = []
                root.agentAvailable = false
                root.agentLoading = false
                root.agentError = 'collector exited with status ' + exitCode
            }
        }
    }

    Process {
        id: focusProc

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.warn('[OpenCode] focus:', text.trim())
            }
        }
    }

    Process {
        id: usageProc
        command: [root.usageCommand]

        stdout: StdioCollector {
            onStreamFinished: root.parseUsage(text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.warn('[OpenCode] usage:', text.trim())
            }
        }

        onExited: function(exitCode) {
            usageWatchdog.stop()
            root.usageRequestPending = false
            if (exitCode !== 0 && root.usageLoading) {
                root.usageAvailable = false
                root.usageLoading = false
                root.usageError = 'usage command exited with status ' + exitCode
                root.rebuildUsageWindows()
            }
        }
    }

    Timer {
        id: agentWatchdog
        interval: 5000
        onTriggered: {
            root.agents = []
            root.agentAvailable = false
            root.agentLoading = false
            root.agentRequestPending = false
            root.agentError = 'collector did not start or finish'
        }
    }

    Timer {
        id: usageWatchdog
        interval: 30000
        onTriggered: {
            root.usageAvailable = false
            root.usageLoading = false
            root.usageRequestPending = false
            root.usageError = 'usage command did not start or finish'
            root.rebuildUsageWindows()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.refreshAgents()
    }

    Timer {
        interval: root.panelOpen ? 60000 : 300000
        running: true
        repeat: true
        onTriggered: root.refreshUsage()
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            root.nowMs = Date.now()
            root.rebuildUsageWindows()
            if (root.usageAvailable && (root.reset5hAt <= root.nowMs || root.resetWeeklyAt <= root.nowMs || root.resetMonthlyAt <= root.nowMs))
                root.refreshUsage()
        }
    }

    onPanelOpenChanged: {
        if (root.panelOpen)
            root.refreshUsage()
    }

    Component.onCompleted: {
        root.refreshAgents()
        root.refreshUsage()
    }
}
