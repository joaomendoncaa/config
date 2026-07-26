import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.Core
import "NotificationLogic.js" as N

Item {
    id: service

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell/"
    readonly property string historyPath: stateDir + "notifications.json"
    readonly property string rulesPath: Quickshell.env("HOME") + "/.config/quickshell/notification-rules.json"
    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/quickshell/"
    readonly property string imageCacheDir: cacheDir + "notification-images/"

    readonly property int cornerRadius: Config.borderRadius

    // Notification rules — loaded from notification-rules.json
    property var notificationRules: []

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

    function fyi(summary, body, urgency, expireTimeout, command, group, desktopEntry) {
        group = String(group || "")
        if (group) {
            var oldId = service._fyiGroups[group]
            if (oldId !== undefined) {
                service.dismissPendingByOriginalId(oldId)
                // Also dismiss any popup wrapper for this group
                var oldWrapper = service._popupRefsByOriginalId[oldId]
                if (oldWrapper) oldWrapper.popup = false
                delete service._fyiGroups[group]
            }
        }

        var id = --service._fyiSeq
        var snapshot = {
            id: id,
            originalId: id,
            app: String(summary || ""),
            appIcon: "",
            summary: String(summary || ""),
            body: String(body || ""),
            image: "",
            glyph: "",
            urgency: typeof urgency === "number" ? urgency : NotificationUrgency.Normal,
            expireTimeout: typeof expireTimeout === "number" ? expireTimeout : 0,
            timestamp: Date.now(),
            _clickCommand: String(command || ""),
            _desktopEntry: String(desktopEntry || "")
        }
        snapshot.contentHash = N.contentHash(snapshot)
        snapshot.duplicateCount = 1
        if (snapshot.expireTimeout <= 0)
            snapshot.expireTimeout = service.defaultExpirySeconds(snapshot.urgency)
        setRef(id, null)
        addToPending(snapshot)
        if (!service.doNotDisturb) {
            Qt.callLater(function() {
                if (service.popupsBlocked) return
                showPopup(snapshot)
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

    // visiblePopups — array of NotificationWrapper objects for individual popup windows
    property var visiblePopups: []
    property var _popupRefs: ({}) // id -> wrapper
    property var _popupRefsByOriginalId: ({}) // originalId -> wrapper
    readonly property int maxVisiblePopups: 4

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
            return Math.min(maxPopupDuration, Math.max(normalPopupDuration, requestedDuration(expireTimeout)))
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

    function defaultExpirySeconds(urgency) {
        return durationFor(urgency, 0) / 1000
    }

    function shouldBypassDnd(notification) {
        return N.shouldBypassDnd(notification, NotificationUrgency.Critical)
    }

    function snapshotOf(notification) {
        return N.snapshotOf(notification, Date.now())
    }

    // Merge duplicate notifications by content hash
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
                merged._desktopEntry = snapshot._desktopEntry || row._desktopEntry || ""
                merged.expireTimeout = snapshot.expireTimeout || 0
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
            _clickCommand: snapshot._clickCommand || "",
            _desktopEntry: snapshot._desktopEntry || ""
        }
        setRef(fresh.id, newRef)
        pendingModel.insert(0, fresh)
    }

    // -----------------------------------------------------------------------
    // showPopup — creates/updates a popup wrapper and adds to visiblePopups
    // -----------------------------------------------------------------------
    Component { id: wrapperComponent; NotificationWrapper {} }

    function showPopup(snapshot) {
        var hash = snapshot.contentHash || N.contentHash(snapshot)
        var existing = _popupRefsByOriginalId[snapshot.originalId]

        // Duplicate: update existing popup in place
        if (existing && !existing.popupClosing) {
            var oldRef = existing.ref
            existing.id = snapshot.id
            existing.originalId = snapshot.originalId
            existing.timestamp = snapshot.timestamp
            existing.duplicateCount = (existing.duplicateCount || 1) + 1
            existing._clickCommand = snapshot._clickCommand || existing._clickCommand || ""
            existing._desktopEntry = snapshot._desktopEntry || existing._desktopEntry || ""
            existing.expireTimeout = snapshot.expireTimeout || existing.expireTimeout
            existing.ref = getRef(snapshot.id)
            if (oldRef && oldRef !== getRef(snapshot.id)) {
                try { if (oldRef.tracked) oldRef.dismiss() } catch (e) {}
            }
            existing.stopPopupTimer()
            existing.startPopupTimer()
            // Trigger UI update
            visiblePopups = visiblePopups.slice()
            return
        }

        // Create new wrapper
        var wrapper = wrapperComponent.createObject(service, {
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
            popup: true,
            popupClosing: false,
            popupProgress: 1.0,
            ref: getRef(snapshot.id),
            service: service,
            _clickCommand: snapshot._clickCommand || "",
            _desktopEntry: snapshot._desktopEntry || ""
        })
        if (!wrapper) return

        _popupRefs[snapshot.id] = wrapper
        _popupRefsByOriginalId[snapshot.originalId] = wrapper

        // Evict oldest if at max
        if (visiblePopups.length >= maxVisiblePopups) {
            var oldest = visiblePopups[visiblePopups.length - 1]
            if (oldest) oldest.popup = false
        }

        visiblePopups.unshift(wrapper)
        wrapper.startPopupTimer()
        visiblePopups = visiblePopups.slice()
    }

    function dismissPopupByWrapper(wrapper) {
        if (!wrapper) return
        wrapper.stopPopupTimer()
        wrapper.popup = false
        wrapper.popupClosing = true
        // Remove from visiblePopups
        var idx = visiblePopups.indexOf(wrapper)
        if (idx !== -1) {
            visiblePopups.splice(idx, 1)
            visiblePopups = visiblePopups.slice()
        }
        markSeenByOriginalId(wrapper.originalId)
        // Clean up ref
        removeRef(wrapper.id)
        delete _popupRefs[wrapper.id]
        delete _popupRefsByOriginalId[wrapper.originalId]
    }

    // Called by the popup manager when a popup window is destroyed
    function releasePopup(wrapper) {
        if (!wrapper) return
        var idx = visiblePopups.indexOf(wrapper)
        if (idx !== -1) {
            visiblePopups.splice(idx, 1)
            visiblePopups = visiblePopups.slice()
        }
        delete _popupRefs[wrapper.id]
        delete _popupRefsByOriginalId[wrapper.originalId]
    }

    function handleNotification(notification) {
        notification.tracked = true
        var snapshot = snapshotOf(notification)
        setRef(snapshot.id, notification)

        var appName = String(notification.appName || "")
        var ephemeralApp = N.isEphemeralApp(appName)

        // Rules engine — evaluate before any processing
        var rule = N.evaluateRules(service.notificationRules, snapshot)
        if (rule) {
            switch (rule.action) {
            case "ignore":
                notification.tracked = false
                return
            case "mute":
                // No popup, but keep in center
                if (rule.urgencyOverride !== undefined) snapshot.urgency = rule.urgencyOverride
                addToPending(snapshot)
                maybeCacheImage(snapshot)
                return
            case "popup_only":
                if (rule.urgencyOverride !== undefined) snapshot.urgency = rule.urgencyOverride
                if (!service.doNotDisturb || shouldBypassDnd(notification)) {
                    Qt.callLater(function() {
                        if (service.popupsBlocked) return
                        showPopup(snapshot)
                    })
                }
                return
            case "no_history":
                if (rule.urgencyOverride !== undefined) snapshot.urgency = rule.urgencyOverride
                snapshot._noHistory = true
                if (!service.doNotDisturb || shouldBypassDnd(notification)) {
                    Qt.callLater(function() {
                        if (service.popupsBlocked) return
                        showPopup(snapshot)
                    })
                }
                return
            case "default":
                if (rule.urgencyOverride !== undefined) snapshot.urgency = rule.urgencyOverride
                break
            }
        }

        if (ephemeralApp) {
            if (service.doNotDisturb && !shouldBypassDnd(notification)) {
                notification.tracked = false
                return
            }
            Qt.callLater(function() {
                if (service.popupsBlocked) return
                showPopup(snapshot)
            })
            return
        }

        if (snapshot.expireTimeout <= 0)
            snapshot.expireTimeout = service.defaultExpirySeconds(snapshot.urgency)
        addToPending(snapshot)
        maybeCacheImage(snapshot)

        if (service.doNotDisturb && !shouldBypassDnd(notification)) {
            notification.tracked = false
            return
        }

        Qt.callLater(function() {
            if (service.popupsBlocked) return
            showPopup(snapshot)
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
            _clickCommand: row._clickCommand || "",
            _desktopEntry: row._desktopEntry || ""
        }
    }

    function markSeenByOriginalId(originalId) {
        Qt.callLater(function() {
            for (var i = 0; i < pendingModel.count; i++) {
                var entry = pendingModel.get(i)
                if (!entry || entry.originalId !== originalId) continue
                var snapshot = service.snapshotFromRow(entry)
                pendingModel.remove(i)
                pastModel.insert(0, snapshot)
                while (pastModel.count > service.historyCap) {
                    var trimmedPast = pastModel.get(pastModel.count - 1)
                    if (trimmedPast) removeRef(trimmedPast.id)
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
                pastModel.insert(0, snapshot)
            }
            while (pastModel.count > service.historyCap) {
                var trimmedPast = pastModel.get(pastModel.count - 1)
                if (trimmedPast) removeRef(trimmedPast.id)
                pastModel.remove(pastModel.count - 1)
            }
            scheduleHistorySave()
        })
    }

    // Legacy popup dismiss for backward compat — no longer used but kept for IPC
    function dismissPopup(index) {
        // popupModel is no longer used; popups are managed via visiblePopups
        if (index < 0 || index >= visiblePopups.length) return
        var wrapper = visiblePopups[index]
        if (wrapper) wrapper.popup = false
    }

    function expirePopup(index) {
        dismissPopup(index)
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

    function dismissPast(index) {
        if (index < 0 || index >= pastModel.count) return
        var entry = pastModel.get(index)
        if (entry) {
            maybeDeleteCachedImage(entry.image)
            removeRef(entry.id)
        }
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
                if (entry) {
                    maybeDeleteCachedImage(entry.image)
                    removeRef(entry.id)
                }
            }
            pastModel.clear()
            scheduleHistorySave()
        })
    }

    function invokePopupDefault(index) {
        if (index < 0 || index >= popupModel.count) return
        var entry = popupModel.get(index)
        if (!entry) return
        var wrapper = _popupRefsByOriginalId[entry.originalId]
        if (wrapper) {
            dismissPopupByWrapper(wrapper)
            service.invokeDefaultFromWrapper(wrapper)
            return
        }
        // Fallback for old flow
        var ref = getRef(entry.id)
        var invoked = false
        if (ref && ref.actions) {
            for (var i = 0; i < ref.actions.length; i++) {
                var action = ref.actions[i]
                if (action && action.identifier === "default") {
                    try { action.invoke(); invoked = true } catch (e) {}
                    break
                }
            }
        }
        if (!invoked) {
            var cmd = String(entry._clickCommand || "")
            if (cmd) {
                var home = Quickshell.env("HOME")
                fyiActionProc.command = [
                    "sh", "-c",
                    "PATH=" + home + "/.config.jmmm.sh/bin:/usr/local/bin:/usr/bin:/bin; " + cmd
                ]
                fyiActionProc.running = true
            } else {
                launchApp(entry)
            }
        }
    }

    function invokeDefaultFromWrapper(wrapper) {
        if (!wrapper) return
        var ref = wrapper.ref
        var invoked = false
        if (ref && ref.actions && ref.actions.length > 0) {
            // Try "default" action first
            for (var i = 0; i < ref.actions.length; i++) {
                var action = ref.actions[i]
                if (action && action.identifier === "default") {
                    try { action.invoke(); invoked = true } catch (e) {}
                    break
                }
            }
            // Fallback: invoke first action (many apps only have one action)
            if (!invoked && ref.actions.length > 0) {
                var first = ref.actions[0]
                if (first && first.invoke) {
                    try { first.invoke(); invoked = true } catch (e) {}
                }
            }
        }
        if (!invoked) {
            var cmd = String(wrapper._clickCommand || "")
            if (cmd) {
                var home = Quickshell.env("HOME")
                fyiActionProc.command = [
                    "sh", "-c",
                    "PATH=" + home + "/.config.jmmm.sh/bin:/usr/local/bin:/usr/bin:/bin; " + cmd
                ]
                fyiActionProc.running = true
            } else {
                launchApp(wrapper)
            }
        }
        if (invoked) focusAppWorkspace(wrapper.app)
    }

    function invokePendingDefault(index) {
        if (index < 0 || index >= pendingModel.count) return
        var entry = pendingModel.get(index)
        var ref = entry ? getRef(entry.id) : null
        var invoked = false
        if (ref && ref.actions) {
            for (var i = 0; i < ref.actions.length; i++) {
                var action = ref.actions[i]
                if (action && action.identifier === "default") {
                    try { action.invoke(); invoked = true } catch (e) {}
                    break
                }
            }
        }
        if (!invoked) {
            var cmd = entry ? String(entry._clickCommand || "") : ""
            if (cmd) {
                var home = Quickshell.env("HOME")
                fyiActionProc.command = [
                    "sh", "-c",
                    "PATH=" + home + "/.config.jmmm.sh/bin:/usr/local/bin:/usr/bin:/bin; " + cmd
                ]
                fyiActionProc.running = true
            } else {
                launchApp(entry)
            }
        }
        if (invoked && entry) focusAppWorkspace(entry.app)
        dismissPending(index)
    }

    function invokePastDefault(index) {
        if (index < 0 || index >= pastModel.count) return
        var entry = pastModel.get(index)
        if (!entry || !entry.app) return
        var ref = entry ? getRef(entry.id) : null
        if (ref && ref.actions && ref.actions.length > 0) {
            for (var i = 0; i < ref.actions.length; i++) {
                var action = ref.actions[i]
                if (action && action.identifier === "default") {
                    try { action.invoke() } catch (e) {}
                    break
                }
            }
            if (ref.actions.length > 0 && (!ref.actions[0] || ref.actions[0].identifier !== "default")) {
                var first = ref.actions[0]
                if (first && first.invoke) {
                    try { first.invoke() } catch (e) {}
                }
            }
        }
        launchApp(entry)
    }

    function launchApp(entry) {
        if (!entry || !entry.app) return
        var home = Quickshell.env("HOME")
        var de = String(entry._desktopEntry || "")
        var app = String(entry.app || "")
        var focusApp = home + "/.config.jmmm.sh/bin/hyprland-focus-app"
        var safeApp = "'" + app.replace(/'/g, "'\\''") + "'"

        var script = "exec 2>/tmp/notif-launch-strace.log; set -x; "
        script += "if " + focusApp + " " + safeApp + "; then exit 0; fi; "

        var lower = app.toLowerCase()
        var firstWord = app.split(/ +/)[0]
        var firstWordLow = firstWord.toLowerCase()
        var dashes = lower.replace(/ /g, '-')

        var gtkTries = [lower.replace(/ /g, '.'), dashes, lower.replace(/ /g, ''), lower, app]
        if (de) gtkTries.unshift(de)

        for (var ti = 0; ti < gtkTries.length; ti++) {
            var t = gtkTries[ti]
            if (!t || t.indexOf("'") >= 0) continue
            script += "if gtk-launch '" + t + "' 2>/dev/null; then exit 0; fi; "
        }

        var seen = {}
        var addCmd = function(s) {
            if (s && !seen[s]) { seen[s] = true; script += "'" + s + "' &>/dev/null & disown; "; }
        }
        addCmd(firstWord)
        addCmd(firstWordLow)
        addCmd(dashes)
        addCmd(de)

        script += "sleep 1; " + focusApp + " " + safeApp
        launchAppProc.command = ["bash", "-l", "-c", script]
        launchAppProc.running = true
    }

    Process { id: launchAppProc; running: false }
    Process { id: fyiActionProc; running: false }
    Process {
        id: focusAppProc
        running: false
        onExited: function() { /* best-effort, ignore failures */ }
    }

    function focusAppWorkspace(appName) {
        if (!appName) return
        var home = Quickshell.env("HOME")
        focusAppProc.command = [home + "/.config.jmmm.sh/bin/hyprland-focus-app", appName]
        focusAppProc.running = true
    }

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

    readonly property int pastTtlMs: 7 * 24 * 60 * 60 * 1000

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
                removeRef(entry.id)
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

    // Rules file
    FileView {
        id: rulesFile
        path: service.rulesPath
        watchChanges: true
        printErrors: false
        onLoaded: service.notificationRules = N.parseRules(text())
        onLoadFailed: service.notificationRules = []
        onFileChanged: reload()
    }

    Component.onCompleted: {
        ensureDirsProc.running = true
        Qt.callLater(function() { historyFile.reload() })
        Qt.callLater(function() { rulesFile.reload() })
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
            service.clearPending()
            service.clearPast()
            for (var i = service.visiblePopups.length - 1; i >= 0; i--) {
                service.visiblePopups[i].popup = false
            }
            return "ok"
        }

        function dismissOne(): string {
            if (service.visiblePopups.length > 0) {
                service.visiblePopups[0].popup = false
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
            if (service.visiblePopups.length === 0) return "none"
            var wrapper = service.visiblePopups[0]
            service.dismissPopupByWrapper(wrapper)
            service.invokeDefaultFromWrapper(wrapper)
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
            for (var i = service.visiblePopups.length - 1; i >= 0; i--) {
                var w = service.visiblePopups[i]
                if (w && String(w.summary || "").indexOf(needle) !== -1) {
                    w.popup = false
                    hit = true
                }
            }
            return hit ? "ok" : "none"
        }

        function fyi(summary: string, body: string, urgency: string, expiry: string, command: string, group: string, desktopEntry: string): string {
            var u = NotificationUrgency.Normal
            var urg = String(urgency || "").toLowerCase()
            if (urg === "low" || urg === "0") u = NotificationUrgency.Low
            else if (urg === "critical" || urg === "2") u = NotificationUrgency.Critical
            var e = Number(expiry || 0)
            if (!isFinite(e) || e < 0) e = 0
            service.fyi(summary, body, u, e, command, group, desktopEntry)
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

    // Per-screen popup managers — individual popup windows
    Variants {
        model: Quickshell.screens

        NotificationPopupManager {
            modelData: modelData
            popupService: service
            topMargin: Config.height + Config.shellPadding + Config.gapsOut
        }
    }
}
