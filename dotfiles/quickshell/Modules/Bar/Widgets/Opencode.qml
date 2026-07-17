import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Core
import "../../../Widgets"

Rectangle {
    id: root

    property QtObject barWindow: null
    property bool popupVisible: false
    property string workspaceId: Quickshell.env("QUICKSHELL_OPENCODE_WORKSPACE_ID") || "wrk_01KEYSE6SWHFGJ2DB8C2690QJ2"
    property var usageData: null
    property real pct5h: 0
    property real pctWeekly: 0
    property real pctMonthly: 0
    property string reset5h: ""
    property string resetWeekly: ""
    property string resetMonthly: ""
    property string balance: ""
    property string sessionState: "working"
    property int spinnerFrame: 0
    readonly property var spinnerChars: ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]

    ListModel {
        id: sessionModel
    }

    function fetchUsage() {
        usageProc.running = true;
    }

    function parseSessions(output) {
        console.log("[Opencode] parseSessions called, raw length:", output.length);
        sessionModel.clear();
        var trimmed = output.trim();
        console.log("[Opencode] parseSessions trimmed length:", trimmed.length);
        if (trimmed === '') {
            console.log("[Opencode] parseSessions — empty result, no sessions found");
            return;
        }
        var titles = trimmed.split('\n');
        console.log("[Opencode] parseSessions — found", titles.length, "sessions:", JSON.stringify(titles));
        for (var i = 0; i < titles.length; i++) {
            sessionModel.append({title: titles[i]});
        }
        console.log("[Opencode] parseSessions — sessionModel.count:", sessionModel.count);
    }

    function scaleForBar(value) {
        if (value <= 0)
            return 0;

        return Math.pow(value, 0.66);
    }

    function parseUsage(output) {
        console.log("[Opencode] parseUsage called, output length:", output.length);
        try {
            var data = JSON.parse(output);
            console.log("[Opencode] parseUsage parsed data:", JSON.stringify(data).substring(0, 200));
            usageData = data;
            balance = data.billing && data.billing.balance ? data.billing.balance : "";
            if (data.usage) {
                if (data.usage["5h"]) {
                    pct5h = Number(data.usage["5h"].current) || 0;
                    reset5h = data.usage["5h"].reset || "";
                }
                if (data.usage.weekly) {
                    pctWeekly = Number(data.usage.weekly.current) || 0;
                    resetWeekly = data.usage.weekly.reset || "";
                }
                if (data.usage.monthly) {
                    pctMonthly = Number(data.usage.monthly.current) || 0;
                    resetMonthly = data.usage.monthly.reset || "";
                }
            }
        } catch (e) {
            console.warn("[Opencode] Failed to parse usage:", e);
        }
    }

    Layout.fillWidth: true
    Layout.preferredWidth: Config.buttonSize * 5
    Layout.preferredHeight: Config.buttonSize
    Layout.leftMargin: Config.gapOuter
    color: "transparent"

    readonly property real defaultTitleWidth: 200
    readonly property real minTitleWidth: 40
    readonly property real perSessionTitleWidth: {
        if (sessionModel.count === 0)
            return 0;
        var n = sessionModel.count;
        var fixed = iconContainer.width + 4 + battery5h.width + 6 + 4;
        var spinnerEstimate = Config.fontSize * 0.6;
        var perSessionOverhead = spinnerEstimate + 3;
        var interSession = (n - 1) * 8;
        var available = width - fixed - (n * perSessionOverhead) - interSession;
        var perTitle = available / n;
        return Math.max(minTitleWidth, Math.min(defaultTitleWidth, perTitle));
    }

    Item {
        id: iconContainer

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Config.buttonSize * 0.7
        height: Config.buttonSize * 0.7

        Image {
            id: maskImage

            anchors.fill: parent
            source: "../../../Assets/opencode-logo.svg"
            sourceSize.width: width
            sourceSize.height: height
            smooth: true
            visible: false
        }

        Rectangle {
            id: fgColor

            anchors.fill: parent
            color: Config.foreground
            visible: false
        }

        OpacityMask {
            anchors.fill: parent
            source: fgColor
            maskSource: maskImage
        }

    }

    Item {
        id: battery5h

        anchors.left: iconContainer.right
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        width: 8
        height: Config.buttonSize * 0.55

        Rectangle {
            anchors.fill: parent
            radius: 2
            color: Config.foregroundSecondary

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 2
                width: parent.width - 4
                height: (parent.height - 4) * scaleForBar(Math.max(0, 1 - Math.min(Math.max(root.pct5h, 0), 100) / 100))
                radius: 1
                color: Config.foreground
            }

        }

    }

    Item {
        id: sessionDisplay

        anchors.left: battery5h.right
        anchors.leftMargin: 6
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        visible: sessionModel.count > 0

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Repeater {
                model: sessionModel

                delegate: Item {
                    required property string title

                    width: spinnerText.implicitWidth + 3 + titleText.width
                    height: sessionDisplay.height

                    Text {
                        id: spinnerText
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        text: spinnerChars[spinnerFrame]
                        color: Config.foreground
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize
                    }

                    MarqueeText {
                        id: titleText
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: spinnerText.right
                        anchors.leftMargin: 3
                        width: perSessionTitleWidth
                        height: parent.height
                        text: title
                        textColor: Config.foreground
                        fontFamily: Config.fontFamily
                        fontSize: Config.fontSize
                    }
                }
            }
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            var item = popupLoader.item;
            if (item && item.visible)
                item.visible = false;
            else if (!root.popupVisible)
                root.popupVisible = true;
        }
    }

    LazyLoader {
        id: popupLoader

        active: root.popupVisible

        PopupWindow {
            id: popup

            visible: true
            anchor.window: root.barWindow
            implicitWidth: 340
            implicitHeight: 250
            color: "transparent"
            onVisibleChanged: {
                if (!visible && root.popupVisible)
                    root.popupVisible = false;

            }
            Component.onCompleted: {
                console.log("[Opencode] PopupWindow Component.onCompleted — fetching usage");
                if (root.barWindow) {
                    var pos = root.mapToItem(root.barWindow.contentItem, 0, 0);
                    anchor.rect.x = pos.x;
                    anchor.rect.y = pos.y + root.height + Config.gapsOut + Config.borderSize;
                }
                root.fetchUsage();
            }

            Rectangle {
                id: popupBg

                anchors.fill: parent
                color: Config.backgroundColored
                radius: 5
                focus: true
                Keys.onEscapePressed: root.popupVisible = false

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 0

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: "5H"
                                color: Config.foreground
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSize - 2
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "🗲 " + root.reset5h
                                color: Config.foreground
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSize - 2
                            }

                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            radius: 2
                            color: Config.foregroundSecondary

                            Rectangle {
                                x: 3
                                y: 3
                                height: parent.height - 6
                                radius: 1
                                width: (parent.width - 6) * Math.max(0, 1 - Math.min(Math.max(root.pct5h, 0), 100) / 100)
                                color: Config.foreground
                            }

                        }

                    }

                    Item {
                        Layout.preferredHeight: 10
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: "1W"
                                color: Config.foreground
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSize - 2
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "🗲 " + root.resetWeekly
                                color: Config.foreground
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSize - 2
                            }

                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            radius: 2
                            color: Config.foregroundSecondary

                            Rectangle {
                                x: 3
                                y: 3
                                height: parent.height - 6
                                radius: 1
                                width: (parent.width - 6) * Math.max(0, 1 - Math.min(Math.max(root.pctWeekly, 0), 100) / 100)
                                color: Config.foreground
                            }

                        }

                    }

                    Item {
                        Layout.preferredHeight: 10
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: "1M"
                                color: Config.foreground
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSize - 2
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "🗲 " + root.resetMonthly
                                color: Config.foreground
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSize - 2
                            }

                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            radius: 2
                            color: Config.foregroundSecondary

                            Rectangle {
                                x: 3
                                y: 3
                                height: parent.height - 6
                                radius: 1
                                width: (parent.width - 6) * Math.max(0, 1 - Math.min(Math.max(root.pctMonthly, 0), 100) / 100)
                                color: Config.foreground
                            }

                        }

                    }

                    Item {
                        Layout.preferredHeight: 16
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Rectangle {
                            Layout.preferredHeight: balanceLabel.height + 8
                            Layout.preferredWidth: balanceLabel.width + 16
                            radius: 2
                            color: Config.foreground

                            Text {
                                id: balanceLabel

                                anchors.centerIn: parent
                                text: "BALANCE " + (root.balance || "...")
                                color: Config.backgroundColored
                                font.family: Config.fontFamily
                                font.weight: Font.Medium
                                font.pixelSize: Config.fontSize - 2
                            }

                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            color: dashboardLinkMouse.containsMouse ? Config.foreground : "transparent"
                            Layout.preferredHeight: Config.buttonSize
                            implicitWidth: dashboardLink.implicitWidth + 16
                            radius: 1

                            Text {
                                id: dashboardLink

                                text: "OPEN DASHBOARD ↗"
                                anchors.centerIn: parent
                                color: dashboardLinkMouse.containsMouse ? Config.backgroundColored : Config.foreground
                                font.family: Config.fontFamily
                                font.weight: Font.Medium
                                font.pixelSize: Config.fontSize - 2
                            }

                            MouseArea {
                                id: dashboardLinkMouse

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: Quickshell.execDetached(["xdg-open", "https://opencode.ai/workspace/" + root.workspaceId + "/go"])
                            }

                        }

                    }

                }

            }

        }

    }

    HyprlandFocusGrab {
        id: focusGrab

        active: root.popupVisible && popupLoader.item !== null
        windows: popupLoader.item ? [popupLoader.item] : []
        onCleared: {
            if (root.popupVisible)
                root.popupVisible = false;

        }
    }

    Process {
        id: usageProc

        command: ["bash", "-c", "set -a; source ~/.config.jmmm.sh/dotfiles/bash/.env 2>/dev/null; set +a; opencode-usage"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                console.log("[Opencode] usageProc stdout length:", text.length, "preview:", text.substring(0, 100));
                root.parseUsage(text);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: console.log("[Opencode] usageProc stderr:", text)
        }

        onExited: function(exitCode, exitStatus) {
            console.log("[Opencode] usageProc exited with code:", exitCode, "status:", exitStatus);
        }

    }

    Timer {
        id: spinnerTimer

        interval: 100
        running: sessionModel.count > 0
        repeat: true
        onTriggered: spinnerFrame = (spinnerFrame + 1) % spinnerChars.length
    }

    Timer {
        id: sessionTimer

        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            console.log("[Opencode] sessionTimer triggered, sessionProc.running =", sessionProc.running);
            if (!sessionProc.running) {
                console.log("[Opencode] sessionTimer — launching sessionProc");
                sessionProc.running = true;
            }
        }
    }

    Process {
        id: sessionProc

        command: [
            "bash", "-c",
            "db=\"${XDG_DATA_HOME:-$HOME/.local/share}/opencode/opencode.db\"; " +
            "sqlite3 \"$db\" \"SELECT s.title FROM session s " +
            "WHERE s.time_archived IS NULL " +
            "AND EXISTS (SELECT 1 FROM part p WHERE p.session_id = s.id) " +
            "AND COALESCE(json_extract((SELECT p.data FROM part p WHERE p.session_id = s.id ORDER BY p.time_created DESC, p.id DESC LIMIT 1), '$.type'), '') || '|' || " +
            "COALESCE(json_extract((SELECT p.data FROM part p WHERE p.session_id = s.id ORDER BY p.time_created DESC, p.id DESC LIMIT 1), '$.reason'), '') != 'step-finish|stop' " +
            "AND (SELECT p.time_created FROM part p WHERE p.session_id = s.id ORDER BY p.time_created DESC, p.id DESC LIMIT 1) > unixepoch('now', '-30 minutes') * 1000 " +
            "AND (s.agent IS NULL OR s.agent != 'Git Commit') " +
            "AND s.parent_id IS NULL " +
            "ORDER BY s.time_updated DESC\" 2>/dev/null"
        ]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                console.log("[Opencode] sessionProc stdout length:", text.length, "content:", JSON.stringify(text.substring(0, 200)));
                root.parseSessions(text);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: console.log("[Opencode] sessionProc stderr:", text)
        }

        onExited: function(exitCode, exitStatus) {
            console.log("[Opencode] sessionProc exited with code:", exitCode, "status:", exitStatus);
        }

    }

    Component.onCompleted: {
        console.log("[Opencode] Component.onCompleted — starting sessionProc");
        sessionProc.running = true;
        console.log("[Opencode] sessionProc.running =", sessionProc.running);
        console.log("[Opencode] workspaceId =", root.workspaceId);
        console.log("[Opencode] QUICKSHELL_OPENCODE_WORKSPACE_ID =", Quickshell.env("QUICKSHELL_OPENCODE_WORKSPACE_ID"));
        fetchUsage();
    }

}
