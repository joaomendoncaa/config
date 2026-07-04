import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core

Rectangle {
    id: root

    property int updateCount: 0
    property var packages: []
    property var lastUpdated: new Date(0)
    property QtObject barWindow: null
    property var listProcess
    property var upgradeProcess
    property var upgradeQueue: []
    property bool upgrading: false
    property bool upgradingAll: false
    property var upgradingPackages: []

    signal toggle()
    signal upgradeStarted()
    signal upgradeFinished()

    function refresh() {
        root.listProcess.running = true;
    }

    function enqueueUpgrade(pkgName, source) {
        for (var i = 0; i < root.upgradeQueue.length; i++) {
            if (root.upgradeQueue[i].name === pkgName)
                return ;

        }
        root.upgradeQueue.push({
            "name": pkgName,
            "source": source
        });
        processQueue();
    }

    function enqueueUpgradeAll() {
        root.upgradingAll = true;
        for (var i = 0; i < root.packages.length; i++) {
            var dup = false;
            for (var j = 0; j < root.upgradeQueue.length; j++) {
                if (root.upgradeQueue[j].name === root.packages[i].name) {
                    dup = true;
                    break;
                }
            }
            if (!dup)
                root.upgradeQueue.push({
                    "name": root.packages[i].name,
                    "source": root.packages[i].source
                });

        }
        processQueue();
    }

    function processQueue() {
        if (root.upgrading || root.upgradeQueue.length === 0)
            return ;

        root.upgrading = true;
        root.upgradeStarted();
        var yayPkgs = [];
        var flatpakPkgs = [];
        root.upgradingPackages = [];
        for (var i = 0; i < root.upgradeQueue.length; i++) {
            root.upgradingPackages.push(root.upgradeQueue[i].name);
            if (root.upgradeQueue[i].source === "flatpak")
                flatpakPkgs.push(root.upgradeQueue[i].name);
            else
                yayPkgs.push(root.upgradeQueue[i].name);
        }
        root.upgradeQueue = [];
        var script = "";
        if (yayPkgs.length > 0)
            script += "yay -S --noconfirm " + yayPkgs.join(" ") + " 2>&1; ";

        if (flatpakPkgs.length > 0)
            script += "flatpak update --noninteractive -y " + flatpakPkgs.join(" ") + " 2>&1; ";

        if (script.length === 0) {
            root.upgrading = false;
            return ;
        }
        root.upgradeProcess.command = ["bash", "-c", script];
        root.upgradeProcess.running = true;
    }

    Layout.preferredWidth: Config.buttonSize
    Layout.preferredHeight: Config.buttonSize
    radius: Config.buttonBorderRadius
    color: mouseArea.containsMouse && root.updateCount > 0 ? Config.foreground : "transparent"
    opacity: root.updateCount > 0 ? 1 : 0

    Rectangle {
        id: badge

        anchors.centerIn: parent
        width: Config.buttonSize * 0.7
        height: Config.buttonSize * 0.7
        radius: width / 2
        color: root.upgrading ? Config.accent : Config.foreground

        Text {
            id: badgeText

            anchors.centerIn: parent
            text: root.upgrading ? "\uf110" : root.updateCount > 9 ? "+9" : root.updateCount
            color: Config.foregroundSelected
            font.pixelSize: Config.fontSize * 0.75
            font.family: Config.fontFamily
            font.bold: true
        }

        RotationAnimator {
            target: badge
            from: 0
            to: 360
            duration: 1000
            running: root.upgrading
            loops: Animation.Infinite
        }

    }

    Timer {
        id: updateTimer

        interval: 7.2e+06
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: refresh()
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        cursorShape: root.updateCount > 0 || root.upgrading ? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: root.updateCount > 0 || root.upgrading
        enabled: root.updateCount > 0 || root.upgrading
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton)
                Quickshell.execDetached(["omarchy-launch-floating-terminal-with-presentation", "omarchy-update"]);
            else
                root.toggle();
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 200
        }

    }

    listProcess: Process {
        command: ["qs-update-panel-list"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var output = root.listProcess.stdout.text.trim();
                    if (output.length > 0) {
                        var parsed = JSON.parse(output);
                        if (Array.isArray(parsed)) {
                            root.packages = parsed;
                            root.updateCount = parsed.length;
                            root.lastUpdated = new Date();
                        }
                    }
                } catch (e) {
                    console.warn("[Updates] Failed to parse package list:", e);
                }
            }
        }

    }

    upgradeProcess: Process {
        command: ["true"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var output = root.upgradeProcess.stdout.text.trim();
                if (output.length > 0) {
                    var lower = output.toLowerCase();
                    if (lower.indexOf("error:") >= 0 || lower.indexOf("failed:") >= 0 || lower.indexOf("==> error") >= 0) {
                        var escaped = output.replace(/'/g, "'\\''");
                        Quickshell.execDetached(["bash", "-c", 'notify-send "Update failed" "$(echo \'' + escaped + '\' | tail -10)"']);
                    }
                }
                root.upgrading = false;
                root.upgradingAll = false;
                root.upgradingPackages = [];
                root.upgradeFinished();
                root.refresh();
                root.processQueue();
            }
        }

    }

}
