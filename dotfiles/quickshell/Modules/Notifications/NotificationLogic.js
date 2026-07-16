function isChromiumDerived(app, appIcon) {
    var source = (String(app || "") + "\n" + String(appIcon || "")).toLowerCase()
    return source.indexOf("chrom") >= 0 || source.indexOf("brave") >= 0 ||
           source.indexOf("vivaldi") >= 0 || source.indexOf("microsoft-edge") >= 0 ||
           source.indexOf("opera") >= 0
}

function sanitizeBody(body, app, appIcon) {
    var text = String(body || "").replace(/<img[^>]*>/gi, "")
    if (!isChromiumDerived(app, appIcon)) return text

    return text
        .replace(/^\s*<a\b[^>]*>\s*(?:https?:\/\/|www\.)?(?:[a-z0-9-]+\.)+[a-z]{2,}(?::\d+)?(?:\/[^<\s]*)?\s*<\/a>\s*/i, "")
        .replace(/^\s*(?:https?:\/\/|www\.)?(?:[a-z0-9-]+\.)+[a-z]{2,}(?::\d+)?(?:\/\S*)?\s+/i, "")
}

function summaryStartsWithGlyph(summary) {
    var text = String(summary || "").replace(/^\s+/, "")
    if (!text) return false

    var offset = 1
    var first = text.charCodeAt(0)
    if (first >= 0xd800 && first <= 0xdbff && text.length > 1) offset = 2

    var spaces = 0
    while (offset < text.length && text.charAt(offset) === " ") {
        spaces++
        offset++
    }

    return spaces >= 2
}

function shouldBypassDnd(notification, criticalUrgency) {
    var appName = String((notification && notification.appName) || "")
    if (appName === "notify-send-custom") return true
    return appName === "notify-send" && notification && notification.urgency === criticalUrgency
}

function isEphemeralApp(appName) {
    var name = String(appName || "")
    return name === "notify-send" || name === "notify-send-custom"
}

function glyphFromHints(hints) {
    try {
        if (hints) {
            var glyph = hints["glyph"]
            if (glyph !== undefined && glyph !== null) return String(glyph)
        }
    } catch (e) {}
    return ""
}

function shouldRenderCompactGlyph(glyph, iconSource) {
    return String(glyph || "").length > 0 && String(iconSource || "").length === 0
}

function contentHash(obj) {
    var u = obj ? obj.urgency : undefined
    var uStr = (u === null || u === undefined) ? "" : String(u)
    var parts = [
        String((obj && obj.app) || ""),
        String((obj && obj.appIcon) || ""),
        String((obj && obj.summary) || ""),
        String((obj && obj.body) || ""),
        String((obj && obj.glyph) || ""),
        uStr
    ]
    var s = parts.join("\u0001")
    var h = 5381
    for (var i = 0; i < s.length; i++) {
        h = ((h << 5) + h + s.charCodeAt(i)) | 0
    }
    return "h" + (h >>> 0).toString(16)
}

function snapshotOf(notification, timestamp) {
    var n = notification || {}
    var id = n.id || 0
    var expireTimeout = Number(n.expireTimeout || 0)
    if (!isFinite(expireTimeout) || expireTimeout < 0) expireTimeout = 0
    var snap = {
        id: id,
        originalId: id,
        app: n.appName || "",
        appIcon: n.appIcon || "",
        summary: String(n.summary || ""),
        body: n.body || "",
        image: n.image || "",
        glyph: glyphFromHints(n.hints),
        urgency: n.urgency,
        expireTimeout: expireTimeout,
        timestamp: timestamp === undefined ? Date.now() : timestamp
    }
    snap.contentHash = contentHash(snap)
    return snap
}

function historyEntry(value, normalUrgency) {
    var e = value || {}
    var entry = {
        id: e.id || 0,
        originalId: e.originalId || e.id || 0,
        app: e.app || "",
        appIcon: e.appIcon || "",
        summary: e.summary || "",
        body: e.body || "",
        image: e.image || "",
        glyph: e.glyph || "",
        urgency: typeof e.urgency === "number" ? e.urgency : normalUrgency,
        expireTimeout: 0,
        timestamp: e.timestamp || 0
    }
    entry.contentHash = e.contentHash || contentHash(entry)
    entry.duplicateCount = typeof e.duplicateCount === "number" ? e.duplicateCount : 1
    return entry
}

function dedupeByOriginalId(rows) {
    var values = Array.isArray(rows) ? rows : []
    var keep = {}
    for (var i = 0; i < values.length; i++) {
        var row = values[i]
        if (!row) continue
        var key = row.originalId
        if (key === undefined || key === null) key = "_" + i
        var prior = keep[key]
        if (!prior || (row.timestamp || 0) >= (prior.timestamp || 0)) keep[key] = row
    }

    var out = []
    for (var id in keep) out.push(keep[id])
    out.sort(function(a, b) { return (b.timestamp || 0) - (a.timestamp || 0) })
    return out
}

function mergeByContentHash(rows) {
    var values = Array.isArray(rows) ? rows : []
    var keep = {}
    var order = []
    for (var i = 0; i < values.length; i++) {
        var row = values[i]
        if (!row) continue
        var key = row.contentHash || contentHash(row)
        var prior = keep[key]
        if (!prior) {
            row.contentHash = key
            if (typeof row.duplicateCount !== "number") row.duplicateCount = 1
            keep[key] = row
            order.push(key)
        } else {
            var pc = Number(prior.duplicateCount || 1)
            var nc = Number(row.duplicateCount || 1)
            if ((row.timestamp || 0) > (prior.timestamp || 0)) {
                row.contentHash = key
                row.duplicateCount = pc + nc
                keep[key] = row
            } else {
                prior.duplicateCount = pc + nc
            }
        }
    }
    var out = []
    for (var k = 0; k < order.length; k++) out.push(keep[order[k]])
    out.sort(function(a, b) { return (b.timestamp || 0) - (a.timestamp || 0) })
    return out
}

function parseHistory(raw, normalUrgency, historyCap) {
    var text = String(raw || "").trim()
    var cap = historyCap === undefined || historyCap === null ? 100 : Number(historyCap)
    if (isNaN(cap)) cap = 100
    cap = Math.max(0, cap)
    if (!text) return { empty: true, error: false, dnd: null, pending: [], past: [], hadDuplicates: false }

    try {
        var parsed = JSON.parse(text)
        var pendingRaw = (parsed && Array.isArray(parsed.pending)) ? parsed.pending : []
        var pastRaw = (parsed && Array.isArray(parsed.past)) ? parsed.past : []
        if (parsed && Array.isArray(parsed.entries)) pastRaw = pastRaw.concat(parsed.entries)

        var pendingDeduped = dedupeByOriginalId(pendingRaw)
        var pastDeduped = dedupeByOriginalId(pastRaw)
        var pendingMerged = mergeByContentHash(pendingDeduped)
        var pastMerged = mergeByContentHash(pastDeduped)

        return {
            empty: false,
            error: false,
            dnd: parsed && typeof parsed.dnd === "boolean" ? parsed.dnd : null,
            pending: pendingMerged.slice(0, cap).map(function(entry) { return historyEntry(entry, normalUrgency) }),
            past: pastMerged.slice(0, cap).map(function(entry) { return historyEntry(entry, normalUrgency) }),
            hadDuplicates: pendingDeduped.length !== pendingRaw.length || pastDeduped.length !== pastRaw.length ||
                           pendingMerged.length !== pendingDeduped.length || pastMerged.length !== pastDeduped.length
        }
    } catch (e) {
        return { empty: false, error: true, errorMessage: String(e), dnd: null, pending: [], past: [], hadDuplicates: false }
    }
}

function imageExtension(srcPath) {
    var lower = String(srcPath || "").toLowerCase()
    var dot = lower.lastIndexOf(".")
    if (dot < 0) return "png"
    var ext = lower.substring(dot + 1)
    if (ext.length === 0 || ext.length > 5) return "png"
    return ext
}
