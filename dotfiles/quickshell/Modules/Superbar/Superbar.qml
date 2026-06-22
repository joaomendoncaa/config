import "Lib.js" as Lib
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "Widgets" as Widgets
import qs.Core

PanelWindow {
    id: root

    property var modes: ["apps", "emojis", "files", "clipboard", "calc", "chart", "theme"]
    property string mode: "apps"
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
    property string fdQueryMarker: ""
    property string initialMode: "apps"
    property var themeList: []

    signal dismissed()

    function dismiss() {
        dismissed();
    }

    function setSearchMode(m) {
        if (modes.indexOf(m) === -1) {
            console.error("Superbar: invalid mode '" + m + "'");
            return ;
        }
        if (m !== mode) {
            mode = m;
            filterText = "";
            selectedIndex = 0;
            cursorPosition = 0;
            clearFileSearch();
            rebuildDisplay();
            Qt.callLater(function() {
                keyCatcher.forceActiveFocus();
            });
        }
    }

    function clearFileSearch() {
        fileSearchTimer.stop();
        fileResults = [];
    }

    function rebuildDisplay() {
        var items = searchResults();
        displayModel.clear();
        for (var i = 0; i < items.length; i++) {
            var it = items[i];
            displayModel.append({
                "type": it.type,
                "label": it.label,
                "detail": it.detail || "",
                "emojiChar": it.emojiChar || "",
                "iconName": it.iconName || "",
                "fullText": it.fullText || "",
                "imagePath": it.imagePath || "",
                "filePath": it.filePath || "",
                "mime": it.mime || ""
            });
        }
        if (displayModel.count === 0)
            selectedIndex = 0;
        else if (selectedIndex >= displayModel.count)
            selectedIndex = displayModel.count - 1;
        positionToSelected();
    }

    function positionToSelected() {
        if (displayModel.count > 0)
            resultList.positionViewAtIndex(selectedIndex, ListView.Contain);

    }

    function searchResults() {
        switch (mode) {
        case "apps":
            return searchApps();
        case "emojis":
            return searchEmojis();
        case "files":
            return searchFiles();
        case "clipboard":
            return searchClipboard();
        case "calc":
            return searchCalc();
        case "theme":
            return searchThemes();
        }
        return [];
    }

    function searchApps() {
        var entries = DesktopEntries.applications.values || [];
        var rows = Lib.sortedEntries(entries, filterText);
        var max = Math.min(rows.length, 100);
        var out = [];
        for (var i = 0; i < max; i++) {
            out.push({
                "type": "app",
                "label": rows[i].name,
                "iconName": String(rows[i].entry.icon || ""),
                "entry": rows[i].entry
            });
        }
        return out;
    }

    function searchEmojis() {
        var results = Lib.filterEmojis(emojiData, filterText, 100);
        var out = [];
        for (var i = 0; i < results.length; i++) {
            out.push({
                "type": "emoji",
                "label": (results[i].k || "").split(" ")[0] || "emoji",
                "emojiChar": results[i].e
            });
        }
        return out;
    }

    function searchFiles() {
        if (!fileResults || fileResults.length === 0)
            return [];

        return fileResults.map(function(p) {
            return {
                "type": "file",
                "label": p
            };
        });
    }

    function searchClipboard() {
        if (clipboardData.length === 0 && filterText.length === 0)
            return [];

        var results = Lib.filterClipboardHistory(clipboardData, filterText, 50);
        return results.map(function(r) {
            var entry = r.entry;
            if (typeof entry === "string")
                return {
                "type": "clipboard",
                "label": entry.replace(/\n/g, " ").substring(0, 120),
                "detail": String(entry.length) + " chars",
                "fullText": entry,
                "imagePath": "",
                "mime": ""
            };

            if (entry.type === "image")
                return {
                "type": "clipboard",
                "label": entry.capturedAt || "Image",
                "detail": entry.mime || "",
                "fullText": "",
                "imagePath": String(entry.path || ""),
                "filePath": String(entry.path || ""),
                "mime": String(entry.mime || "")
            };

            if (entry.type === "video")
                return {
                "type": "clipboard",
                "label": entry.capturedAt || "Video",
                "detail": entry.mime || "video",
                "fullText": "",
                "imagePath": String(entry.thumbnail || entry.path || ""),
                "filePath": String(entry.path || ""),
                "mime": "text/uri-list"
            };

            return {
                "type": "clipboard",
                "label": entry.text.replace(/\n/g, " ").substring(0, 120),
                "detail": String(entry.text.length) + " chars",
                "fullText": entry.text,
                "imagePath": "",
                "mime": ""
            };
        });
    }

    function searchCalc() {
        if (!filterText)
            return [];

        if (!calcResult || calcQueryMarker !== filterText)
            return [];

        return [{
            "type": "calc",
            "label": calcResult,
            "fullText": calcResult
        }];
    }

    function searchThemes() {
        var results = Lib.filterThemes(themeList, filterText, 100);
        return results.map(function(name) {
            return {
                "type": "theme",
                "label": name
            };
        });
    }

    function buildClipboardCopyCommand(item) {
        if (item.filePath && item.mime === "text/uri-list")
            return "printf 'file://%s\\n' " + Lib.shellQuote(item.filePath) + " | wl-copy --type text/uri-list";
        if (item.filePath)
            return "wl-copy --type " + Lib.shellQuote(item.mime) + " < " + Lib.shellQuote(item.filePath);
        return "wl-copy " + Lib.shellQuote(item.fullText);
    }

    function activateSelected() {
        if (selectedIndex < 0 || selectedIndex >= displayModel.count)
            return ;

        var item = displayModel.get(selectedIndex);
        if (item.type === "app") {
            var entries = DesktopEntries.applications.values || [];
            for (var i = 0; i < entries.length; i++) {
                if (Lib.entryName(entries[i]) === item.label) {
                    entries[i].execute();
                    dismiss();
                    return ;
                }
            }
        }
        if (item.type === "emoji") {
            var pasteCmd = "; sleep 0.15; wtype -M ctrl -k v -m ctrl 2>/dev/null || true";
            Quickshell.execDetached(["bash", "-c", "wl-copy " + Lib.shellQuote(item.emojiChar) + pasteCmd]);
            dismiss();
        }
        if (item.type === "file") {
            Quickshell.execDetached(["bash", "-c", "xdg-open " + Lib.shellQuote(item.label)]);
            dismiss();
        }
        if (item.type === "clipboard") {
            var pasteCmd = "; sleep 0.15; wtype -M ctrl -k v -m ctrl 2>/dev/null || true";
            Quickshell.execDetached(["bash", "-c", buildClipboardCopyCommand(item) + pasteCmd]);
            dismiss();
        }
        if (item.type === "calc") {
            Quickshell.execDetached(["bash", "-c", "wl-copy " + Lib.shellQuote(item.fullText)]);
            dismiss();
        }
        if (item.type === "theme") {
            Quickshell.execDetached(["bash", "-c", "theme apply " + Lib.shellQuote(item.label)]);
            dismiss();
        }
    }

    function copySelectedContent() {
        if (selectedIndex < 0 || selectedIndex >= displayModel.count)
            return ;

        var item = displayModel.get(selectedIndex);
        switch (item.type) {
        case "emoji":
            Quickshell.execDetached(["bash", "-c", "wl-copy " + Lib.shellQuote(item.emojiChar)]);
            break;
        case "file":
            Quickshell.execDetached(["bash", "-c", "wl-copy " + Lib.shellQuote(item.label)]);
            break;
        case "clipboard":
            Quickshell.execDetached(["bash", "-c", buildClipboardCopyCommand(item)]);
            break;
        case "calc":
            Quickshell.execDetached(["bash", "-c", "wl-copy " + Lib.shellQuote(item.fullText)]);
            break;
        }
        dismiss();
    }

    function resolveIcon(name) {
        if (!name)
            return Quickshell.iconPath("application-x-executable", true);

        if (name.indexOf("/") >= 0) {
            if (name.indexOf("file://") === 0 || name.indexOf("image://") === 0)
                return name;

            if (name.charAt(0) === "/")
                return "file://" + name;

        }
        return Quickshell.iconPath(name, true);
    }

    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "superbar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    Component.onCompleted: {
        if (initialMode !== "apps")
            setSearchMode(initialMode);
        rebuildDisplay();
        Qt.callLater(function() {
            keyCatcher.forceActiveFocus();
        });
    }
    onModeChanged: {
        if (mode === "files" && filterText)
            fileSearchTimer.restart();
        else if (mode !== "files")
            clearFileSearch();
        if (mode === "clipboard")
            rebuildDisplay();

        if (mode === "chart" && !chartInitialized)
            chartInitialized = true;

        if (mode === "theme" && themeList.length === 0)
            themeListProc.running = true;
    }
    onFilterTextChanged: {
        if (mode === "files")
            fileSearchTimer.restart();

        if (mode === "calc") {
            root.calcResult = "";
            calcTimer.restart();
        }
        if (mode === "chart")
            chartTimer.restart();

        if (mode !== "files")
            rebuildDisplay();

    }
    onCalcResultChanged: {
        if (mode === "calc")
            rebuildDisplay();

    }
    onFileResultsChanged: {
        if (mode === "files")
            rebuildDisplay();

    }

    ListModel {
        id: displayModel
    }

    anchors {
        left: true
        right: true
        top: true
        bottom: true
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

                Widgets.SearchInput {
                    id: searchInput

                    width: parent.width
                    height: Config.fontSize + 16
                    mode: root.mode
                    filterText: root.filterText
                    cursorPosition: root.cursorPosition
                }

                Item {
                    width: parent.width
                    height: parent.height - searchInput.height - parent.spacing

                    Row {
                        visible: root.mode !== "chart"
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

                                delegate: Widgets.ResultDelegate {
                                    selectedIndex: root.selectedIndex
                                    iconResolver: function(name) {
                                        return root.resolveIcon(name);
                                    }
                                    onItemHovered: root.selectedIndex = index
                                    onItemClicked: {
                                        root.selectedIndex = index;
                                        root.activateSelected();
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

                        Widgets.Preview {
                            id: previewPanel

                            displayModel: displayModel
                            selectedIndex: root.selectedIndex
                            active: root.mode === "clipboard"
                        }

                    }

                    Loader {
                        id: chartLoader

                        active: root.chartInitialized
                        visible: root.mode === "chart"
                        anchors.fill: parent
                        source: "Widgets/Chart.qml"
                    }

                }

            }

        }

        Widgets.KeyIntercept {
            id: keyCatcher

            anchors.fill: parent
            root: root
            displayModel: displayModel
        }

    }

    FileView {
        path: Quickshell.env("HOME") + "/.config.jmmm.sh/dotfiles/quickshell/Data/emojis.json"
        onLoaded: root.emojiData = Lib.parseEmojiJson(text())
        onLoadFailed: root.emojiData = []
    }

    FileView {
        id: clipFile

        path: Quickshell.env("HOME") + "/.local/state/clipboard-history.json"
        watchChanges: true
        atomicWrites: true
        printErrors: false
        onLoaded: {
            root.clipboardData = Lib.parseClipboardHistory(text());
            if (root.mode === "clipboard")
                root.rebuildDisplay();

        }
        onFileChanged: reload()
    }

    Timer {
        id: fileSearchTimer

        interval: 200
        onTriggered: {
            if (root.mode !== "files" || !root.filterText) {
                root.fileResults = [];
                return ;
            }
            root.fdQueryMarker = root.filterText;
            fdProc.command = ["fd", "-t", "f", "--max-results", "50", root.filterText, Quickshell.env("HOME")];
            fdProc.running = true;
        }
    }

    Process {
        id: fdProc

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (root.fdQueryMarker !== root.filterText)
                    return ;

                var lines = String(text || "").trim();
                if (!lines) {
                    root.fileResults = [];
                    return ;
                }
                var parts = lines.split("\n");
                var paths = [];
                for (var i = 0; i < parts.length; i++) {
                    var p = String(parts[i] || "").trim();
                    if (p)
                        paths.push(p);

                }
                root.fileResults = paths;
            }
        }

    }

    Timer {
        id: calcTimer

        interval: 200
        onTriggered: {
            if (root.mode !== "calc" || !root.filterText)
                return ;

            root.calcQueryMarker = root.filterText;
            root.calcResult = "";
            calcProc.command = ["qalc", "-t", root.filterText];
            calcProc.running = true;
        }
    }

    Process {
        id: calcProc

        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (root.calcQueryMarker !== root.filterText)
                    return ;

                root.calcResult = String(text || "").trim();
            }
        }

    }

    Process {
        id: themeListProc

        command: [Quickshell.env("HOME") + "/.config.jmmm.sh/bin/theme", "list"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var lines = String(text || "").trim().split("\n").filter(function(l) {
                    return l.length > 0;
                });
                root.themeList = lines;
                if (root.mode === "theme")
                    root.rebuildDisplay();
            }
        }
    }

    Timer {
        id: chartTimer

        interval: 400
        onTriggered: {
            if (root.mode !== "chart" || !root.filterText)
                return ;

            root.chartQueryMarker = root.filterText;
            var chart = chartLoader.item;
            if (chart)
                chart.symbol = root.filterText;

        }
    }

    Connections {
        function onValuesChanged() {
            if (root.mode === "apps")
                root.rebuildDisplay();

        }

        target: DesktopEntries.applications
    }

}
