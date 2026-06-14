import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Core
import "Utils.js" as Utils
import "Widgets"


PanelWindow {
  id: root

  signal dismissed

  readonly property var modeNames: ["apps", "emojis", "files", "clipboard", "calc", "chart"]
  property int modeIndex: 0
  property string filterText: ""
  property int selectedIndex: 0
  property int cursorPosition: 0

  property var emojiData: []
  property var clipboardData: []
  property var fileResults: []
  property string calcResult: ""
  property string calcQueryMarker: ""

  property bool chartInitialized: false
  property string chartQueryMarker: ""

  ListModel { id: displayModel }

  function dismiss() {
    dismissed()
  }

  exclusiveZone: 0
  color: "transparent"
  anchors { left: true; right: true; top: true; bottom: true }
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "superbar"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  exclusionMode: ExclusionMode.Ignore

  Component.onCompleted: {
    rebuildDisplay()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }



  function setMode(mode) {
    if (mode < 0 || mode > 5) return
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
      case 4: return searchCalc()
    }
    return []
  }

  function searchApps() {
    var entries = DesktopEntries.applications.values || []
    var rows = Utils.sortedEntries(entries, filterText)
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
    var results = Utils.filterEmojis(emojiData, filterText, 100)
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
    var results = Utils.filterClipboardHistory(clipboardData, filterText, 50)
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

  function searchCalc() {
    if (!filterText) return []
    if (!calcResult || calcQueryMarker !== filterText) return []
    return [{ type: "calc", label: calcResult, fullText: calcResult }]
  }

  function activateSelected() {
    if (selectedIndex < 0 || selectedIndex >= displayModel.count) return
    var item = displayModel.get(selectedIndex)
    if (item.type === "app") {
      var entries = DesktopEntries.applications.values || []
      for (var i = 0; i < entries.length; i++) {
        if (Utils.entryName(entries[i]) === item.label) {
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
      Quickshell.execDetached(["bash", "-c", "xdg-open " + Utils.shellQuote(item.label)])
      dismiss()
    }
    if (item.type === "clipboard") {
      if (item.imagePath) {
        Quickshell.execDetached(["bash", "-c", "wl-copy --type " + Utils.shellQuote(item.mime) + " < " + Utils.shellQuote(item.imagePath)])
      } else {
        Quickshell.execDetached(["bash", "-c", "wl-copy " + Utils.shellQuote(item.fullText)])
      }
      dismiss()
    }
    if (item.type === "calc") {
      Quickshell.execDetached(["bash", "-c", "wl-copy " + Utils.shellQuote(item.fullText)])
      dismiss()
    }
  }

  function copySelectedPath() {
    if (modeIndex !== 2 || selectedIndex < 0) return
    var item = displayModel.get(selectedIndex)
    if (item && item.type === "file") {
      Quickshell.execDetached(["bash", "-c", "wl-copy " + Utils.shellQuote(item.label)])
    }
  }



  function resolveIcon(name) {
    if (!name) return Quickshell.iconPath("application-x-executable", true)
    if (name.indexOf("/") >= 0) {
      if (name.indexOf("file://") === 0 || name.indexOf("image://") === 0) return name
      if (name.charAt(0) === "/") return "file://" + name
    }
    return Quickshell.iconPath(name, true)
  }



  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.2)

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
      readonly property int cardWidth: 900
      readonly property int cardHeight: 420

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

        SearchInput {
          id: searchInput
          width: parent.width
          height: Config.fontSize + 16
          modeIndex: root.modeIndex
          modeNames: root.modeNames
          filterText: root.filterText
          cursorPosition: root.cursorPosition
        }

        Item {
          width: parent.width
          height: parent.height - searchInput.height - parent.spacing

          Row {
            visible: root.modeIndex !== 5
            anchors.fill: parent
            spacing: 0

            Item {
              width: parent.width - (previewPanel.visible ? previewPanel.width : 0)
              height: parent.height

              ListView {
                id: resultList
                anchors.fill: parent
                model: displayModel
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds

                delegate: ResultDelegate {
                  selectedIndex: root.selectedIndex
                  iconResolver: function(name) { return root.resolveIcon(name) }
                  onItemHovered: root.selectedIndex = index
                  onItemClicked: {
                    root.selectedIndex = index
                    root.activateSelected()
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

            Preview {
              id: previewPanel
              displayModel: displayModel
              selectedIndex: root.selectedIndex
              active: root.modeIndex === 3
            }
          }

          Loader {
            id: chartLoader
            active: root.chartInitialized
            visible: root.modeIndex === 5
            anchors.fill: parent
            source: "Widgets/Chart/Chart.qml"
          }
        }
      }
    }

    KeyIntercept {
      id: keyCatcher
      anchors.fill: parent
      root: root
      displayModel: displayModel
    }
  }

  FileView {
    path: Quickshell.env("HOME") + "/.config.jmmm.sh/dotfiles/quickshell/Data/emojis.json"
    onLoaded:     root.emojiData = Utils.parseEmojiJson(text())
    onLoadFailed: root.emojiData = []
  }

  FileView {
    id: clipFile
    path: Quickshell.env("HOME") + "/.local/state/clipboard-history.json"
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: {
      root.clipboardData = Utils.parseClipboardHistory(text())
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

  Timer {
    id: calcTimer
    interval: 200
    onTriggered: {
      if (root.modeIndex !== 4 || !root.filterText) return
      root.calcQueryMarker = root.filterText
      root.calcResult = ""
      calcProc.command = ["qalc", "-t", root.filterText]
      calcProc.running = true
    }
  }

  Process {
    id: calcProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (root.calcQueryMarker !== root.filterText) return
        root.calcResult = String(text || "").trim()
      }
    }
  }

  Timer {
    id: chartTimer
    interval: 400
    onTriggered: {
      if (root.modeIndex !== 5 || !root.filterText) return
      root.chartQueryMarker = root.filterText
      var chart = chartLoader.item
      if (chart) chart.symbol = root.filterText
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
    if (modeIndex === 5 && !chartInitialized) {
      chartInitialized = true
    }
  }

  onFilterTextChanged: {
    if (modeIndex === 2) {
      fileSearchTimer.restart()
    }
    if (modeIndex === 4) {
      root.calcResult = ""
      calcTimer.restart()
    }
    if (modeIndex === 5) {
      chartTimer.restart()
    }
    if (modeIndex !== 2) {
      rebuildDisplay()
    }
  }

  onCalcResultChanged: {
    if (modeIndex === 4) rebuildDisplay()
  }

  onFileResultsChanged: {
    if (modeIndex === 2) rebuildDisplay()
  }

}
