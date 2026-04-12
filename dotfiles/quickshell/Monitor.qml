import "."
import QtQuick
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    width: Config.buttonSize
    height: Config.buttonSize
    radius: Config.buttonBorderRadius
    color: mouseArea.containsMouse ? Config.backgroundHovered : "transparent"
    Component.onCompleted: {
        if (statFile.loaded && meminfoFile.loaded) {
            var cpu = internal.parseCpuUsage();
            var ram = internal.parseRamUsage();
            internal.pushSample(cpu, ram);
            canvas.requestPaint();
        }
    }

    QtObject {
        id: internal

        readonly property int historySize: 26
        readonly property int padding: 6
        property var cpuHistory: new Array(historySize).fill(0.5)
        property var ramHistory: new Array(historySize).fill(0.5)
        property int writeIndex: 0
        property var prevCpuStats: null

        function parseCpuUsage() {
            var lines = statFile.text().split('\n');
            var cpuLine = lines[0];
            var parts = cpuLine.split(/\s+/);
            var user = parseInt(parts[1], 10) || 0;
            var nice = parseInt(parts[2], 10) || 0;
            var system = parseInt(parts[3], 10) || 0;
            var idle = parseInt(parts[4], 10) || 0;
            var currentStats = {
                "user": user,
                "nice": nice,
                "system": system,
                "idle": idle
            };
            if (prevCpuStats === null) {
                prevCpuStats = currentStats;
                return 0;
            }
            var userDiff = currentStats.user - prevCpuStats.user;
            var niceDiff = currentStats.nice - prevCpuStats.nice;
            var systemDiff = currentStats.system - prevCpuStats.system;
            var idleDiff = currentStats.idle - prevCpuStats.idle;
            var totalDiff = userDiff + niceDiff + systemDiff + idleDiff;
            var usage = totalDiff > 0 ? (totalDiff - idleDiff) / totalDiff : 0;
            prevCpuStats = currentStats;
            return usage;
        }

        function parseRamUsage() {
            var text = meminfoFile.text();
            var totalMatch = text.match(/MemTotal:\s+(\d+)/);
            var availableMatch = text.match(/MemAvailable:\s+(\d+)/);
            if (!totalMatch || !availableMatch)
                return 0;

            var total = parseInt(totalMatch[1], 10);
            var available = parseInt(availableMatch[1], 10);
            if (total === 0)
                return 0;

            return (total - available) / total;
        }

        function pushSample(cpu, ram) {
            cpuHistory[writeIndex] = Math.round(cpu * 10) / 10;
            ramHistory[writeIndex] = Math.round(ram * 10) / 10;
            writeIndex = (writeIndex + 1) % historySize;
        }

    }

    FileView {
        id: statFile

        blockLoading: true
        path: "file:///proc/stat"
    }

    FileView {
        id: meminfoFile

        blockLoading: true
        path: "file:///proc/meminfo"
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            statFile.reload();
            meminfoFile.reload();
        }
    }

    Connections {
        function onTextChanged() {
            if (statFile.loaded && meminfoFile.loaded) {
                var cpu = internal.parseCpuUsage();
                var ram = internal.parseRamUsage();
                internal.pushSample(cpu, ram);
                canvas.requestPaint();
            }
        }

        target: statFile
    }

    Canvas {
        id: canvas

        anchors.centerIn: parent
        width: Config.buttonSize
        height: Config.buttonSize
        onPaint: {
            var ctx = getContext('2d');
            var w = width;
            var h = height;
            var pad = internal.padding;
            var graphH = h - pad * 2;
            var historySize = internal.historySize;
            var writeIdx = internal.writeIndex;
            ctx.clearRect(0, 0, w, h);
            ctx.strokeStyle = Config.foregroundSecondary;
            ctx.lineWidth = 2;
            ctx.setLineDash([]);
            ctx.beginPath();
            ctx.moveTo(0, pad);
            ctx.lineTo(w, pad);
            ctx.moveTo(0, h - pad);
            ctx.lineTo(w, h - pad);
            ctx.stroke();
            ctx.strokeStyle = Config.foreground;
            ctx.beginPath();
            for (var i = 0; i < historySize; i++) {
                var dataIdx = (writeIdx + i) % historySize;
                var x = i;
                var y = pad + (1 - internal.cpuHistory[dataIdx]) * graphH;
                if (i === 0)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }
            ctx.stroke();
            ctx.setLineDash([4, 4]);
            ctx.beginPath();
            for (var j = 0; j < historySize; j++) {
                var ramIdx = (writeIdx + j) % historySize;
                var rx = j;
                var ry = pad + (1 - internal.ramHistory[ramIdx]) * graphH;
                if (j === 0)
                    ctx.moveTo(rx, ry);
                else
                    ctx.lineTo(rx, ry);
            }
            ctx.stroke();
        }
    }

    MouseArea {
        // TODO: btop panel onClicked

        id: mouseArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: {
        }
    }

}
