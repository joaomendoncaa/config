import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import qs.Core

Rectangle {
    id: root

    required property var service

    readonly property int panelWidth: Math.round(Config.buttonSize * 18)
    readonly property int headerHeight: Math.round(Config.buttonSize * 1.3)
    readonly property int mapSideMargin: Config.shellPadding
    // Native map viewBox is 784.077 x 458.627; keep the aspect ratio.
    readonly property real mapAspect: 458.627 / 784.077
    readonly property int mapWidth: root.panelWidth - 2 * root.mapSideMargin
    readonly property int mapHeight: Math.round(root.mapWidth * root.mapAspect)
    readonly property int rowHeight: Math.round(Config.buttonSize * 1.08)
    readonly property int itemGap: Config.gapInner + 4
    readonly property int tableMaxRows: 10

    // Countries ordered by measured latency; unmeasured rows go last so the
    // table stays stable while the probe is still running.
    readonly property var countryRows: {
        var list = (root.service.countries || []).slice()
        var measured = root.service.latencyByCountry || ({})
        list.sort(function(a, b) {
            var ea = measured[String(a.code || "").toUpperCase()]
            var eb = measured[String(b.code || "").toUpperCase()]
            var la = ea && typeof ea.latency === "number" ? ea.latency : Infinity
            var lb = eb && typeof eb.latency === "number" ? eb.latency : Infinity
            if (la !== lb)
                return la < lb ? -1 : 1
            return String(a.name || "").localeCompare(String(b.name || ""))
        })
        return list
    }
    readonly property int tableHeight: Math.min(root.countryRows.length, root.tableMaxRows) * root.rowHeight

    // Total vertical budget: padding + header + map + table + list bottom gap.
    readonly property int desiredHeight: Config.shellPadding + root.headerHeight + Config.gapInner + root.mapHeight
        + (root.tableHeight > 0 ? Config.gapInner + root.tableHeight + Config.shellPadding : 0) + Config.shellPadding

    readonly property bool connecting: root.service.busy && root.service._pendingGoal === "connected"
    readonly property bool disconnecting: root.service.busy && root.service._pendingGoal === "disconnected"
    readonly property bool connected: root.service.connected

    // Country the user last asked to connect to; highlighted + spinner state
    // while a connect is in flight. Cleared once the busy state settles.
    property string pendingCountry: ""

    // Header label: hovered available country wins, then the active VPN
    // country, then the user's physical country.
    readonly property string headerCountryName: {
        if (!root.service)
            return "VPN"
        if (root.hoveredCountryCode.length === 2)
            return map.countryName(root.hoveredCountryCode)
        if (root.connected && root.service.countryCode)
            return map.countryName(root.service.countryCode.toLowerCase())
        if (root.service.homeCountryName.length > 0)
            return root.service.homeCountryName
        return "VPN"
    }

    // Actual map hover; drives the inverted table row.
    readonly property string hoveredMapCode: {
        if (!map || !map.hoveringAvailable)
            return ""
        return map.hoveredCode
    }

    // Table row hover; drives the map highlight and the header.
    property string tableHoveredCode: ""

    readonly property string hoveredCountryCode: root.tableHoveredCode.length === 2
        ? root.tableHoveredCode
        : root.hoveredMapCode

    readonly property real hoveredLatency: {
        if (root.hoveredCountryCode.length !== 2)
            return -1
        var entry = root.service.latencyByCountry[root.hoveredCountryCode.toUpperCase()]
        return entry && typeof entry.latency === "number" ? entry.latency : -1
    }

    readonly property int hoveredLoad: {
        if (root.hoveredCountryCode.length !== 2)
            return -1
        var entry = root.service.latencyByCountry[root.hoveredCountryCode.toUpperCase()]
        return entry && typeof entry.load === "number" && entry.load >= 0 ? entry.load : -1
    }

    // "US" -> flag emoji via regional indicator symbols.
    function flagEmoji(code) {
        if (!code || code.length !== 2)
            return ""
        var out = ""
        for (var i = 0; i < 2; i++)
            out += String.fromCodePoint(0x1F1E6 + code.toUpperCase().charCodeAt(i) - 65)
        return out
    }

    signal dismissed()

    function toggleConnection() {
        if (root.service.busy)
            return
        if (root.connected) {
            root.service.startDisconnect()
        } else {
            var best = root.service.bestCountry()
            if (best)
                root.selectCountry(best.code)
            else
                root.service.startConnect()
        }
    }

    function selectCountry(code) {
        root.pendingCountry = code
        root.tableHoveredCode = ""
        root.service.selectCountry(code)
    }

    function resetHover() {
        root.tableHoveredCode = ""
        if (map)
            map.hoveredCode = ""
    }

    color: Config.backgroundColored
    radius: Config.borderRadius
    clip: true
    focus: true
    Keys.onEscapePressed: root.dismissed()

    // Clear the pending-server marker once the connect/disconnect settles so
    // the highlight falls back to whichever server is actually connected.
    Connections {
        target: root.service

        function onBusyChanged() {
            if (root.service.busy)
                root.tableHoveredCode = ""
            else
                root.pendingCountry = ""
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // --- Header: flag + country + IP, disconnect button -------------------
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.headerHeight
            Layout.topMargin: Config.shellPadding
            Layout.leftMargin: root.mapSideMargin
            Layout.rightMargin: root.mapSideMargin

            RowLayout {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.itemGap

                Text {
                    visible: root.headerCountryName.length > 0
                    text: root.flagEmoji(root.hoveredCountryCode.length === 2 ? root.hoveredCountryCode : (root.connected ? root.service.countryCode : root.service.homeCountryCode))
                    font.pixelSize: Config.fontSize
                }

                Text {
                    text: root.headerCountryName
                    color: root.hoveredCountryCode.length === 2 ? Config.foregroundSecondary : Config.foreground
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                    font.bold: true
                    visible: root.headerCountryName.length > 0
                }

                // Hovered country's server occupancy, between name and RTT.
                Rectangle {
                    visible: root.hoveredLoad >= 0
                    Layout.preferredWidth: Math.round(Config.buttonSize * 1.6)
                    Layout.preferredHeight: Math.max(4, Math.round(Config.buttonSize * 0.22))
                    Layout.alignment: Qt.AlignVCenter
                    radius: height / 2
                    color: Config.backgroundColoredTertiary

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, root.hoveredLoad / 100))
                        height: parent.height
                        radius: parent.radius
                        color: Config.foreground
                    }
                }

                // Hovered country's measured RTT, next to its name.
                Text {
                    visible: root.hoveredLatency >= 0
                    text: Math.round(root.hoveredLatency) + " ms"
                    color: Config.foregroundSecondary
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                }

                // Public IP: hidden while loading, struck through on failure.
                Text {
                    visible: root.connected && !(map && map.hoveringAvailable) && !root.service.ipFetching && !root.service.ipFailed && root.service.publicIp.length > 0
                    text: root.service.publicIp
                    color: Config.foregroundSecondary
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                }

                Text {
                    visible: root.connected && !(map && map.hoveringAvailable) && !root.service.ipFetching && root.service.ipFailed
                    text: "0.0.0.0"
                    color: Config.foregroundSecondary
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                    font.strikeout: true
                }
            }

            Rectangle {
                id: connectButton

                // Get out of the way while a country is hovered so the full
                // name has room in the header.
                visible: !map || map.hoveredCode.length === 0

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: buttonContent.implicitWidth + Config.gapOuter
                height: parent.height
                radius: Config.borderRadius
                color: {
                    if (root.connected)
                        return connectMouse.containsMouse ? Config.backgroundHovered : Config.accent
                    if (root.service.busy)
                        return Config.foreground
                    return connectMouse.containsMouse ? Config.foreground : Config.backgroundHovered
                }

                RowLayout {
                    id: buttonContent

                    anchors.centerIn: parent
                    spacing: Config.gapInner

                    Text {
                        id: buttonLabel

                        text: {
                            if (root.service.busy)
                                return root.connecting ? "Connecting\u2026" : root.disconnecting ? "Disconnecting\u2026" : "Working\u2026"
                            if (root.connected)
                                return "Disconnect"
                            return "Connect"
                        }
                        color: {
                            if (root.connected)
                                return connectMouse.containsMouse ? Config.foreground : Config.foregroundSelected
                            if (root.service.busy)
                                return Config.foregroundSelected
                            return connectMouse.containsMouse ? Config.foregroundSelected : Config.foreground
                        }
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize
                        font.bold: true
                    }
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

        // --- World map ---------------------------------------------------------
        VpnWorldMap {
            id: map

            Layout.fillWidth: true
            Layout.preferredHeight: root.mapHeight
            Layout.topMargin: Config.gapInner
            Layout.leftMargin: root.mapSideMargin
            Layout.rightMargin: root.mapSideMargin
            service: root.service
            pendingCode: root.pendingCountry
            externalHoveredCode: root.tableHoveredCode
            onCountryClicked: code => root.selectCountry(code)
        }

        // --- Countries, ordered by measured latency -----------------------------
        ListView {
            id: countryTable

            Layout.fillWidth: true
            Layout.preferredHeight: root.tableHeight
            Layout.topMargin: root.tableHeight > 0 ? Config.gapInner : 0
            Layout.bottomMargin: root.tableHeight > 0 ? Config.shellPadding : 0
            Layout.leftMargin: root.mapSideMargin
            Layout.rightMargin: root.mapSideMargin
            model: root.countryRows
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: 0

            delegate: Rectangle {
                id: countryRow

                required property var modelData

                readonly property string code: String(modelData.code || "").toLowerCase()
                readonly property var measured: root.service.latencyByCountry[String(modelData.code || "").toUpperCase()] || null
                readonly property real latency: measured && typeof measured.latency === "number" ? measured.latency : -1
                readonly property int load: measured && measured.load >= 0 ? measured.load : (modelData.load >= 0 ? modelData.load : -1)
                readonly property bool isConnected: root.connected && root.service.countryCode.toLowerCase() === code
                readonly property bool isPending: root.service.busy && root.pendingCountry.toLowerCase() === code
                readonly property bool isMapHovered: root.hoveredMapCode.length === 2 && root.hoveredMapCode === code

                width: ListView.view ? ListView.view.width : root.width
                height: root.rowHeight
                radius: Config.buttonBorderRadius
                color: countryRow.isMapHovered ? Config.foreground : rowMouse.containsMouse ? Config.backgroundHovered : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Config.gapInner
                    anchors.rightMargin: Config.gapInner
                    spacing: root.itemGap

                    Text {
                        text: root.flagEmoji(countryRow.code)
                        font.pixelSize: Config.fontSize
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.name || countryRow.code.toUpperCase()
                        color: countryRow.isMapHovered ? Config.foregroundSelected : (countryRow.isConnected || countryRow.isPending ? Config.accent : Config.foreground)
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize
                        font.bold: countryRow.isConnected || countryRow.isPending
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        visible: countryRow.load >= 0
                        Layout.preferredWidth: Math.round(Config.buttonSize * 1.6)
                        Layout.preferredHeight: Math.max(4, Math.round(Config.buttonSize * 0.22))
                        Layout.alignment: Qt.AlignVCenter
                        radius: height / 2
                        color: countryRow.isMapHovered
                            ? Config.hexWithAlpha(Config.foregroundSelected, "33")
                            : Config.backgroundColoredTertiary

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, countryRow.load / 100))
                            height: parent.height
                            radius: parent.radius
                            color: countryRow.isMapHovered ? Config.foregroundSelected : Config.foreground
                        }
                    }

                    Text {
                        text: {
                            if (!root.service.latencyLoaded)
                                return "\u2026"
                            return countryRow.latency >= 0 ? Math.round(countryRow.latency) + " ms" : "\u2014"
                        }
                        color: countryRow.isMapHovered ? Config.foregroundSelected : (countryRow.isConnected ? Config.accent : Config.foreground)
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: Math.round(Config.buttonSize * 2.2)
                    }
                }

                MouseArea {
                    id: rowMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !root.service.busy && countryRow.code.length === 2
                    onEntered: root.tableHoveredCode = countryRow.code
                    onExited: {
                        if (root.tableHoveredCode === countryRow.code)
                            root.tableHoveredCode = ""
                    }
                    onClicked: root.selectCountry(countryRow.code)
                }
            }
        }
    }
}
