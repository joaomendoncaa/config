import "."
import QtQuick
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    property bool hasCPU: true
    property bool hasRAM: true
    property bool hasGPU: true
    property bool hasNet: true

    width: Config.buttonSize * 2
    height: Config.buttonSize
    radius: Config.buttonBorderRadius
    color: mouseArea.containsMouse ? Config.backgroundHovered : "transparent"
    Component.onCompleted: {
        console.log("[Monitor] Component loaded, statFile.loaded:", statFile.loaded, "meminfoFile.loaded:", meminfoFile.loaded, "gpuFile.loaded:", gpuFile.loaded);
        if (statFile.loaded && meminfoFile.loaded) {
            var cpu = internal.parseCpuUsage();
            var ram = internal.parseRamUsage();
            internal.pushSample(cpu, ram, null, 0, 0);
            canvas.requestPaint();
        }
    }

    QtObject {
        id: internal

        readonly property int hPadding: 6
        readonly property int historySize: root.width
        readonly property int padding: 6
        property var cpuHistory: new Array(historySize).fill(0.5)
        property var ramHistory: new Array(historySize).fill(0.5)
        property var gpuHistory: new Array(historySize).fill(0.5)
        property var netHistory: new Array(historySize).fill(0.5)
        property int writeIndex: 0
        property var prevCpuStats: null
        property bool gpuAvailable: true
        property real pendingCpu: 0
        property real pendingRam: 0
        property real pendingNetDown: 0
        property real pendingNetUp: 0
        property var prevNetDownStats: null
        property var prevNetUpStats: null
        property var prevNetTime: null
        property string netIface: ""
        readonly property real maxDownSpeed: 500 * 1024 * 1024
        readonly property real maxUpSpeed: 100 * 1024 * 1024
        property var downHistory: new Array(historySize).fill(0)
        property var upHistory: new Array(historySize).fill(0)
        property real currentDown: 0
        property real currentUp: 0

        function scaleForBar(value) {
            if (value <= 0)
                return 0;

            return Math.pow(value, 0.33);
        }

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

        function parseGpuUsage(output) {
            if (!output || output.length === 0)
                return null;

            var trimmed = output.trim();
            var value = parseInt(trimmed, 10);
            if (isNaN(value) || value < 0 || value > 100)
                return null;

            return value / 100;
        }

        function findNetInterface(text) {
            var lines = text.split('\n');
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line.length === 0)
                    continue;

                if (line.startsWith("Inter-"))
                    continue;

                if (line.startsWith(" face"))
                    continue;

                var colonIdx = line.indexOf(':');
                if (colonIdx === -1)
                    continue;

                var name = line.substring(0, colonIdx).trim();
                if (name === "lo")
                    continue;

                return name;
            }
            return "";
        }

        function parseNetUsage() {
            if (!netdevFile.loaded) {
                pendingNetDown = 0;
                pendingNetUp = 0;
                return ;
            }
            var text = netdevFile.text();
            if (netIface === "") {
                netIface = findNetInterface(text);
                if (netIface === "") {
                    pendingNetDown = 0;
                    pendingNetUp = 0;
                    return ;
                }
            }
            var lines = text.split('\n');
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                var colonIdx = line.indexOf(':');
                if (colonIdx === -1)
                    continue;

                var name = line.substring(0, colonIdx).trim();
                if (name !== netIface)
                    continue;

                var parts = line.substring(colonIdx + 1).trim().split(/\s+/);
                var rx = parseInt(parts[0], 10) || 0;
                var tx = parseInt(parts[8], 10) || 0;
                var now = Date.now();
                var downUsed = 0;
                var upUsed = 0;
                if (prevNetDownStats !== null && prevNetUpStats !== null && prevNetTime !== null) {
                    var elapsed = (now - prevNetTime) / 1000;
                    if (elapsed > 0) {
                        var rxDiff = rx - prevNetDownStats;
                        var txDiff = tx - prevNetUpStats;
                        downUsed = Math.max(0, rxDiff) / elapsed;
                        upUsed = Math.max(0, txDiff) / elapsed;
                    }
                }
                prevNetDownStats = rx;
                prevNetUpStats = tx;
                prevNetTime = now;
                pendingNetDown = Math.min(downUsed / maxDownSpeed, 1);
                pendingNetUp = Math.min(upUsed / maxUpSpeed, 1);
                return ;
            }
            netIface = "";
            pendingNetDown = 0;
            pendingNetUp = 0;
        }

        function pushSample(cpu, ram, gpu, netDown, netUp) {
            cpuHistory[writeIndex] = Math.round(cpu * 10) / 10;
            ramHistory[writeIndex] = Math.round(ram * 10) / 10;
            netHistory[writeIndex] = Math.round((netDown + netUp) / 2 * 10) / 10;
            downHistory[writeIndex] = Math.round(netDown * 10) / 10;
            upHistory[writeIndex] = Math.round(netUp * 10) / 10;
            currentDown = netDown;
            currentUp = netUp;
            if (gpu !== null)
                gpuHistory[writeIndex] = Math.round(gpu * 10) / 10;

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

    FileView {
        id: gpuFile

        blockLoading: true
        path: "file:///tmp/quickshell_gpu_usage"
    }

    FileView {
        id: netdevFile

        blockLoading: true
        path: "file:///proc/net/dev"
    }

    Process {
        id: nvidiaSmiProc

        running: false
        command: ["sh", "-c", "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits > /tmp/quickshell_gpu_usage"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.log("[GPU] Process failed, disabling GPU");
                internal.gpuAvailable = false;
                return ;
            }
            gpuFile.reload();
        }
    }

    Connections {
        function onTextChanged() {
            var text = gpuFile.text();
            if (!text || text.length === 0)
                return ;

            var gpu = internal.parseGpuUsage(text);
            if (gpu === null) {
                console.log("[GPU] Parse failed, disabling GPU");
                internal.gpuAvailable = false;
                return ;
            }
            internal.pushSample(internal.pendingCpu, internal.pendingRam, gpu, internal.pendingNetDown, internal.pendingNetUp);
            canvas.requestPaint();
        }

        target: gpuFile
    }

    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: {
            statFile.reload();
            meminfoFile.reload();
            netdevFile.reload();
            if (internal.gpuAvailable && !nvidiaSmiProc.running)
                nvidiaSmiProc.running = true;

        }
    }

    Connections {
        function onTextChanged() {
            if (statFile.loaded && meminfoFile.loaded && netdevFile.loaded) {
                var cpu = internal.parseCpuUsage();
                var ram = internal.parseRamUsage();
                internal.parseNetUsage();
                internal.pendingCpu = cpu;
                internal.pendingRam = ram;
                if (!internal.gpuAvailable) {
                    internal.pushSample(cpu, ram, null, internal.pendingNetDown, internal.pendingNetUp);
                    canvas.requestPaint();
                }
            }
        }

        target: statFile
    }

    Canvas {
        id: canvas

        anchors.left: parent.left
        anchors.leftMargin: internal.hPadding
        width: root.width - netBars.width - internal.hPadding * 2 - 2
        height: root.height
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
            ctx.lineWidth = 1;
            ctx.setLineDash([]);
            ctx.beginPath();
            ctx.moveTo(0, pad);
            ctx.lineTo(w, pad);
            ctx.moveTo(0, h - pad);
            ctx.lineTo(w, h - pad);
            ctx.stroke();
            ctx.strokeStyle = Config.foreground;
            if (root.hasCPU) {
                ctx.setLineDash([]);
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
            }
            if (root.hasRAM) {
                ctx.setLineDash([4, 2]);
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
            if (root.hasGPU && internal.gpuAvailable) {
                ctx.setLineDash([1, 1]);
                ctx.beginPath();
                for (var k = 0; k < historySize; k++) {
                    var gpuIdx = (writeIdx + k) % historySize;
                    var gx = k;
                    var gy = pad + (1 - internal.gpuHistory[gpuIdx]) * graphH;
                    if (k === 0)
                        ctx.moveTo(gx, gy);
                    else
                        ctx.lineTo(gx, gy);
                }
                ctx.stroke();
            }
        }
    }

    Item {
        id: netBars

        anchors.right: parent.right
        anchors.rightMargin: internal.hPadding
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: downBarBg.width + upBarBg.width + 2

        Rectangle {
            id: downBarBg

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: internal.padding
            anchors.bottom: parent.bottom
            anchors.bottomMargin: internal.padding
            width: 5
            color: Config.foregroundSecondary

            Rectangle {
                id: downBarFill

                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: internal.currentDown > 0 ? Math.max(2, Math.min(parent.height * internal.scaleForBar(internal.currentDown), parent.height)) : 0
                color: Config.foreground
            }

        }

        Rectangle {
            id: upBarBg

            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: internal.padding
            anchors.bottom: parent.bottom
            anchors.bottomMargin: internal.padding
            width: 5
            color: Config.foregroundSecondary

            Rectangle {
                id: upBarFill

                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                height: internal.currentUp > 0 ? Math.max(2, Math.min(parent.height * internal.scaleForBar(internal.currentUp), parent.height)) : 0
                color: Config.foreground
            }

        }

    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: {
        }
    }

}
