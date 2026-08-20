import QtQuick
import QtQuick.Layouts
import qs.Core

Rectangle {
    id: root

    required property var service

    readonly property int panelWidth: Math.round(Config.buttonSize * 16)
    readonly property int buttonHeight: 34
    readonly property int rowHeight: Math.round(Config.buttonSize * 1.7)
    readonly property int maximumListHeight: Math.round(Config.buttonSize * 14)
    readonly property int footerHeight: Math.round(Config.buttonSize * 2)
    readonly property int listHeight: Math.min(
        root.maximumListHeight,
        Math.max(root.rowHeight, root.service.countries.length * root.rowHeight) + (root.showListFooter ? root.footerHeight : 0))
    // shellPadding (list top margin + button bottom margin) and
    // gapInner (gap between the list and the button) are part of the panel's
    // vertical budget.
    readonly property int desiredHeight: Config.shellPadding + root.listHeight + Config.gapInner + root.buttonHeight + Config.shellPadding

    readonly property bool connecting: root.service.busy && root.service._pendingGoal === "connected"
    readonly property bool disconnecting: root.service.busy && root.service._pendingGoal === "disconnected"
    readonly property bool connected: root.service.connected

    // Country the user last asked to connect to; highlighted + shows a spinner
    // while a connect is in flight. Cleared once the busy state settles.
    property string pendingCountry: ""

    // Countries with the currently-connected country pinned to the top.
    // Matching uses the same code-substring rule as the row highlight so the
    // "first item" always agrees with the "highlighted item".
    readonly property var orderedCountries: {
        if (!root.connected || !root.service.serverName)
            return root.service.countries
        var sn = root.service.serverName.toUpperCase()
        var idx = -1
        for (var i = 0; i < root.service.countries.length; i++) {
            var code = (root.service.countries[i].code || "").toUpperCase()
            if (code && sn.indexOf(code) >= 0) {
                idx = i
                break
            }
        }
        if (idx <= 0)
            return root.service.countries
        var out = root.service.countries.slice()
        out.unshift(out.splice(idx, 1)[0])
        return out
    }

    // Footer message shows only when there is genuinely nothing to list.
    // The height and the text visibility must stay in sync, otherwise the
    // message renders on top of the last result row of a populated list.
    readonly property bool showListFooter: root.service.countries.length === 0

    readonly property string listFooterText: root.service.serverListLoaded
        ? "No free servers found"
        : "Loading servers\u2026"

    signal dismissed()

    function toggleConnection() {
        if (root.service.busy)
            return
        if (root.connected)
            root.service.startDisconnect()
        else
            root.service.startConnect()
    }

    function selectCountry(code) {
        root.pendingCountry = code
        root.service.selectCountry(code)
    }

    color: Config.backgroundColored
    radius: Config.borderRadius
    clip: true
    focus: true
    Keys.onEscapePressed: root.dismissed()

    Component.onCompleted: root.service.refreshServers()

    // Clear the pending-server marker once the connect/disconnect settles so
    // the highlight falls back to whichever server is actually connected.
    Connections {
        target: root.service

        function onBusyChanged() {
            if (!root.service.busy)
                root.pendingCountry = ""
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // --- Server list (scrollable) ----------------------------------------
        ListView {
            id: serverList

            Layout.fillWidth: true
            Layout.preferredHeight: root.listHeight
            Layout.topMargin: Config.shellPadding
            Layout.leftMargin: Config.shellPadding
            Layout.rightMargin: Config.shellPadding
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: 2
            model: root.orderedCountries

            delegate: VpnCountryRow {
                width: serverList.width
                current: root.service.busy
                    ? root.pendingCountry === (modelData && modelData.code)
                    : root.connected && root.service.serverName &&
                        root.service.serverName.toUpperCase().indexOf((modelData && modelData.code) || "") >= 0
                connecting: root.service.busy && root.pendingCountry === (modelData && modelData.code)
                disabled: root.service.busy && root.pendingCountry !== (modelData && modelData.code)
                onClicked: root.selectCountry(modelData ? modelData.code : "")
            }

            footer: Item {
                width: serverList.width
                height: root.showListFooter ? root.footerHeight : 0

                Text {
                    anchors.centerIn: parent
                    visible: root.showListFooter
                    text: root.listFooterText
                    color: Config.foregroundSecondary
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                }
            }
        }

        // --- Connect / disconnect button (bottom) ------------------------------
        Item {
            Layout.fillWidth: true
            Layout.minimumHeight: root.buttonHeight
            Layout.preferredHeight: root.buttonHeight
            Layout.topMargin: Config.gapInner
            Layout.bottomMargin: Config.shellPadding
            Layout.leftMargin: Config.shellPadding
            Layout.rightMargin: Config.shellPadding

            Rectangle {
                id: connectButton

                anchors.fill: parent
                radius: Config.borderRadius
                color: connectMouse.containsMouse && !root.service.busy
                    ? Config.backgroundHovered
                    : root.connected ? Config.accent : Config.foreground

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (root.service.busy)
                            return root.connecting ? "Connecting\u2026" : root.disconnecting ? "Disconnecting\u2026" : "Working\u2026"
                        if (root.connected)
                            return "Disconnect"
                        return "Connect"
                    }
                    color: connectMouse.containsMouse
                        ? Config.foreground
                        : Config.foregroundSelected
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                    font.bold: true
                }

                MouseArea {
                    id: connectMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !root.service.busy
                    onClicked: root.toggleConnection()
                }
            }
        }
    }
}