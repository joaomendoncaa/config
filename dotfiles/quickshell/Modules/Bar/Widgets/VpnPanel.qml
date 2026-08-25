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

    // Total vertical budget: top padding + header + gap + map + bottom padding.
    readonly property int desiredHeight: Config.shellPadding + root.headerHeight + Config.gapInner + root.mapHeight + Config.shellPadding

    readonly property bool connecting: root.service.busy && root.service._pendingGoal === "connected"
    readonly property bool disconnecting: root.service.busy && root.service._pendingGoal === "disconnected"
    readonly property bool connected: root.service.connected

    // Country the user last asked to connect to; highlighted + spinner state
    // while a connect is in flight. Cleared once the busy state settles.
    property string pendingCountry: ""

    // Header label: hovered available country wins, then the active one.
    readonly property string headerCountryName: map.hoveringAvailable
        ? map.countryName(map.hoveredCode)
        : root.connected && root.service.countryCode ? map.countryName(root.service.countryCode.toLowerCase()) : ""

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
                spacing: Config.gapInner

                Text {
                    visible: root.headerCountryName.length > 0
                    text: root.flagEmoji(map.hoveringAvailable ? map.hoveredCode : root.service.countryCode)
                    font.pixelSize: Config.fontSize
                }

                Text {
                    text: root.headerCountryName
                    color: map.hoveringAvailable ? Config.foregroundSecondary : Config.foreground
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                    font.bold: true
                    visible: root.headerCountryName.length > 0
                }

                // Public IP: hidden while loading, struck through on failure.
                Text {
                    visible: root.connected && !map.hoveringAvailable && !root.service.ipFetching && !root.service.ipFailed && root.service.publicIp.length > 0
                    text: root.service.publicIp
                    color: Config.foregroundSecondary
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                }

                Text {
                    visible: root.connected && !map.hoveringAvailable && !root.service.ipFetching && root.service.ipFailed
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
                visible: map.hoveredCode.length === 0

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: buttonLabel.implicitWidth + Config.gapOuter
                height: parent.height
                radius: Config.borderRadius
                color: connectMouse.containsMouse && !root.service.busy ? Config.backgroundHovered : root.connected ? Config.accent : Config.foreground

                Text {
                    id: buttonLabel

                    anchors.centerIn: parent
                    text: {
                        if (root.service.busy)
                            return root.connecting ? "Connecting\u2026" : root.disconnecting ? "Disconnecting\u2026" : "Working\u2026"
                        if (root.connected)
                            return "Disconnect"
                        return "Connect"
                    }
                    color: connectMouse.containsMouse ? Config.foreground : Config.foregroundSelected
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

        // --- World map ---------------------------------------------------------
        VpnWorldMap {
            id: map

            Layout.fillWidth: true
            Layout.preferredHeight: root.mapHeight
            Layout.topMargin: Config.gapInner
            Layout.leftMargin: root.mapSideMargin
            Layout.rightMargin: root.mapSideMargin
            Layout.bottomMargin: Config.shellPadding
            service: root.service
            pendingCode: root.pendingCountry
            onCountryClicked: code => root.selectCountry(code)
        }
    }
}
