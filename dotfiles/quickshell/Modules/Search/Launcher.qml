import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Core


PanelWindow {
  id: root

  signal dismissed

  readonly property var modeNames: ["apps", "emojis", "files", "clipboard"]
  property int modeIndex: 0
  property string filterText: ""
  property int selectedIndex: 0
  property int cursorPosition: 0

  property var emojiData: []
  property var clipboardData: []
  property var fileResults: []

  ListModel { id: displayModel }

  function dismiss() {
    dismissed()
  }

  exclusiveZone: 0
  color: "transparent"
  anchors { left: true; right: true; top: true; bottom: true }
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  exclusionMode: ExclusionMode.Ignore

  Component.onCompleted: {
    rebuildDisplay()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function parseEmojiJson(raw) {
    try {
      var data = JSON.parse(String(raw || "[]"))
      return Array.isArray(data) ? data : []
    } catch (e) {
      return []
    }
  }

  function setMode(mode) {
    if (mode < 0 || mode > 3) return
    if (modeIndex !== mode) {
      modeIndex = mode
      filterText = ""
      selectedIndex = 0
      cursorPosition = 0
      clearFileSearch()
      rebuildDisplay()
      Qt.callLater(function() { keyCatcher.forceActiveFocus() })
    }
  }

  function clearFileSearch() {
    fileSearchTimer.stop()
    fileResults = []
  }

  function rebuildDisplay() {
    var items = searchResults()
    displayModel.clear()
    for (var i = 0; i < items.length; i++) {
      var it = items[i]
      displayModel.append({
        type: it.type,
        label: it.label,
        detail: it.detail || "",
        emojiChar: it.emojiChar || "",
        iconName: it.iconName || "",
        fullText: it.fullText || "",
        imagePath: it.imagePath || "",
        mime: it.mime || ""
      })
    }
    if (displayModel.count === 0) {
      selectedIndex = 0
    } else if (selectedIndex >= displayModel.count) {
      selectedIndex = displayModel.count - 1
    }
    positionToSelected()
  }

  function positionToSelected() {
    if (displayModel.count > 0) {
      resultList.positionViewAtIndex(selectedIndex, ListView.Contain)
    }
  }

  function searchResults() {
    switch (modeIndex) {
      case 0: return searchApps()
      case 1: return searchEmojis()
      case 2: return searchFiles()
      case 3: return searchClipboard()
    }
    return []
  }

  function searchApps() {
    var entries = DesktopEntries.applications.values || []
    var rows = sortedEntries(entries, filterText)
    var max = Math.min(rows.length, 100)
    var out = []
    for (var i = 0; i < max; i++) {
      out.push({
        type: "app",
        label: rows[i].name,
        iconName: String(rows[i].entry.icon || ""),
        entry: rows[i].entry
      })
    }
    return out
  }

  function searchEmojis() {
    var results = filterEmojis(emojiData, filterText, 100)
    var out = []
    for (var i = 0; i < results.length; i++) {
      out.push({
        type: "emoji",
        label: (results[i].k || "").split(" ")[0] || "emoji",
        emojiChar: results[i].e
      })
    }
    return out
  }

  function searchFiles() {
    if (!fileResults || fileResults.length === 0) return []
    return fileResults.map(function(p) {
      return { type: "file", label: p }
    })
  }

  function searchClipboard() {
    if (clipboardData.length === 0 && filterText.length === 0) return []
    var results = filterClipboardHistory(clipboardData, filterText, 50)
    return results.map(function(r) {
      var entry = r.entry
      if (typeof entry === "string") {
        return {
          type: "clipboard",
          label: entry.replace(/\n/g, " ").substring(0, 120),
          detail: String(entry.length) + " chars",
          fullText: entry,
          imagePath: "",
          mime: ""
        }
      }
      if (entry.type === "image") {
        return {
          type: "clipboard",
          label: entry.capturedAt || "Image",
          detail: entry.mime || "",
          fullText: "",
          imagePath: String(entry.path || ""),
          mime: String(entry.mime || "")
        }
      }
      if (entry.type === "video") {
        return {
          type: "clipboard",
          label: entry.capturedAt || "Video",
          detail: entry.mime || "",
          fullText: "",
          imagePath: String(entry.thumbnail || entry.path || ""),
          mime: String(entry.mime || "")
        }
      }
      return {
        type: "clipboard",
        label: entry.text.replace(/\n/g, " ").substring(0, 120),
        detail: String(entry.text.length) + " chars",
        fullText: entry.text,
        imagePath: "",
        mime: ""
      }
    })
  }

  function activateSelected() {
    if (selectedIndex < 0 || selectedIndex >= displayModel.count) return
    var item = displayModel.get(selectedIndex)
    if (item.type === "app") {
      var entries = DesktopEntries.applications.values || []
      for (var i = 0; i < entries.length; i++) {
        if (entryName(entries[i]) === item.label) {
          entries[i].execute()
          dismiss()
          return
        }
      }
    }
    if (item.type === "emoji") {
      Quickshell.execDetached(["bash", "-c", "wl-copy '" + item.emojiChar.replace(/'/g, "'\\''") + "'"])
      dismiss()
    }
    if (item.type === "file") {
      Quickshell.execDetached(["bash", "-c", "xdg-open " + shellQuote(item.label)])
      dismiss()
    }
    if (item.type === "clipboard") {
      if (item.imagePath) {
        Quickshell.execDetached(["bash", "-c", "wl-copy --type " + shellQuote(item.mime) + " < " + shellQuote(item.imagePath)])
      } else {
        Quickshell.execDetached(["bash", "-c", "wl-copy " + shellQuote(item.fullText)])
      }
      dismiss()
    }
  }

  function copySelectedPath() {
    if (modeIndex !== 2 || selectedIndex < 0) return
    var item = displayModel.get(selectedIndex)
    if (item && item.type === "file") {
      Quickshell.execDetached(["bash", "-c", "wl-copy " + shellQuote(item.label)])
    }
  }

  function shellQuote(s) {
    return "'" + String(s || "").replace(/'/g, "'\\''") + "'"
  }

  function resolveIcon(name) {
    if (!name) return Quickshell.iconPath("application-x-executable", true)
    if (name.indexOf("/") >= 0) {
      if (name.indexOf("file://") === 0 || name.indexOf("image://") === 0) return name
      if (name.charAt(0) === "/") return "file://" + name
    }
    return Quickshell.iconPath(name, true)
  }

  // ---- inlined from LauncherAppSearch.js ----
  function entryName(entry) {
    return String((entry && entry.name) || (entry && entry.id) || "")
  }

  function entrySearchText(entry) {
    if (!entry) return ""
    return [entry.name, entry.genericName, entry.comment, entry.keywords ? entry.keywords.join(" ") : "", entry.id].join(" ").toLowerCase()
  }

  function entryAcronym(entry) {
    var vals = words([entry && entry.name, entry && entry.genericName, entry && entry.id].join(" "))
    var r = ""
    for (var i = 0; i < vals.length; i++) r += vals[i].charAt(0)
    return r
  }

  function words(value) {
    var v = String(value || "")
      .replace(/([a-z0-9])([A-Z])/g, "$1 $2")
      .replace(/[._:\/\\-]+/g, " ")
      .toLowerCase()
    return v.split(/[^a-z0-9]+/).filter(function(w) { return w.length > 0 })
  }

  function termMatches(entry, term) {
    if (!term) return true
    var name = entryName(entry).toLowerCase()
    var id = String((entry && entry.id) || "").toLowerCase()
    var haystack = entrySearchText(entry)
    if (name.indexOf(term) >= 0) return true
    if (id.indexOf(term) >= 0) return true
    if (haystack.indexOf(term) >= 0) return true
    return term.length <= 5 && entryAcronym(entry).indexOf(term) >= 0
  }

  function fuzzyScore(entry, query) {
    var q = String(query || "").trim().toLowerCase()
    if (!q) return 0
    var terms = q.split(/\s+/)
    for (var i = 0; i < terms.length; i++) {
      if (terms[i] && !termMatches(entry, terms[i])) return -1
    }
    var name = entryName(entry).toLowerCase()
    var id = String((entry && entry.id) || "").toLowerCase()
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
    var q = String(query || "").trim()
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

  // ---- inlined from EmojiSearch.js ----
  function filterEmojis(emojis, query, limit) {
    var values = Array.isArray(emojis) ? emojis : []
    var needle = String(query || "").trim().toLowerCase()
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

  // ---- inlined from ClipboardHistory.js ----
  function parseClipboardHistory(raw) {
    try {
      var parsed = JSON.parse(String(raw || "[]"))
      return Array.isArray(parsed) ? parsed : []
    } catch (e) {
      return []
    }
  }

  function filterClipboardHistory(history, query, limit) {
    var needle = String(query || "").trim().toLowerCase()
    var max = Math.max(0, Number(limit) || 50)
    if (max === 0) return []

    var out = []
    for (var i = 0; i < history.length; i++) {
      var entry = history[i]
      if (!entry) continue
      var searchText = ""
      if (typeof entry === "string") {
        searchText = entry
      } else if (entry.type === "image") {
        searchText = (entry.capturedAt || "") + " " + (entry.mime || "") + " image"
      } else if (entry.type === "video") {
        searchText = (entry.capturedAt || "") + " " + (entry.mime || "") + " video"
      } else {
        searchText = String(entry.text || "")
      }
      if (!needle || searchText.toLowerCase().indexOf(needle) >= 0) {
        out.push({ entry: entry, index: i })
        if (out.length >= max) break
      }
    }
    return out
  }

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.4)

    MouseArea {
      anchors.fill: parent
      onClicked: dismiss()
    }
  }

  FocusScope {
    id: content
    anchors.fill: parent
    focus: true

    Rectangle {
      id: card
      readonly property int cardWidth: 600
      readonly property int cardHeight: 420
      readonly property int headerHeight: 44

      width: Math.min(cardWidth, parent.width - Config.shellPadding * 2)
      height: Math.min(cardHeight, parent.height - Config.shellPadding * 2)
      radius: 7
      color: Config.backgroundColored
      // border.color: Config.accent
      // border.width: Config.borderSize
      anchors.centerIn: parent

      Column {
        anchors.fill: parent
        anchors.margins: Config.shellPadding
        spacing: 1

        Item {
          width: parent.width
          height: card.headerHeight

          Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Rectangle {
              id: modePill
              visible: root.modeIndex !== 0
              height: Config.fontSize + 6
              width: modePillLabel.width + 10
              radius: 3
              color: Config.accent
              anchors.verticalCenter: parent.verticalCenter

              Text {
                id: modePillLabel
                anchors.centerIn: parent
                text: root.modeNames[root.modeIndex]
                color: Config.foregroundSelected
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize - 2
              }
            }

            Item {
              width: root.modeIndex !== 0 ? 8 : 0
              height: 1
            }

            Text {
              id: textBefore
              text: root.filterText.length > 0
                ? root.filterText.substring(0, root.cursorPosition)
                : ""
              color: Config.foreground
              font.family: Config.fontFamily
              font.pixelSize: Config.fontSize
              anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
              width: 10
              height: Config.fontSize + 4
              color: Config.foreground
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              id: textAfter
              visible: root.filterText.length > 0
              text: root.filterText.substring(root.cursorPosition)
              color: Config.foreground
              font.family: Config.fontFamily
              font.pixelSize: Config.fontSize
              anchors.verticalCenter: parent.verticalCenter
            }

          }
        }

        Item {
          width: parent.width
          height: parent.height - card.headerHeight - 8 - 1

          ListView {
            id: resultList
            anchors.fill: parent
            model: displayModel
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
              required property int index
              required property string type
              required property string label
              required property string detail
              required property string emojiChar
              required property string iconName
              required property string fullText
              required property string imagePath
              required property string mime

              readonly property bool isSelected: index === root.selectedIndex

              width: ListView.view.width
              height: type === "emoji" ? 52 : 44
              radius: 3
              color: isSelected ? Config.accent : "transparent"

              Row {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 10

                Item {
                  width: type === "emoji" ? 48 : 32
                  height: parent.height

                  Text {
                    visible: type === "emoji"
                    text: emojiChar
                    font.pixelSize: 28
                    anchors.centerIn: parent
                  }

                  IconImage {
                    visible: type === "app"
                    anchors.centerIn: parent
                    implicitSize: 22
                    source: root.resolveIcon(iconName)
                    asynchronous: true
                  }

                  Text {
                    visible: type === "file"
                    text: "\uD83D\uDCC4"
                    font.pixelSize: 18
                    anchors.centerIn: parent
                  }

                  Item {
                    visible: type === "clipboard"
                    width: imagePath.length > 0 ? parent.height - 4 : 22
                    height: parent.height - 4
                    anchors.centerIn: parent
                    clip: true

                    Image {
                      visible: imagePath.length > 0
                      anchors.fill: parent
                      source: imagePath.length > 0 ? "file://" + imagePath : ""
                      fillMode: Image.PreserveAspectCrop
                      asynchronous: true
                      smooth: true
                    }

                    Rectangle {
                      visible: imagePath.length === 0
                      anchors.centerIn: parent
                      width: 16; height: 20; radius: 2
                      color: "transparent"
                      border.color: isSelected ? Config.foregroundSelected : Config.foreground
                      border.width: 2
                    }
                  }
                }

                Column {
                  width: parent.width - (type === "emoji" ? 48 + 10 : 32 + 10)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 2

                  Text {
                    width: parent.width
                    text: type === "clipboard" ? label : label
                    color: isSelected ? Config.foregroundSelected : Config.foreground
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    visible: detail.length > 0
                    text: detail
                    color: isSelected ? Config.foregroundSelected : Config.foregroundSecondary
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize - 4
                    opacity: 0.7
                    elide: Text.ElideRight
                  }
                }
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onContainsMouseChanged: {
                  if (containsMouse) root.selectedIndex = index
                }
                onClicked: {
                  root.selectedIndex = index
                  root.activateSelected()
                }
              }
            }
          }

          Text {
            anchors.centerIn: parent
            visible: displayModel.count === 0
            text: root.filterText.length > 0 ? "No results" : "Start typing\u2026"
            color: Config.foregroundSecondary
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize
          }
        }
      }
    }

    Item {
      id: keyCatcher
      anchors.fill: parent
      focus: true

      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          if (root.filterText.length > 0) {
            root.selectedIndex = 0
            root.filterText = ""
            root.cursorPosition = 0
          } else if (root.modeIndex !== 0) {
            root.setMode(0)
          } else {
            dismiss()
          }
          event.accepted = true
        } else if (event.key === Qt.Key_Backspace) {
          if (root.cursorPosition > 0) {
            root.filterText = root.filterText.substring(0, root.cursorPosition - 1) + root.filterText.substring(root.cursorPosition)
            root.cursorPosition--
            if (root.modeIndex !== 2) root.selectedIndex = 0
          } else if (root.modeIndex !== 0) {
            root.setMode(0)
          }
          event.accepted = true
        } else if (event.key === Qt.Key_Left) {
          root.cursorPosition = Math.max(0, root.cursorPosition - 1)
          event.accepted = true
        } else if (event.key === Qt.Key_Right) {
          root.cursorPosition = Math.min(root.filterText.length, root.cursorPosition + 1)
          event.accepted = true
        } else if (event.key === Qt.Key_Up) {
          if (displayModel.count > 0) {
            root.selectedIndex = (root.selectedIndex - 1 + displayModel.count) % displayModel.count
            root.positionToSelected()
          }
          event.accepted = true
        } else if (event.key === Qt.Key_Down) {
          if (displayModel.count > 0) {
            root.selectedIndex = (root.selectedIndex + 1) % displayModel.count
            root.positionToSelected()
          }
          event.accepted = true
        } else if (event.key === Qt.Key_PageUp) {
          if (displayModel.count > 0) {
            root.selectedIndex = Math.max(0, root.selectedIndex - 8)
            root.positionToSelected()
          }
          event.accepted = true
        } else if (event.key === Qt.Key_PageDown) {
          if (displayModel.count > 0) {
            root.selectedIndex = Math.min(displayModel.count - 1, root.selectedIndex + 8)
            root.positionToSelected()
          }
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          root.activateSelected()
          event.accepted = true
        } else if (event.key === Qt.Key_Y && (event.modifiers & Qt.ControlModifier)) {
          root.activateSelected()
          event.accepted = true
        } else if (event.key === Qt.Key_C && (event.modifiers & Qt.ControlModifier)) {
          if (root.modeIndex === 2) root.copySelectedPath()
          event.accepted = true
        } else if (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier)) {
          if (displayModel.count > 0) {
            root.selectedIndex = (root.selectedIndex - 1 + displayModel.count) % displayModel.count
            root.positionToSelected()
          }
          event.accepted = true
        } else if (event.key === Qt.Key_N && (event.modifiers & Qt.ControlModifier)) {
          if (displayModel.count > 0) {
            root.selectedIndex = (root.selectedIndex + 1) % displayModel.count
            root.positionToSelected()
          }
          event.accepted = true
        } else if (event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier)) {
          root.cursorPosition = 0
          event.accepted = true
        } else if (event.key === Qt.Key_E && (event.modifiers & Qt.ControlModifier)) {
          root.cursorPosition = root.filterText.length
          event.accepted = true
        } else if (event.key === Qt.Key_W && (event.modifiers & Qt.ControlModifier)) {
          if (root.cursorPosition === 0 && root.modeIndex !== 0) {
            root.setMode(0)
          } else if (root.cursorPosition > 0) {
            var pos = root.cursorPosition
            while (pos > 0 && root.filterText[pos - 1] === ' ') pos--
            while (pos > 0 && root.filterText[pos - 1] !== ' ') pos--
            if (pos < root.cursorPosition) {
              root.filterText = root.filterText.substring(0, pos) + root.filterText.substring(root.cursorPosition)
              root.cursorPosition = pos
              if (root.modeIndex !== 2) root.selectedIndex = 0
            }
          }
          event.accepted = true
        } else if (event.text && event.text.length === 1) {
          var char = event.text
          if (root.filterText.length === 0 && root.modeIndex === 0) {
            if (char === ":") { root.setMode(1); event.accepted = true; return }
            if (char === ".") { root.setMode(2); event.accepted = true; return }
            if (char === "$") { root.setMode(3); event.accepted = true; return }
          }
          if (char.charCodeAt(0) >= 32 && char.charCodeAt(0) !== 127) {
            root.selectedIndex = 0
            root.filterText = root.filterText.substring(0, root.cursorPosition) + char + root.filterText.substring(root.cursorPosition)
            root.cursorPosition++
            event.accepted = true
          }
        }
      }
    }
  }

  FileView {
    path: Quickshell.env("HOME") + "/.config.jmmm.sh/dotfiles/quickshell/Modules/Search/emojis.json"
    onLoaded: root.emojiData = root.parseEmojiJson(text())
    onLoadFailed: root.emojiData = []
  }

  FileView {
    id: clipFile
    path: Quickshell.env("HOME") + "/.local/state/clipboard-history.json"
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: {
      root.clipboardData = parseClipboardHistory(text())
      if (root.modeIndex === 3) root.rebuildDisplay()
    }
    onFileChanged: reload()
  }

  property string fdQueryMarker: ""

  Timer {
    id: fileSearchTimer
    interval: 200
    onTriggered: {
      if (root.modeIndex !== 2 || !root.filterText) {
        root.fileResults = []
        return
      }
      root.fdQueryMarker = root.filterText
      fdProc.command = ["fd", "-t", "f", "--max-results", "50", root.filterText, Quickshell.env("HOME")]
      fdProc.running = true
    }
  }

  Process {
    id: fdProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (root.fdQueryMarker !== root.filterText) return
        var lines = String(text || "").trim()
        if (!lines) {
          root.fileResults = []
          return
        }
        var parts = lines.split("\n")
        var paths = []
        for (var i = 0; i < parts.length; i++) {
          var p = String(parts[i] || "").trim()
          if (p) paths.push(p)
        }
        root.fileResults = paths
      }
    }
  }

  Connections {
    target: DesktopEntries.applications
    function onValuesChanged() {
        if (root.modeIndex === 0) root.rebuildDisplay()
    }
  }

  onModeIndexChanged: {
    if (modeIndex === 2 && filterText) {
      fileSearchTimer.restart()
    } else if (modeIndex !== 2) {
      clearFileSearch()
    }
    if (modeIndex === 3) rebuildDisplay()
  }

  onFilterTextChanged: {
    if (modeIndex === 2) {
      fileSearchTimer.restart()
    }
    if (modeIndex !== 2) {
      rebuildDisplay()
    }
  }

  onFileResultsChanged: {
    if (modeIndex === 2) rebuildDisplay()
  }
}
