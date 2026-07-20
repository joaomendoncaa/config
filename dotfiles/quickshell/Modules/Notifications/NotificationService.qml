import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.Core
import "NotificationLogic.js" as N

Item {
    id: service

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell/"
    readonly property string historyPath: stateDir + "notifications.json"
    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/quickshell/"
    readonly property string imageCacheDir: cacheDir + "notification-images/"

    readonly property int cornerRadius: Config.borderRadius

    signal historyOpenRequested()

    property bool popupsBlocked: false

    property bool _hydrating: false

    PersistentProperties {
        id: persisted
        reloadableId: "quickshell-notifications"
        property bool doNotDisturb: false
        onDoNotDisturbChanged: {
            if (service._hydrating) return
            service.scheduleHistorySave()
        }
    }

    readonly property alias doNotDisturb: persisted.doNotDisturb

    function setDoNotDisturb(value) {
        persisted.doNotDisturb = !!value
    }

    property int _fyiSeq: 0
    property var _fyiGroups: ({})

    function fyi(summary, body, urgency, expireTimeout, command, group) {
        group = String(group || "")
        if (group) {
            var oldId = service._fyiGroups[group]
            if (oldId !== undefined) {
                service.dismissPendingByOriginalId(oldId)
                for (var pi = 0; pi < popupModel.count; pi++) {
                    var pe = popupModel.get(pi)
                    if (pe && pe.originalId === oldId) {
                        service.dismissPopup(pi)
                        break
                    }
                }
                delete service._fyiGroups[group]
            }
        }

        var id = --service._fyiSeq
        var snapshot = {
            id: id,
            originalId: id,
            app: "fyi",
            appIcon: "",
            summary: String(summary || ""),
            body: String(body || ""),
            image: "",
            glyph: "",
            urgency: typeof urgency === "number" ? urgency : NotificationUrgency.Normal,
            expireTimeout: typeof expireTimeout === "number" ? expireTimeout : 0,
            timestamp: Date.now(),
            _clickCommand: String(command || "")
        }
        snapshot.contentHash = N.contentHash(snapshot)
        snapshot.duplicateCount = 1
        setRef(id, null)
        addToPending(snapshot)
        if (snapshot.expireTimeout > 0)
            schedulePendingExpiry(snapshot.contentHash, id, snapshot.expireTimeout)
        if (!service.doNotDisturb) {
            Qt.callLater(function() {
                if (service.popupsBlocked) return
                upsertPopup(snapshot)
            })
        }
        if (group) {
            service._fyiGroups[group] = id
        }
    }

    property alias popupModel: popupModel
    property alias pendingModel: pendingModel
    property alias pastModel: pastModel

    ListModel { id: popupModel }
    ListModel { id: pendingModel }
    ListModel { id: pastModel }

    property var _refs: ({})

    function setRef(id, ref) {
        _refs[id] = ref || null
    }

    function getRef(id) {
        var r = _refs[id]
        if (r === undefined) return null
        return r
    }

    function removeRef(id) {
        delete _refs[id]
    }

    readonly property int historyCap: 100
    property var imageCacheQueue: []

    readonly property int lowPopupDuration: 5000
    readonly property int normalPopupDuration: 8000
    readonly property int maxPopupDuration: 30000

    function durationFor(urgency, expireTimeout) {
        switch (urgency) {
        case NotificationUrgency.Critical:
            return 0
        case NotificationUrgency.Low:
            return Math.min(maxPopupDuration, Math.max(lowPopupDuration, requestedDuration(expireTimeout)))
        default:
            return Math.min(maxPopupDuration, Math.max(normalPopupDuration, requestedDuration(expireTimeout)))
        }
    }

    function requestedDuration(expireTimeout) {
        var seconds = Number(expireTimeout || 0)
        if (!isFinite(seconds) || seconds <= 0) return 0
        return Math.round(seconds * 1000)
    }

    function shouldBypassDnd(notification) {
        return N.shouldBypassDnd(notification, NotificationUrgency.Critical)
    }

    function snapshotOf(notification) {
        return N.snapshotOf(notification, Date.now())
    }

    // Merge duplicate notifications by content hash: if a pending card with the
    // same content already exists, bump its duplicate count and refresh its
    // id/timestamp/ref in place (position preserved). Otherwise insert at 0.
    function upsertPending(snapshot) {
        var hash = snapshot.contentHash || N.contentHash(snapshot)
        var newRef = getRef(snapshot.id)
        for (var i = 0; i < pendingModel.count; i++) {
            var row = pendingModel.get(i)
            if (row && row.contentHash === hash) {
                var merged = service.snapshotFromRow(row)
                var oldId = merged.id
                merged.id = snapshot.id
                merged.originalId = snapshot.originalId
                merged.timestamp = snapshot.timestamp
                merged.duplicateCount = (row.duplicateCount || 1) + 1
                merged._clickCommand = snapshot._clickCommand || row._clickCommand || ""
                removeRef(oldId)
                setRef(merged.id, newRef)
                pendingModel.set(i, merged)
                return
            }
        }
        var fresh = {
            id: snapshot.id,
            originalId: snapshot.originalId,
            app: snapshot.app,
            appIcon: snapshot.appIcon,
            summary: snapshot.summary,
            body: snapshot.body,
            image: snapshot.image,
            glyph: snapshot.glyph || "",
            urgency: snapshot.urgency,
            expireTimeout: snapshot.expireTimeout || 0,
            timestamp: snapshot.timestamp,
            contentHash: hash,
            duplicateCount: snapshot.duplicateCount || 1,
            _clickCommand: snapshot._clickCommand || ""
        }
        setRef(fresh.id, newRef)
        pendingModel.insert(0, fresh)
    }

    // Same merge-by-contentHash strategy for floating popup toasts. When a
    // duplicate arrives, the existing popup is updated in place (count bumped,
    // ref/timestamp refreshed) and the stale old ref is dismissed so the DBus
    // server doesn't leak tracked notifications.
    function upsertPopup(snapshot) {
        var hash = snapshot.contentHash || N.contentHash(snapshot)
        var newRef = getRef(snapshot.id)
        for (var i = 0; i < popupModel.count; i++) {
            var row = popupModel.get(i)
            if (row && row.contentHash === hash) {
                var oldRef = getRef(row.id)
                var merged = service.snapshotFromRow(row)
                var oldId = merged.id
                merged.id = snapshot.id
                merged.originalId = snapshot.originalId
                merged.timestamp = snapshot.timestamp
                merged.expireTimeout = snapshot.expireTimeout || 0
                merged.duplicateCount = (row.duplicateCount || 1) + 1
                merged._clickCommand = snapshot._clickCommand || row._clickCommand || ""
                removeRef(oldId)
                setRef(merged.id, newRef)
                popupModel.set(i, merged)
                if (oldRef && oldRef !== newRef) {
                    try { if (oldRef.tracked) oldRef.dismiss() } catch (e) {}
                }
                return
            }
        }
        var fresh = {
            id: snapshot.id,
            originalId: snapshot.originalId,
            app: snapshot.app,
            appIcon: snapshot.appIcon,
            summary: snapshot.summary,
            body: snapshot.body,
            image: snapshot.image,
            glyph: snapshot.glyph || "",
            urgency: snapshot.urgency,
            expireTimeout: snapshot.expireTimeout || 0,
            timestamp: snapshot.timestamp,
            contentHash: hash,
            duplicateCount: snapshot.duplicateCount || 1,
            _clickCommand: snapshot._clickCommand || ""
        }
        setRef(fresh.id, newRef)
        popupModel.insert(0, fresh)
    }

    function handleNotification(notification) {
        notification.tracked = true
        var snapshot = snapshotOf(notification)
        setRef(snapshot.id, notification)

        var transient = !!notification.transient
        var appName = String(notification.appName || "")
        var ephemeralApp = N.isEphemeralApp(appName)

        if (transient || ephemeralApp) {
            if (service.doNotDisturb && !shouldBypassDnd(notification)) {
                notification.tracked = false
                return
            }
            Qt.callLater(function() {
                if (service.popupsBlocked) return
                upsertPopup(snapshot)
            })
            return
        }

        addToPending(snapshot)
        maybeCacheImage(snapshot)

        if (service.doNotDisturb && !shouldBypassDnd(notification)) {
            notification.tracked = false
            return
        }

        Qt.callLater(function() {
            if (service.popupsBlocked) return
            upsertPopup(snapshot)
        })
    }

    function addToPending(snapshot) {
        Qt.callLater(function() {
            upsertPending(snapshot)
            while (pendingModel.count > service.historyCap) {
                var trimmed = pendingModel.get(pendingModel.count - 1)
                if (trimmed) removeRef(trimmed.id)
                pendingModel.remove(pendingModel.count - 1)
            }
            scheduleHistorySave()
        })
    }

    function snapshotFromRow(row) {
        return {
            id: row.id,
            originalId: row.originalId,
            app: row.app,
            appIcon: row.appIcon,
            summary: row.summary,
            body: row.body,
            image: row.image,
            glyph: row.glyph || "",
            urgency: row.urgency,
            expireTimeout: row.expireTimeout || 0,
            timestamp: row.timestamp,
            contentHash: row.contentHash || N.contentHash(row),
            duplicateCount: row.duplicateCount || 1,
            _clickCommand: row._clickCommand || ""
        }
    }

    function markSeenByOriginalId(originalId) {
        Qt.callLater(function() {
            for (var i = 0; i < pendingModel.count; i++) {
                var entry = pendingModel.get(i)
                if (!entry || entry.originalId !== originalId) continue
                var snapshot = service.snapshotFromRow(entry)
                pendingModel.remove(i)
                removeRef(entry.id)
                pastModel.insert(0, snapshot)
                while (pastModel.count > service.historyCap) {
                    pastModel.remove(pastModel.count - 1)
                }
                scheduleHistorySave()
                return
            }
        })
    }

    function markAllSeen() {
        Qt.callLater(function() {
            while (pendingModel.count > 0) {
                var entry = pendingModel.get(0)
                var snapshot = service.snapshotFromRow(entry)
                pendingModel.remove(0)
                removeRef(entry.id)
                pastModel.insert(0, snapshot)
            }
            while (pastModel.count > service.historyCap) {
                pastModel.remove(pastModel.count - 1)
            }
            scheduleHistorySave()
        })
    }

    function dismissPopup(index) {
        removePopup(index, "dismiss")
    }

    function expirePopup(index) {
        removePopup(index, "expire")
    }

    function removePopup(index, reason) {
        if (index < 0 || index >= popupModel.count) return
        var entry = popupModel.get(index)
        var ref = entry ? getRef(entry.id) : null
        var originalId = entry ? entry.originalId : -1
        popupModel.remove(index)
        if (entry) removeRef(entry.id)
        if (ref) {
            try {
                if (ref.tracked) {
                    if (reason === "expire" && typeof ref.expire === "function") ref.expire()
                    else ref.dismiss()
                }
            } catch (e) {}
        }
        if (originalId >= 0) markSeenByOriginalId(originalId)
    }

    function clearPopups() {
        while (popupModel.count > 0) dismissPopup(0)
    }

    function dismissPending(index) {
        if (index < 0 || index >= pendingModel.count) return
        var entry = pendingModel.get(index)
        if (entry) {
            maybeDeleteCachedImage(entry.image)
            removeRef(entry.id)
        }
        pendingModel.remove(index)
        scheduleHistorySave()
    }

    function dismissPendingByOriginalId(originalId) {
        for (var i = 0; i < pendingModel.count; i++) {
            var entry = pendingModel.get(i)
            if (entry && entry.originalId === originalId) {
                dismissPending(i)
                return
            }
        }
    }

    property var _expiryTimers: ({})

    function schedulePendingExpiry(contentHash, originalId, timeoutSeconds) {
        if (_expiryTimers[contentHash]) {
            _expiryTimers[contentHash].destroy()
            delete _expiryTimers[contentHash]
        }
        var timer = expiryTimerComponent.createObject(service, {
            interval: timeoutSeconds * 1000,
            targetOriginalId: originalId
        })
        _expiryTimers[contentHash] = timer
        timer.running = true
    }

    function _cleanupExpiryTimer(timer) {
        for (var key in service._expiryTimers) {
            if (service._expiryTimers[key] === timer) {
                delete service._expiryTimers[key]
                break
            }
        }
    }

    Component {
        id: expiryTimerComponent
        Timer {
            repeat: false
            property int targetOriginalId: 0
            onTriggered: {
                service.dismissPendingByOriginalId(targetOriginalId)
                service._cleanupExpiryTimer(this)
                destroy()
            }
        }
    }

    function dismissPast(index) {
        if (index < 0 || index >= pastModel.count) return
        var entry = pastModel.get(index)
        if (entry) maybeDeleteCachedImage(entry.image)
        pastModel.remove(index)
        scheduleHistorySave()
    }

    function clearPending() {
        Qt.callLater(function() {
            for (var i = 0; i < pendingModel.count; i++) {
                var entry = pendingModel.get(i)
                if (entry) {
                    maybeDeleteCachedImage(entry.image)
                    removeRef(entry.id)
                }
            }
            pendingModel.clear()
            scheduleHistorySave()
        })
    }

    function clearPast() {
        Qt.callLater(function() {
            for (var i = 0; i < pastModel.count; i++) {
                var entry = pastModel.get(i)
                if (entry) maybeDeleteCachedImage(entry.image)
            }
            pastModel.clear()
            scheduleHistorySave()
        })
    }

    function invokePopupDefault(index) {
        if (index < 0 || index >= popupModel.count) return
        var entry = popupModel.get(index)
        var ref = entry ? getRef(entry.id) : null
        var invoked = false
        var logParts = ["app=" + (entry ? entry.app : "?"), "id=" + (entry ? entry.id : "?")]
        if (ref) {
            if (ref.actions) {
                logParts.push("actions_count=" + ref.actions.length)
                for (var i = 0; i < ref.actions.length; i++) {
                    var action = ref.actions[i]
                    if (action && action.identifier === "default") {
                        try { action.invoke(); invoked = true } catch (e) { logParts.push("invoke_error=" + e) }
                        break
                    }
                }
            } else {
                logParts.push("ref_exists_no_actions")
            }
        } else {
            logParts.push("ref_null")
        }
        if (!invoked) {
            var cmd = entry ? String(entry._clickCommand || "") : ""
            if (cmd) {
                logParts.push("fyi_cmd=" + cmd)
                var home = Quickshell.env("HOME")
                fyiActionProc.command = [
                    "sh", "-c",
                    "PATH=" + home + "/.config.jmmm.sh/bin:/usr/local/bin:/usr/bin:/bin; " + cmd
                ]
                fyiActionProc.running = true
                invoked = true
            } else {
                logParts.push("focusApp")
                focusApp(entry)
            }
        } else {
            logParts.push("handled_by_action")
        }
        logParts.push("invoked=" + invoked)
        var refKeys = Object.keys(_refs)
        logParts.push("refs_count=" + refKeys.length)
        logParts.push("ref_keys=[" + refKeys.join(",") + "]")
        debugProc.command = ["sh", "-c", "echo '" + logParts.join(" | ") + "' >> /tmp/notif-debug.log"]
        debugProc.running = true
        dismissPopup(index)
    }

    function focusApp(entry) {
        if (!entry || !entry.app) return
        var home = Quickshell.env("HOME")
        focusAppProc.command = [
            home + "/.config.jmmm.sh/bin/hyprland-focus-app",
            String(entry.app)
        ]
        focusAppProc.running = true
    }

    Process { id: focusAppProc; running: false }
    Process { id: fyiActionProc; running: false }
    Process { id: debugProc; running: false }

    // Image caching
    function imageExtension(srcPath) {
        return N.imageExtension(srcPath)
    }

    function maybeCacheImage(snapshot) {
        var image = String(snapshot.image || "")
        if (!image) return
        if (image.indexOf("image://") === 0) return
        if (image.indexOf("file:///tmp/") !== 0) return

        var srcPath = decodeURIComponent(image.substring(7))
        var ext = imageExtension(srcPath)
        var destPath = imageCacheDir + snapshot.timestamp + "-" + snapshot.originalId + "." + ext
        var destUri = "file://" + destPath

        imageCacheQueue = imageCacheQueue.concat([{
            srcPath: srcPath,
            destPath: destPath,
            targetUri: destUri,
            originalId: snapshot.originalId,
            timestamp: snapshot.timestamp
        }])
        runNextImageCacheJob()
    }

    function runNextImageCacheJob() {
        if (imageCacheProc.running || imageCacheQueue.length === 0) return

        var job = imageCacheQueue[0]
        imageCacheQueue = imageCacheQueue.slice(1)
        imageCacheProc.targetUri = job.targetUri
        imageCacheProc.matchOriginalId = job.originalId
        imageCacheProc.matchTimestamp = job.timestamp
        imageCacheProc.command = ["cp", "-f", job.srcPath, job.destPath]
        imageCacheProc.running = true
    }

    function rewriteCachedImage(targetUri, originalId, timestamp) {
        function rewrite(model) {
            for (var i = 0; i < model.count; i++) {
                var row = model.get(i)
                if (row && row.originalId === originalId && row.timestamp === timestamp) {
                    model.setProperty(i, "image", targetUri)
                    return true
                }
            }
            return false
        }
        return rewrite(pendingModel) || rewrite(pastModel)
    }

    function maybeDeleteCachedImage(image) {
        var path = String(image || "")
        if (!path) return
        if (path.indexOf("file://") !== 0) return
        var local = decodeURIComponent(path.substring(7))
        if (local.indexOf(imageCacheDir) !== 0) return
        deleteImageProc.command = ["rm", "-f", local]
        deleteImageProc.running = true
    }

    Process {
        id: ensureDirsProc
        command: ["mkdir", "-p", service.stateDir, service.imageCacheDir]
        running: false
    }

    Process {
        id: imageCacheProc
        property string targetUri: ""
        property int matchOriginalId: -1
        property double matchTimestamp: 0
        onExited: function(exitCode) {
            if (exitCode === 0 && targetUri && rewriteCachedImage(targetUri, matchOriginalId, matchTimestamp))
                scheduleHistorySave()
            targetUri = ""
            matchOriginalId = -1
            matchTimestamp = 0
            runNextImageCacheJob()
        }
    }

    Process { id: deleteImageProc; running: false }

    // History persistence
    FileView {
        id: historyFile
        path: service.historyPath
        watchChanges: false
        atomicWrites: true
        printErrors: false
        onLoaded: service.loadHistory(text())
        onLoadFailed: service.loadHistory("")
    }

    Timer {
        id: historySaveTimer
        interval: 200
        repeat: false
        onTriggered: service.flushHistory()
    }

    readonly property int pastTtlMs: 15 * 60 * 1000

    Timer {
        id: pastPruneTimer
        interval: 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: service.prunePast()
    }

    function prunePast() {
        if (pastModel.count === 0) return
        var cutoff = Date.now() - service.pastTtlMs
        var removed = false
        for (var i = pastModel.count - 1; i >= 0; i--) {
            var entry = pastModel.get(i)
            if (entry && entry.timestamp && entry.timestamp < cutoff) {
                if (entry.image) maybeDeleteCachedImage(entry.image)
                pastModel.remove(i)
                removed = true
            }
        }
        if (removed) scheduleHistorySave()
    }

    function scheduleHistorySave() {
        if (!service.historyLoaded) return
        historySaveTimer.restart()
    }

    property bool historyLoaded: false

    function loadHistory(raw) {
        if (service.historyLoaded) return

        var parsed = N.parseHistory(raw, NotificationUrgency.Normal, service.historyCap)
        if (parsed.empty) {
            service.historyLoaded = true
            return
        }
        if (parsed.error) {
            console.warn("notifications: history parse failed:", parsed.errorMessage || "")
            service.historyLoaded = true
            return
        }

        if (parsed.dnd !== null) {
            service._hydrating = true
            persisted.doNotDisturb = parsed.dnd
            service._hydrating = false
        }

        Qt.callLater(function() {
            for (var i = 0; i < parsed.pending.length; i++) pendingModel.append(parsed.pending[i])
            for (var j = 0; j < parsed.past.length; j++) pastModel.append(parsed.past[j])
            service.historyLoaded = true
            if (parsed.hadDuplicates) service.scheduleHistorySave()
        })
    }

    function flushHistory() {
        function dump(model) {
            var out = []
            for (var i = 0; i < model.count; i++) {
                var r = model.get(i)
                if (!r) continue
                out.push({
                    id: r.id,
                    originalId: r.originalId,
                    app: r.app,
                    appIcon: r.appIcon,
                    summary: r.summary,
                    body: r.body,
                    image: r.image,
                    glyph: r.glyph || "",
                    urgency: r.urgency,
                    expireTimeout: r.expireTimeout || 0,
                    timestamp: r.timestamp,
                    contentHash: r.contentHash || "",
                    duplicateCount: r.duplicateCount || 1
                })
            }
            return out
        }
        var payload = {
            version: 2,
            dnd: persisted.doNotDisturb,
            pending: dump(pendingModel),
            past: dump(pastModel)
        }
        historyFile.setText(JSON.stringify(payload, null, 2) + "\n")
    }

    Component.onCompleted: {
        ensureDirsProc.running = true
        Qt.callLater(function() { historyFile.reload() })
    }

    // IPC handler
    IpcHandler {
        target: "notifications"

        function dndState(): string {
            return service.doNotDisturb ? "on" : "off"
        }

        function toggleDnd(): string {
            service.setDoNotDisturb(!service.doNotDisturb)
            return dndState()
        }

        function setDnd(value: string): string {
            var v = String(value || "").toLowerCase()
            var on = v === "true" || v === "1" || v === "on" || v === "yes"
            service.setDoNotDisturb(on)
            return dndState()
        }

        function isDnd(): string {
            return dndState()
        }

        function showHistory(): string {
            service.historyOpenRequested()
            return "ok"
        }

        function clear(): string {
            service.clearPast()
            return "ok"
        }

        function clearPending(): string {
            service.clearPending()
            return "ok"
        }

        function markAllSeen(): string {
            service.markAllSeen()
            return "ok"
        }

        function dismissAll(): string {
            service.clearPopups()
            service.clearPending()
            service.clearPast()
            return "ok"
        }

        function dismissOne(): string {
            if (popupModel.count > 0) {
                service.dismissPopup(0)
                return "ok"
            }
            if (pendingModel.count > 0) {
                service.dismissPending(0)
                return "ok"
            }
            if (pastModel.count > 0) {
                service.dismissPast(0)
                return "ok"
            }
            return "none"
        }

        function invokeLast(): string {
            if (popupModel.count === 0) return "none"
            service.invokePopupDefault(0)
            return "ok"
        }

        function dismiss(summary: string): string {
            var needle = String(summary || "")
            if (!needle) return "none"
            var hit = false
            function sweep(model, dismissFn) {
                for (var i = model.count - 1; i >= 0; i--) {
                    var row = model.get(i)
                    if (row && String(row.summary || "").indexOf(needle) !== -1) {
                        dismissFn(i)
                        hit = true
                    }
                }
            }
            sweep(pendingModel, service.dismissPending)
            sweep(pastModel, service.dismissPast)
            sweep(popupModel, service.dismissPopup)
            return hit ? "ok" : "none"
        }

        function fyi(summary: string, body: string, urgency: string, expiry: string, command: string, group: string): string {
            var u = NotificationUrgency.Normal
            var urg = String(urgency || "").toLowerCase()
            if (urg === "low" || urg === "0") u = NotificationUrgency.Low
            else if (urg === "critical" || urg === "2") u = NotificationUrgency.Critical
            var e = Number(expiry || 0)
            if (!isFinite(e) || e < 0) e = 0
            service.fyi(summary, body, u, e, command, group)
            return "ok"
        }

        function ping(): string { return "ok" }
    }

    // Notification server (DBus, freedesktop spec)
    NotificationServer {
        id: server
        keepOnReload: false
        imageSupported: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        persistenceSupported: true

        onNotification: function(notification) {
            service.handleNotification(notification)
        }
    }

    // Per-screen popup PanelWindows for toast rendering
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: popupWindow
            required property var modelData
            screen: modelData
            visible: popupModel.count > 0

            WlrLayershell.namespace: "quickshell-notifications"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            anchors.right: true
            anchors.top: true
            margins.top: Config.height + Config.shellPadding + Config.gapsOut
            margins.right: Config.shellPadding

            implicitWidth: popupColumn.implicitWidth
            implicitHeight: popupColumn.implicitHeight

            ColumnLayout {
                id: popupColumn
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 8

                Repeater {
                    model: popupModel

                    delegate: Item {
                        id: cardSlot
                        required property int index
                        required property string app
                        required property string appIcon
                        required property string summary
                        required property string body
                        required property string image
                        required property string glyph
                        required property int urgency
                        required property double expireTimeout
                        required property double timestamp
                        required property int duplicateCount

                        Layout.preferredWidth: card.implicitWidth
                        Layout.alignment: Qt.AlignRight
                        implicitHeight: card.implicitHeight

                        readonly property real lifetime: cardSlot.expireTimeout > 0
                            ? Math.round(cardSlot.expireTimeout * 1000)
                            : service.durationFor(cardSlot.urgency, cardSlot.expireTimeout)
                        property real remainingLifetime: 1.0
                        readonly property bool ticking: cardSlot.lifetime > 0 && !card.hovered
                        property bool _stopped: false

                        onDuplicateCountChanged: {
                            if (cardSlot.duplicateCount > 1)
                                cardSlot.remainingLifetime = 1.0
                        }

                        Timer {
                            interval: 50
                            repeat: true
                            running: cardSlot.ticking
                            onTriggered: {
                                if (cardSlot._stopped || popupModel.count <= cardSlot.index) return
                                if (cardSlot.lifetime <= 0) return
                                cardSlot.remainingLifetime -= 50.0 / cardSlot.lifetime
                                if (cardSlot.remainingLifetime <= 0) {
                                    cardSlot.remainingLifetime = 0
                                    cardSlot._stopped = true
                                    service.expirePopup(cardSlot.index)
                                }
                            }
                        }

                        NotificationCard {
                            id: card
                            anchors.right: parent.right
                            app: cardSlot.app
                            appIcon: cardSlot.appIcon
                            summary: cardSlot.summary
                            body: cardSlot.body
                            image: cardSlot.image
                            urgency: cardSlot.urgency
                            timestamp: cardSlot.timestamp
                            expireTimeout: cardSlot.expireTimeout
                            duplicateCount: cardSlot.duplicateCount
                            cornerRadius: service.cornerRadius
                            glyph: cardSlot.glyph

                            onCloseRequested: {
                                cardSlot._stopped = true
                                service.dismissPopup(cardSlot.index)
                            }
                            onCardClicked: {
                                cardSlot._stopped = true
                                service.invokePopupDefault(cardSlot.index)
                            }
                        }
                    }
                }
            }
        }
    }
}
