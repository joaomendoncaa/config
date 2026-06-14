.pragma library
.import QtQuick 2.15 as QtQuick
.import Quickshell as Quickshell

// ---- General utilities ----
function parseEmojiJson(raw) {
    try {
        var data = JSON.parse(String(raw || '[]'))
        return Array.isArray(data) ? data : []
    } catch (e) {
        return []
    }
}

function shellQuote(s) {
    return "'" + String(s || '').replace(/'/g, "'\\''") + "'"
}

function resolveIcon(name) {
    if (!name) return Quickshell.iconPath('application-x-executable', true)
    if (name.indexOf('/') >= 0) {
        if (name.indexOf('file://') === 0 || name.indexOf('image://') === 0) return name
        if (name.charAt(0) === '/') return 'file://' + name
    }
    return Quickshell.iconPath(name, true)
}

// ---- LauncherAppSearch.js ----
function entryName(entry) {
    return String((entry && entry.name) || (entry && entry.id) || '')
}

function entrySearchText(entry) {
    if (!entry) return ''
    return [entry.name, entry.genericName, entry.comment, entry.keywords ? entry.keywords.join(' ') : '', entry.id].join(' ').toLowerCase()
}

function entryAcronym(entry) {
    var vals = words([entry && entry.name, entry && entry.genericName, entry && entry.id].join(' '))
    var r = ''
    for (var i = 0; i < vals.length; i++) r += vals[i].charAt(0)
    return r
}

function words(value) {
    var v = String(value || '')
        .replace(/([a-z0-9])([A-Z])/g, '$1 $2')
        .replace(/[._:\/\\-]+/g, ' ')
        .toLowerCase()
    return v.split(/[^a-z0-9]+/).filter(function(w) { return w.length > 0 })
}

function termMatches(entry, term) {
    if (!term) return true
    var name = entryName(entry).toLowerCase()
    var id = String((entry && entry.id) || '').toLowerCase()
    var haystack = entrySearchText(entry)
    if (name.indexOf(term) >= 0) return true
    if (id.indexOf(term) >= 0) return true
    if (haystack.indexOf(term) >= 0) return true
    return term.length <= 5 && entryAcronym(entry).indexOf(term) >= 0
}

function fuzzyScore(entry, query) {
    var q = String(query || '').trim().toLowerCase()
    if (!q) return 0
    var terms = q.split(/\s+/)
    for (var i = 0; i < terms.length; i++) {
        if (terms[i] && !termMatches(entry, terms[i])) return -1
    }
    var name = entryName(entry).toLowerCase()
    var id = String((entry && entry.id) || '').toLowerCase()
    var haystack = entrySearchText(entry)
    var directName = name.indexOf(q)
    var directId = id.indexOf(q)
    if (directName === 0) return 10000 - name.length
    if (directId === 0) return 9500 - id.length
    if (directName > 0) return 8000 - directName * 10 - name.length
    if (directId > 0) return 7600 - directId * 10 - id.length
    var hayIndex = haystack.indexOf(q)
    if (hayIndex >= 0) return 6000 - hayIndex
    var acronym = entryAcronym(entry)
    var acronymIndex = acronym.indexOf(q)
    if (acronymIndex === 0) return 5000 - acronym.length
    if (acronymIndex > 0) return 4600 - acronymIndex * 10 - acronym.length
    return 4000 - name.length
}

function sortedEntries(values, query) {
    var q = String(query || '').trim()
    var rows = []
    for (var i = 0; i < values.length; i++) {
        var entry = values[i]
        if (!entry || entry.noDisplay) continue
        var name = entryName(entry)
        if (!name) continue
        var score = fuzzyScore(entry, q)
        if (score < 0) continue
        rows.push({ entry: entry, score: score, key: name.toLowerCase(), name: name })
    }
    rows.sort(function(a, b) {
        if (q && a.score !== b.score) return b.score - a.score
        if (a.key < b.key) return -1
        if (a.key > b.key) return 1
        return 0
    })
    return rows
}

// ---- EmojiSearch.js ----
function filterEmojis(emojis, query, limit) {
    var values = Array.isArray(emojis) ? emojis : []
    var needle = String(query || '').trim().toLowerCase()
    var max = Math.max(0, Number(limit) || 100)
    if (max === 0) return []

    var out = []
    for (var i = 0; i < values.length; i++) {
        var item = values[i]
        if (!item || !item.e) continue
        if (!needle || (item.k && item.k.toLowerCase().indexOf(needle) >= 0)) {
            out.push(item)
            if (out.length >= max) break
        }
    }
    return out
}

// ---- ClipboardHistory.js ----
function parseClipboardHistory(raw) {
    try {
        var parsed = JSON.parse(String(raw || '[]'))
        return Array.isArray(parsed) ? parsed : []
    } catch (e) {
        return []
    }
}

function filterClipboardHistory(history, query, limit) {
    var needle = String(query || '').trim().toLowerCase()
    var max = Math.max(0, Number(limit) || 50)
    if (max === 0) return []

    var out = []
    for (var i = 0; i < history.length; i++) {
        var entry = history[i]
        if (!entry) continue
        var searchText = ''
        if (typeof entry === 'string') {
            searchText = entry
        } else if (entry.type === 'image') {
            searchText = (entry.capturedAt || '') + ' ' + (entry.mime || '') + ' image'
        } else if (entry.type === 'video') {
            searchText = (entry.capturedAt || '') + ' ' + (entry.mime || '') + ' video'
        } else {
            searchText = String(entry.text || '')
        }
        if (!needle || searchText.toLowerCase().indexOf(needle) >= 0) {
            out.push({ entry: entry, index: i })
            if (out.length >= max) break
        }
    }
    return out
}
