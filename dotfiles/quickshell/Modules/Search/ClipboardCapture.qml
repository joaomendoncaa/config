import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateDir: home + "/.local/state"
  readonly property string scriptPath: home + "/.config/quickshell/Modules/Search/capture.sh"
  property var history: []

  function capture(entry) {
    if (!entry || typeof entry !== "object") return
    if (!entry.type) return
    var key = entryKey(entry)
    if (history.length > 0 && entryKey(history[0]) === key) return
    var next = [entry]
    for (var i = 0; i < history.length && next.length < 300; i++) {
      if (entryKey(history[i]) !== key) next.push(history[i])
    }
    history = next
    persist()
  }

  function entryKey(entry) {
    if (entry.type === "image") return "image:" + String(entry.path || "")
    return "text:" + String(entry.text || "")
  }

  function persist() {
    historyFile.setText(JSON.stringify(history, null, 2) + "\n")
  }

  function load(raw) {
    try {
      var parsed = JSON.parse(String(raw || "[]"))
      history = Array.isArray(parsed) ? parsed : []
    } catch (e) {
      history = []
    }
  }

  function poll() {
    pollProc.command = ["bash", "-c", "chmod +x " + scriptPath + " 2>/dev/null; " + scriptPath]
    pollProc.running = true
  }

  FileView {
    id: historyFile
    path: root.stateDir + "/clipboard-history.json"
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.load(text())
    onLoadFailed: root.load("[]")
  }

  Process {
    id: pollProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text || "").trim()
        if (!raw) return
        try {
          var entry = JSON.parse(raw)
          root.capture(entry)
        } catch (e) {}
      }
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.poll()
  }
}
