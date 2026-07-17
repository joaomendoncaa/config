import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

QtObject {
    id: profiler

    property bool enabled: true
    property string outputPath: "/tmp/quickshell-trace.json"

    property var _events: []
    property int _pid: 1
    property int _tid: 1
    property var _active: ({})
    property var _counters: ({})

    property var _file: FileView {
        path: profiler.outputPath
        printErrors: false
    }

    function begin(name, cat) {
        if (!enabled) return
        cat = cat || "qml"
        _events.push({
            name: name,
            cat: cat,
            ph: "B",
            ts: Date.now() * 1000,
            pid: _pid,
            tid: _tid
        })
        _active[name] = true
    }

    function end(name) {
        if (!enabled) return
        if (!_active[name]) return
        _events.push({
            name: name,
            cat: _getCat(name),
            ph: "E",
            ts: Date.now() * 1000,
            pid: _pid,
            tid: _tid
        })
        delete _active[name]
    }

    function instant(name, cat) {
        if (!enabled) return
        cat = cat || "qml"
        _events.push({
            name: name,
            cat: cat,
            ph: "I",
            s: "g",
            ts: Date.now() * 1000,
            pid: _pid,
            tid: _tid
        })
    }

    function counter(name, value) {
        if (!enabled) return
        _counters[name] = value
        var args = {}
        for (var k in _counters) args[k] = _counters[k]
        _events.push({
            name: "counters",
            cat: "counter",
            ph: "C",
            ts: Date.now() * 1000,
            pid: _pid,
            tid: _tid,
            args: args
        })
    }

    function flush() {
        if (!enabled || _events.length === 0) return
        var trace = {
            traceEvents: _events.slice(),
            displayTimeUnit: "ms"
        }
        _file.setText(JSON.stringify(trace, null, 2) + "\n")
    }

    function _getCat(name) {
        if (name.indexOf("token") >= 0) return "network"
        if (name.indexOf("render") >= 0 || name.indexOf("bar") >= 0) return "render"
        if (name.indexOf("notif") >= 0) return "notifications"
        if (name.indexOf("binding") >= 0) return "bindings"
        return "qml"
    }

    Component.onCompleted: {
        _file.setText(JSON.stringify({ traceEvents: [], displayTimeUnit: "ms" }, null, 2) + "\n")
    }
}
