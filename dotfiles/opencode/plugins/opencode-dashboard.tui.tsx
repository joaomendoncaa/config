import { basename, join } from 'node:path'
import { mkdir, readFile, readlink, rename, unlink, writeFile } from 'node:fs/promises'

const POLL_INTERVAL = 500
const FAMILY_REFRESH_INTERVAL = 2000

function responseData(response) {
    if (response && typeof response === 'object' && 'data' in response)
        return response.data
    return response
}

function isAbortedError(error) {
    if (!error)
        return false
    return JSON.stringify(error).includes('MessageAbortedError')
}

async function ttyPath() {
    try {
        return await readlink('/proc/self/fd/0')
    } catch {
        return ''
    }
}

async function processStartTicks() {
    try {
        const stat = await readFile('/proc/self/stat', 'utf8')
        const fields = stat.slice(stat.lastIndexOf(') ') + 2).trim().split(/\s+/)
        return fields[19] || ''
    } catch {
        return ''
    }
}

export default {
    id: 'jmmm.opencode-dashboard',
    tui: async api => {
        const uid = typeof process.getuid === 'function' ? process.getuid() : 0
        const runtimeBase = process.env.XDG_RUNTIME_DIR || `/tmp/opencode-dashboard-${uid}`
        const runtimeDir = join(runtimeBase, 'opencode-dashboard')
        const nonce = crypto.randomUUID()
        const statePath = join(runtimeDir, `tui-${process.pid}-${nonce}.json`)
        const temporaryPath = `${statePath}.tmp`
        const startedAt = Date.now()
        const tty = await ttyPath()
        const startTicks = await processStartTicks()

        const runtimeByRoot = new Map()
        const familyByRoot = new Map()
        const familyUpdatedAt = new Map()
        const rootBySession = new Map()
        let currentRootID = ''
        let updateRunning = false
        let activeUpdate = null
        let pendingRecord = null
        let writeRunning = false
        let activeWrite = Promise.resolve()
        let disposed = false

        await mkdir(runtimeDir, { recursive: true, mode: 0o700 })

        function runtimeState(rootID, info) {
            if (!runtimeByRoot.has(rootID)) {
                runtimeByRoot.set(rootID, {
                    turnStarted: false,
                    error: false,
                    busy: false,
                    state: 'idle',
                    activityAt: info?.time?.updated || startedAt
                })
            }
            return runtimeByRoot.get(rootID)
        }

        async function sessionInfo(sessionID) {
            const cached = api.state.session.get(sessionID)
            if (cached)
                return cached
            try {
                return responseData(await api.client.session.get({ sessionID }))
            } catch {
                return null
            }
        }

        async function rootInfo(selected) {
            let info = selected
            const visited = new Set()
            while (info?.parentID && !visited.has(info.id)) {
                visited.add(info.id)
                const parent = await sessionInfo(info.parentID)
                if (!parent)
                    break
                info = parent
            }
            return info
        }

        async function refreshFamily(root) {
            const now = Date.now()
            if (familyByRoot.has(root.id) && now - (familyUpdatedAt.get(root.id) || 0) < FAMILY_REFRESH_INTERVAL)
                return familyByRoot.get(root.id)

            const family = [root]
            const queue = [root.id]
            const seen = new Set(queue)
            while (queue.length > 0) {
                const sessionID = queue.shift()
                let children = []
                try {
                    children = responseData(await api.client.session.children({ sessionID })) || []
                } catch {
                    children = []
                }
                for (const child of children) {
                    if (!child?.id || seen.has(child.id))
                        continue
                    seen.add(child.id)
                    family.push(child)
                    queue.push(child.id)
                }
            }

            for (const session of family)
                rootBySession.set(session.id, root.id)
            familyByRoot.set(root.id, family)
            familyUpdatedAt.set(root.id, now)
            return family
        }

        function sessionDiff(session) {
            const live = api.state.session.diff(session.id)
            if (Array.isArray(live) && live.length > 0)
                return live
            return Array.isArray(session.summary?.diffs) ? session.summary.diffs : []
        }

        function aggregateDiff(family) {
            const files = new Map()
            for (const session of family) {
                for (const diff of sessionDiff(session)) {
                    const key = diff.file || `${session.id}:${files.size}`
                    const previous = files.get(key) || { additions: 0, deletions: 0 }
                    files.set(key, {
                        additions: Math.max(previous.additions, Number(diff.additions) || 0),
                        deletions: Math.max(previous.deletions, Number(diff.deletions) || 0)
                    })
                }
            }

            if (files.size === 0) {
                return family.reduce((total, session) => ({
                    additions: total.additions + (Number(session.summary?.additions) || 0),
                    deletions: total.deletions + (Number(session.summary?.deletions) || 0)
                }), { additions: 0, deletions: 0 })
            }

            return Array.from(files.values()).reduce((total, diff) => ({
                additions: total.additions + diff.additions,
                deletions: total.deletions + diff.deletions
            }), { additions: 0, deletions: 0 })
        }

        function deriveState(root, family) {
            const runtime = runtimeState(root.id, root)
            const running = family.some(session => api.state.session.status(session.id)?.type === 'busy')
            if (running && !runtime.busy)
                runtime.error = false
            runtime.busy = running
            const blocked = runtime.error || family.some(session => {
                const status = api.state.session.status(session.id)
                const permissions = api.state.session.permission(session.id) || []
                const questions = api.state.session.question(session.id) || []
                return status?.type === 'retry' || permissions.length > 0 || questions.length > 0
            })
            let nextState = runtime.state
            if (blocked) {
                runtime.turnStarted = true
                nextState = 'blocked'
            } else if (running) {
                runtime.turnStarted = true
                runtime.error = false
                nextState = 'running'
            } else {
                nextState = runtime.turnStarted ? 'pending' : 'idle'
            }

            if (nextState !== runtime.state) {
                runtime.state = nextState
                runtime.activityAt = Date.now()
            }
            return runtime
        }

        function queueWrite(record) {
            if (disposed || api.lifecycle.signal.aborted)
                return
            pendingRecord = record
            if (writeRunning)
                return
            writeRunning = true
            activeWrite = (async () => {
                while (pendingRecord && !disposed) {
                    const next = pendingRecord
                    pendingRecord = null
                    await writeFile(temporaryPath, `${JSON.stringify(next)}\n`, { mode: 0o600 })
                    await rename(temporaryPath, statePath)
                }
            })().catch(() => {}).finally(() => {
                writeRunning = false
                if (pendingRecord && !disposed)
                    queueWrite(pendingRecord)
            })
        }

        async function update() {
            if (updateRunning || disposed || api.lifecycle.signal.aborted)
                return
            updateRunning = true
            try {
                const route = api.route.current
                if (route.name !== 'session' || !route.params?.sessionID) {
                    currentRootID = ''
                    queueWrite({
                        schema: 1,
                        pid: process.pid,
                        processStartTicks: startTicks,
                        nonce,
                        startedAt,
                        heartbeatAt: Date.now(),
                        tty,
                        version: api.app.version,
                        route: route.name || 'home'
                    })
                    return
                }

                const selectedSessionID = route.params.sessionID
                const selected = await sessionInfo(selectedSessionID)
                if (!selected) {
                    currentRootID = ''
                    queueWrite({
                        schema: 1,
                        pid: process.pid,
                        processStartTicks: startTicks,
                        nonce,
                        startedAt,
                        heartbeatAt: Date.now(),
                        tty,
                        version: api.app.version,
                        route: 'session',
                        selectedSessionID
                    })
                    return
                }

                const resolvedRoot = await rootInfo(selected)
                if (!resolvedRoot)
                    return
                currentRootID = resolvedRoot.id
                rootBySession.set(selectedSessionID, resolvedRoot.id)

                const family = await refreshFamily(resolvedRoot)
                const runtime = deriveState(resolvedRoot, family)
                const diff = aggregateDiff(family)
                const worktree = api.state.path.worktree || resolvedRoot.directory || ''
                const rawRepo = basename(worktree || resolvedRoot.directory || '')
                const repo = rawRepo.replace(/@[^@]+$/, '')

                queueWrite({
                    schema: 1,
                    pid: process.pid,
                    processStartTicks: startTicks,
                    nonce,
                    startedAt,
                    heartbeatAt: Date.now(),
                    tty,
                    version: api.app.version,
                    route: 'session',
                    selectedSessionID,
                    rootSessionID: resolvedRoot.id,
                    title: resolvedRoot.title || 'New session',
                    directory: resolvedRoot.directory || api.state.path.directory || '',
                    worktree,
                    repo,
                    branch: api.state.vcs?.branch || '',
                    state: runtime.state,
                    additions: diff.additions,
                    deletions: diff.deletions,
                    activityAt: runtime.activityAt,
                    createdAt: resolvedRoot.time?.created || 0
                })
            } catch {
                if (currentRootID) {
                    const runtime = runtimeByRoot.get(currentRootID)
                    if (runtime)
                        runtime.state = 'unknown'
                }
            } finally {
                updateRunning = false
            }
        }

        function requestUpdate() {
            if (updateRunning || disposed || api.lifecycle.signal.aborted)
                return
            activeUpdate = update().finally(() => {
                activeUpdate = null
            })
        }

        const refreshEvents = [
            'session.status',
            'session.idle',
            'session.updated',
            'session.diff',
            'permission.asked',
            'permission.replied',
            'question.asked',
            'question.replied',
            'question.rejected'
        ]
        for (const eventName of refreshEvents) {
            api.event.on(eventName, event => {
                const sessionID = event.properties?.sessionID || event.properties?.info?.id
                const rootID = rootBySession.get(sessionID)
                const runtime = rootID ? runtimeByRoot.get(rootID) : null
                if (runtime)
                    runtime.activityAt = Date.now()
                requestUpdate()
            })
        }

        api.event.on('session.error', event => {
            void (async () => {
                if (isAbortedError(event.properties?.error)) {
                    requestUpdate()
                    return
                }

                const sessionID = event.properties?.sessionID || ''
                let rootID = rootBySession.get(sessionID) || ''
                if (sessionID && !rootID) {
                    const info = await sessionInfo(sessionID)
                    const root = info ? await rootInfo(info) : null
                    rootID = root?.id || ''
                } else if (!sessionID && currentRootID) {
                    const family = familyByRoot.get(currentRootID) || []
                    const currentBusy = family.some(session => api.state.session.status(session.id)?.type === 'busy')
                    rootID = currentBusy ? currentRootID : ''
                }

                if (rootID) {
                    const runtime = runtimeState(rootID, null)
                    runtime.error = true
                    runtime.turnStarted = true
                    runtime.state = 'blocked'
                    runtime.activityAt = Date.now()
                }
                requestUpdate()
            })().catch(() => {})
        })

        const interval = setInterval(requestUpdate, POLL_INTERVAL)
        api.lifecycle.onDispose(async () => {
            disposed = true
            clearInterval(interval)
            pendingRecord = null
            await Promise.allSettled([activeUpdate, activeWrite])
            await Promise.allSettled([unlink(statePath), unlink(temporaryPath)])
        })

        requestUpdate()
    }
}
