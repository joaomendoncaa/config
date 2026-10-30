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

// freedesktop `value` hint: 0-100 int (dunst), occasionally a 0-1 float.
function valueFromHints(hints) {
    try {
        if (!hints) return -1
        var raw = hints["value"]
        if (raw === undefined || raw === null || raw === "") return -1
        var value = Number(raw)
        if (!isFinite(value) || value < 0) return -1
        if (value > 1) value = value / 100
        return Math.max(0, Math.min(1, value))
    } catch (e) {
        return -1
    }
}

// In-place replacement for sliders (volume, brightness, media position).
function tagFromHints(hints) {
    try {
        if (!hints) return ""
        return String(hints["x-dunst-stack-tag"] || hints["x-canonical-private-synchronous"] || "")
    } catch (e) {
        return ""
    }
}

// Stable per-app hue, so the same sender always gets the same badge colour.
function appHue(app) {
    var text = String(app || "")
    var hash = 2166136261
    for (var i = 0; i < text.length; i++) {
        hash ^= text.charCodeAt(i)
        hash = (hash * 16777619) >>> 0
    }
    return hash % 360
}

function appInitial(app) {
    var text = String(app || "")
    for (var i = 0; i < text.length; i++) {
        if (/[a-z0-9]/i.test(text.charAt(i))) return text.charAt(i).toUpperCase()
    }
    return "•"
}

function contentHash(obj) {
    var u = obj ? obj.urgency : undefined
    var uStr = (u === null || u === undefined) ? "" : String(u)
    var v = obj ? obj.value : undefined
    var vStr = (v === null || v === undefined) ? "" : String(v)
    var parts = [
        String((obj && obj.app) || ""),
        String((obj && obj.appIcon) || ""),
        String((obj && obj.summary) || ""),
        String((obj && obj.body) || ""),
        String((obj && obj.glyph) || ""),
        String((obj && obj.tag) || ""),
        vStr,
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
    // freedesktop expire_timeout is milliseconds; the service tracks seconds
    if (expireTimeout > 0) expireTimeout = expireTimeout / 1000
    var de = ""
    try {
        if (n.hints && n.hints["desktop-entry"] !== undefined)
            de = String(n.hints["desktop-entry"])
    } catch (e) {}
    var snap = {
        id: id,
        originalId: id,
        app: n.appName || "",
        appIcon: n.appIcon || "",
        summary: String(n.summary || ""),
        body: n.body || "",
        image: n.image || "",
        glyph: glyphFromHints(n.hints),
        value: valueFromHints(n.hints),
        tag: tagFromHints(n.hints),
        sticky: false,
        urgency: n.urgency,
        expireTimeout: expireTimeout,
        timestamp: timestamp === undefined ? Date.now() : timestamp,
        _desktopEntry: de
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
        // image:// providers only live as long as the notification they came from
        image: String(e.image || "").indexOf("image://") === 0 ? "" : (e.image || ""),
        glyph: e.glyph || "",
        value: typeof e.value === "number" ? e.value : -1,
        tag: e.tag || "",
        sticky: !!e.sticky,
        urgency: typeof e.urgency === "number" ? e.urgency : normalUrgency,
        expireTimeout: 0,
        timestamp: e.timestamp || 0
    }
    entry.contentHash = e.contentHash || contentHash(entry)
    entry.duplicateCount = typeof e.duplicateCount === "number" ? e.duplicateCount : 1
    entry._busy = !!e._busy
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

// ---------------------------------------------------------------------------
// Notification Rules Engine
// Rules are evaluated in order; first match wins.
// Each rule: { match: {appName?, desktopEntry?, summary?, body?, urgency?},
//              matchType: "contains"|"exact"|"regex",
//              action: "ignore"|"mute"|"popup_only"|"no_history"|"default",
//              urgencyOverride?: int, timeout?: seconds | "never",
//              interrupt?: bool (show during Do not disturb),
//              sound?: bool (default true — set false to skip the notification ding) }
// ---------------------------------------------------------------------------

function evaluateRules(rules, snapshot) {
    if (!rules || !Array.isArray(rules) || rules.length === 0) return null
    for (var i = 0; i < rules.length; i++) {
        var rule = rules[i]
        if (!rule || !rule.match) continue
        if (_matchesRule(rule, snapshot)) return rule
    }
    return null
}

function _matchesRule(rule, snapshot) {
    var match = rule.match
    var matchType = rule.matchType || "contains"

    if (match.appName !== undefined && match.appName !== null) {
        if (!_matchField(snapshot.app, match.appName, matchType)) return false
    }
    if (match.desktopEntry !== undefined && match.desktopEntry !== null) {
        if (!_matchField(snapshot._desktopEntry, match.desktopEntry, matchType)) return false
    }
    if (match.summary !== undefined && match.summary !== null) {
        if (!_matchField(snapshot.summary, match.summary, matchType)) return false
    }
    if (match.body !== undefined && match.body !== null) {
        if (!_matchField(snapshot.body, match.body, matchType)) return false
    }
    if (match.urgency !== undefined && match.urgency !== null) {
        var urgency = snapshot.urgency
        var wanted = match.urgency
        if (typeof wanted === "string") {
            var names = { low: 0, normal: 1, critical: 2 }
            wanted = names[wanted.toLowerCase()]
        }
        if (wanted === undefined || Number(wanted) !== Number(urgency)) return false
    }
    return true
}

function _matchField(value, pattern, matchType) {
    var text = String(value || "").toLowerCase()
    var pat = String(pattern || "").toLowerCase()
    if (matchType === "exact") return text === pat
    if (matchType === "regex") {
        try {
            var re = new RegExp(pat, "i")
            return re.test(text)
        } catch (e) {
            return false
        }
    }
    // contains (default)
    return text.indexOf(pat) !== -1
}

// Default rules loaded from a JSON file
function parseRules(raw) {
    var text = String(raw || "").trim()
    if (!text) return []
    try {
        var parsed = JSON.parse(text)
        return Array.isArray(parsed) ? parsed : []
    } catch (e) {
        return []
    }
}
