import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick.Controls
import qs.Core
import "WeatherModel.js" as Model

// Weather bar widget — full parity port of omarchy-4 weather panel.
//
//  Left click  : toggle forecast popup (hero + 3-day row, editable location)
//  Middle click: refresh (wttr.in + open-meteo)
//  Right click : show `qs-weather-status` via notificationService
//
// Storage: ~/.local/state/quickshell/weather.json  {name, latitude, longitude}
//  Missing file = IP auto-detect via wttr.in.  Not inside dotfiles/ so
//  `git push` never leaks your location.  The file is owned by
//  bin/qs-weather-location (same shape as omarchy's helper).
//
// Placed between Solana & Monitor in Bar.qml rightLayout.
Item {
    id: root

    property QtObject barWindow: null
    property var notificationService: null
    property bool popupOpen: false
    signal opening()

    // Refs to lazy-loaded inner items — ids inside LazyLoader are NOT visible
    // at file scope (hence the ReferenceErrors in the log). We expose them
    // via properties set from inside the popup's Component.onCompleted.
    property var popupRef: null
    property var weatherPanelRef: null
    property var locationFieldRef: null

    // expose to popup content via alias if needed
    readonly property string effectiveLabel: label || "—"

    Layout.preferredWidth: Config.buttonSize
    Layout.preferredHeight: Config.buttonSize
    implicitWidth: Config.buttonSize
    implicitHeight: Config.buttonSize

    function togglePanel() {
        if (popupOpen) {
            popupOpen = false
            return
        }
        popupOpen = true
        opening()
        // mirrored from omarchy Panel.qml: reload location file + trigger fetch
        locationFile.reload()
        refresh()
    }

    function refresh() {
        forecastRetries = 0
        dailyForecastRetries = 0
        if (!forecastProc.running) forecastProc.running = true
        if (locationQuery === "" && !locationProc.running) locationProc.running = true
        refreshDailyForecast(null)
    }

    function refreshDailyForecast(sourceReport) {
        if (dailyForecastProc.running) return
        var lat = parseFloat(String(configuredLocationState.latitude))
        var lon = parseFloat(String(configuredLocationState.longitude))
        if (isNaN(lat) || isNaN(lon)) {
            var area = sourceReport && sourceReport.nearest_area && sourceReport.nearest_area[0] ? sourceReport.nearest_area[0] : areaInfo
            if (!area) return
            lat = parseFloat(String(area.latitude || ""))
            lon = parseFloat(String(area.longitude || ""))
        }
        if (isNaN(lat) || isNaN(lon)) return
        var url = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + encodeURIComponent(String(lat))
            + "&longitude=" + encodeURIComponent(String(lon))
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day"
            + "&forecast_days=4"
            + "&timezone=auto"
        dailyForecastProc.command = ["curl", "-fsS", "--max-time", "5", url]
        dailyForecastProc.running = true
    }

    // ---- location editing (mirrors Panel.qml) ----
    function startEditingLocation() {
        editingLocation = true
        savingLocation = false
        savingLocationQueryStarted = false
        locationSuggestions = []
        suggestionIndex = 0
        Qt.callLater(function() {
            Qt.callLater(function() {
                var field = locationFieldRef
                if (!field) {
                    console.log("[Weather] startEditing: locationFieldRef still null")
                    return
                }
                field.text = configuredLocation
                field.selectAll()
                var popupItem = popupRef
                if (popupItem && popupItem.focusInput) popupItem.focusInput()
                else field.forceActiveFocus(Qt.OtherFocusReason)
            })
        })
    }
    function cancelEditingLocation() {
        editingLocation = false
        savingLocation = false
        savingLocationQueryStarted = false
        locationSuggestions = []
        geocodeDebounce.stop()
        Qt.callLater(function() {
            var popupItem = popupRef
            if (popupItem && popupItem.focusInput) popupItem.focusInput()
            else if (weatherPanelRef && weatherPanelRef.focusInput) weatherPanelRef.focusInput()
            else console.log("[Weather] cancelEditing: no panel ref to focus")
        })
    }
    function commitLocation() {
        var fieldText = locationFieldRef ? locationFieldRef.text : ""
        var location = Model.locationCommit(fieldText, locationSuggestions, suggestionIndex)
        if (location.name === "") {
            clearLocation()
            return
        }
        savingLocation = true
        savingLocationQueryStarted = false
        configuredLocationState = {
            name: location.name,
            latitude: location.latitude,
            longitude: location.longitude
        }
        persistLocation(location.name, location.latitude, location.longitude)
    }
    function clearLocation() {
        persistLocation("", null, null)
        wttrLocation = ""
        cancelEditingLocation()
    }
    function pickSuggestion(suggestion) {
        if (!suggestion) return
        savingLocation = true
        savingLocationQueryStarted = false
        configuredLocationState = {
            name: suggestion.name,
            latitude: suggestion.latitude,
            longitude: suggestion.longitude
        }
        persistLocation(suggestion.name, suggestion.latitude, suggestion.longitude)
    }
    function finishSavingLocation() {
        if (savingLocation && savingLocationQueryStarted) cancelEditingLocation()
    }
    function persistLocation(name, latitude, longitude) {
        var helper = Quickshell.env("HOME") + "/.config.jmmm.sh/bin/qs-weather-location"
        if (name && latitude !== null && longitude !== null)
            locationSaveProc.command = [helper, "--set", name, latitude + "," + longitude]
        else if (name)
            locationSaveProc.command = [helper, "--set", name]
        else
            locationSaveProc.command = [helper, "--clear"]
        locationSaveProc.running = true
    }
    function requestGeocode() {
        var field = locationFieldRef
        var query = field ? field.text.trim() : ""
        if (query.length < 2) {
            locationSuggestions = []
            return
        }
        geocodePendingQuery = query
        if (!geocodeProc.running) startGeocode()
    }
    function startGeocode() {
        geocodeActiveQuery = geocodePendingQuery
        var url = "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(geocodeActiveQuery) + "&count=5&language=en&format=json"
        geocodeProc.command = ["curl", "-fsS", "--max-time", "5", url]
        geocodeProc.running = true
    }

    function buildForecastDays() {
        return Model.buildForecastDays(report, dailyForecastReport, Qt.formatDate(new Date(), "yyyy-MM-dd"))
    }
    function openMeteoForecastDays() {
        return Model.openMeteoForecastDays(dailyForecastReport, Qt.formatDate(new Date(), "yyyy-MM-dd"))
    }
    function wttrNextForecastDays() {
        return Model.wttrNextForecastDays(report, Qt.formatDate(new Date(), "yyyy-MM-dd"))
    }
    function isFutureForecastDate(dateString) {
        return Model.isFutureForecastDate(dateString, Qt.formatDate(new Date(), "yyyy-MM-dd"))
    }
    function roundedTemp(value) { return Model.roundedTemp(value) }
    function celsiusToFahrenheit(value) { return Model.celsiusToFahrenheit(value) }
    function formatTemp(value) { return Model.formatTemp(value, useImperial) }
    function dayName(dateString) { return Model.dayName(dateString, function(d){ return Qt.formatDate(d, "dddd") }) }
    function bareTempForDay(day, kind) { return Model.bareTempForDay(day, kind, useImperial) }
    function dayIcon(day) { return Model.dayIcon(day) }
    function iconForOpenMeteoCode(code) { return Model.iconForOpenMeteoCode(code) }
    function iconForCode(code, night) { return Model.iconForCode(code, night) }

    function scheduleForecastRetry() {
        if (forecastRetries >= 3) return
        forecastRetries++
        forecastRetryTimer.restart()
    }
    function scheduleDailyForecastRetry() {
        if (dailyForecastRetries >= 3) return
        dailyForecastRetries++
        dailyForecastRetryTimer.restart()
    }

    // ---- shared state (mirrors Panel.qml root properties) ----
    property var report: null
    property var dailyForecastReport: null
    property string wttrLocation: ""
    property var configuredLocationState: ({ name: "", latitude: null, longitude: null })
    readonly property string configuredLocation: configuredLocationState.name
    readonly property string locationQuery: Model.wttrLocationQuery(configuredLocationState.name, configuredLocationState.latitude, configuredLocationState.longitude)

    onLocationQueryChanged: {
        if (savingLocation) savingLocationQueryStarted = true
        forecastRetries = 0
        dailyForecastRetries = 0
        forecastProc.running = false
        dailyForecastProc.running = false
        Qt.callLater(refresh)
    }

    property int forecastRetries: 0
    property int dailyForecastRetries: 0
    property bool editingLocation: false
    property bool savingLocation: false
    property bool savingLocationQueryStarted: false
    property var locationSuggestions: []
    property int suggestionIndex: 0
    property string geocodePendingQuery: ""
    property string geocodeActiveQuery: ""
    property string label: ""

    readonly property bool hasConfiguredCoordinates: !isNaN(parseFloat(String(configuredLocationState.latitude))) && !isNaN(parseFloat(String(configuredLocationState.longitude)))
    readonly property var openMeteoCurrent: Model.openMeteoCurrentCondition(dailyForecastReport)
    readonly property var current: (hasConfiguredCoordinates && openMeteoCurrent) ? openMeteoCurrent : ((report && report.current_condition && report.current_condition[0]) ? report.current_condition[0] : openMeteoCurrent)
    readonly property var areaInfo: report && report.nearest_area && report.nearest_area[0] ? report.nearest_area[0] : null
    readonly property var forecastDays: buildForecastDays()
    readonly property string reportCountry: areaInfo && areaInfo.country && areaInfo.country[0] ? areaInfo.country[0].value : ""
    readonly property bool useImperial: Model.shouldUseImperial("", Qt.locale().name, reportCountry)
    readonly property int refreshMinutes: 15

    readonly property string reportLocation: configuredLocation || wttrLocation || (areaInfo && areaInfo.areaName && areaInfo.areaName[0] ? areaInfo.areaName[0].value : "")
    readonly property string reportTempNum: current ? String(useImperial ? current.temp_F : current.temp_C) : ""
    readonly property string tempUnit: "°" + (useImperial ? "F" : "C")
    readonly property string reportFeels: current ? formatTemp(useImperial ? current.FeelsLikeF : current.FeelsLikeC) : ""
    readonly property string reportWind: current ? (useImperial ? (current.windspeedMiles + " mph") : (current.windspeedKmph + " km/h")) : ""
    readonly property string reportHumidity: current ? (current.humidity + "%") : ""

    // ---- bar button -------------------------------------------------
    Rectangle {
        id: button
        anchors.fill: parent
        radius: Config.buttonBorderRadius
        color: mouseArea.containsMouse || root.popupOpen ? Config.backgroundHovered : "transparent"

        Text {
            id: barLabel
            anchors.centerIn: parent
            text: root.label || "—"
            color: Config.foreground
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize + 2
            font.weight: Font.Bold
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    // use vendored qs-weather-status via Process
                    weatherStatusProc.running = true
                } else if (mouse.button === Qt.MiddleButton) {
                    root.refresh()
                    if (root.notificationService) root.notificationService.fyi("Weather refresh…", "", "low", 2)
                } else {
                    root.togglePanel()
                }
            }
            onWheel: function(wheel) {
                // optional: scroll to refresh?
            }
        }
    }

    // ---- location file (private path, not omarchy) ------------------
    FileView {
        id: locationFile
        // keep outside dotfiles so git push doesn't leak location
        path: Quickshell.env("HOME") + "/.local/state/quickshell/weather.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.configuredLocationState = Model.parseLocationFile(text())
        onLoadFailed: root.configuredLocationState = Model.parseLocationFile("")
    }

    Timer {
        interval: 1500
        running: true
        onTriggered: locationFile.reload()
    }

    Process {
        id: forecastProc
        command: ["curl", "-fsS", "--max-time", "10", "https://wttr.in/" + root.locationQuery + "?format=j1"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var raw = String(text || "").trim()
                if (!raw) { root.scheduleForecastRetry(); return }
                try {
                    var parsed = JSON.parse(raw)
                    root.report = parsed
                    if (!root.hasConfiguredCoordinates)
                        root.label = Model.provisionalCurrentIcon(parsed.current_condition && parsed.current_condition[0], root.label)
                    root.forecastRetries = 0
                    if (Model.weatherResponseCompletesSave(root.hasConfiguredCoordinates, "wttr"))
                        root.finishSavingLocation()
                    if (isNaN(parseFloat(String(root.configuredLocationState.latitude))))
                        root.refreshDailyForecast(parsed)
                } catch (e) { root.scheduleForecastRetry() }
            }
        }
    }

    Timer {
        id: forecastRetryTimer
        interval: 2500
        onTriggered: if (!forecastProc.running) forecastProc.running = true
    }

    Timer {
        id: dailyForecastRetryTimer
        interval: 2500
        onTriggered: root.refreshDailyForecast(null)
    }

    Process {
        id: dailyForecastProc
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var raw = String(text || "").trim()
                if (!raw) { root.scheduleDailyForecastRetry(); return }
                try {
                    var parsed = JSON.parse(raw)
                    var parsedCurrent = Model.openMeteoCurrentCondition(parsed)
                    root.dailyForecastReport = parsed
                    root.label = Model.currentIcon(parsedCurrent, root.label)
                    root.dailyForecastRetries = 0
                    if (Model.weatherResponseCompletesSave(root.hasConfiguredCoordinates, "open-meteo"))
                        root.finishSavingLocation()
                } catch (e) { root.scheduleDailyForecastRetry() }
            }
        }
    }

    Process {
        id: geocodeProc
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var parsed = Model.parseGeocodingResults(text)
                root.locationSuggestions = root.editingLocation ? parsed : []
                root.suggestionIndex = 0
                if (root.geocodePendingQuery !== root.geocodeActiveQuery) Qt.callLater(root.startGeocode)
            }
        }
        stderr: StdioCollector {
            id: geocodeErr
            waitForEnd: true
        }
        onExited: function(code, status) {
            if (code !== 0) console.log("[Weather] geocode curl failed code", code, String(geocodeErr.text||"").slice(0,200))
        }
    }

    Timer {
        id: geocodeDebounce
        interval: 300
        onTriggered: root.requestGeocode()
    }

    Process {
        id: locationSaveProc
        onExited: function(exitCode) {
            if (exitCode !== 0 || !root.savingLocation) return
            locationFile.reload()
            if (!root.savingLocationQueryStarted) {
                root.savingLocationQueryStarted = true
                root.forecastRetries = 0
                root.dailyForecastRetries = 0
                forecastProc.running = false
                dailyForecastProc.running = false
                Qt.callLater(root.refresh)
            }
        }
    }

    Process {
        id: locationProc
        command: ["curl", "-fsS", "--max-time", "4", "https://wttr.in/?format=%l"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                var raw = String(text || "").trim()
                if (!raw) return
                root.wttrLocation = raw.split(",")[0]
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: root.refreshMinutes * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: weatherStatusProc
        command: [Quickshell.env("HOME") + "/.config.jmmm.sh/bin/qs-weather-status"]
        stdout: StdioCollector {
            id: weatherStatusOut
            waitForEnd: true
            onStreamFinished: {
                var raw = String(text || "").trim()
                if (raw.length > 0 && root.notificationService)
                    root.notificationService.fyi(raw, "", "low", 6)
                else if (raw.length > 0)
                    Quickshell.execDetached(["notify-send", raw])
            }
        }
        onExited: function(code) {
            if (code !== 0) {
                var raw = String(weatherStatusOut.text || "").trim()
                var err = raw.length > 0 ? raw : "Weather unavailable"
                if (root.notificationService) root.notificationService.fyi(err, "", "low", 4)
            }
        }
    }

    // ---- popup panel ------------------------------------------------
    LazyLoader {
        id: popupLoader
        active: root.popupOpen || item !== null

        PopupWindow {
            id: popup
            function focusInput() {
                // Mirrors SolanaTokenPinned's focusSearch: delegate to panel's focus helper
                if (weatherPanel) weatherPanel.focusInput()
            }

            visible: root.popupOpen
            anchor.window: root.barWindow
            color: "transparent"
            implicitWidth: weatherPanel.panelWidth
            implicitHeight: Math.min(
                weatherPanel.desiredHeight,
                Math.max(
                    Config.buttonSize * 6,
                    (root.barWindow && root.barWindow.screen ? root.barWindow.screen.height : 1080)
                        - anchor.rect.y - Config.gapsOut))

            onVisibleChanged: {
                if (!visible && root.popupOpen) root.popupOpen = false
                if (visible) Qt.callLater(popup.focusInput)
            }

            Component.onCompleted: {
                // Expose to root so outer functions can call focusInput without
                // hitting LazyLoader file-scope ReferenceError.
                root.popupRef = popup
                if (!root.barWindow) return
                var position = root.mapToItem(root.barWindow.contentItem, 0, 0)
                anchor.rect.x = position.x + root.width - popup.width
                anchor.rect.y = position.y + root.height + Config.gapsOut + Config.borderSize
                Qt.callLater(popup.focusInput)
            }
            Component.onDestruction: {
                if (root.popupRef === popup) root.popupRef = null
            }

            Rectangle {
                id: weatherPanel
                anchors.fill: parent
                color: Config.backgroundColored
                radius: Config.borderRadius
                clip: true
                focus: true
                Keys.onEscapePressed: {
                    if (root.editingLocation) root.cancelEditingLocation()
                    else root.popupOpen = false
                }

                Component.onCompleted: root.weatherPanelRef = weatherPanel
                Component.onDestruction: if (root.weatherPanelRef === weatherPanel) root.weatherPanelRef = null

                readonly property int panelWidth: 480
                readonly property int contentPadding: 10
                readonly property int desiredHeight: Math.max(160, weatherColumn.implicitHeight + contentPadding * 2)

                // for HyprlandFocusGrab dismissal
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Tab) {
                        // optional panel switch not implemented; just ignore
                    }
                }

                // Focus helper - mirrors SolanaPanel.focusSearch()
                // When editing, give activeFocus to the TextInput so typing works.
                // Otherwise give it to the keyCatcher for Return-to-edit.
                function focusInput() {
                    // Use the ref - direct id lookup would also work inside this
                    // scope, but using the ref keeps the outer/inner boundary explicit
                    // and avoids LazyLoader ReferenceError when called from root.
                    var field = root.locationFieldRef
                    if (root.editingLocation) {
                        if (field) field.forceActiveFocus(Qt.OtherFocusReason)
                        else if (locationField) locationField.forceActiveFocus(Qt.OtherFocusReason)
                    } else if (keyCatcher) keyCatcher.forceActiveFocus(Qt.OtherFocusReason)
                }
                // Keep old name for cancelEditingLocation compatibility
                function forceActiveFocus() { focusInput() }

                Item {
                    id: keyCatcher
                    anchors.fill: parent
                    anchors.margins: weatherPanel.contentPadding
                    focus: true

                    // key catcher: Esc closes, Return starts editing when not editing
                    // When editing, this item deliberately does NOT handle keys so
                    // the TextField descendant receives them. Mirrors
                    // omarchy's PanelKeyCatcher { blocked: root.editingLocation }.
                    Keys.onEscapePressed: {
                        if (root.editingLocation) {
                            // let locationField's Escape handler run first; if we are here
                            // it means the field didn't accept, so cancel.
                            root.cancelEditingLocation()
                        } else {
                            root.popupOpen = false
                        }
                    }
                    Keys.onPressed: function(event) {
                        if (root.editingLocation) return
                        if (event.key === Qt.Key_Return) {
                            root.startEditingLocation()
                            event.accepted = true
                        }
                    }

                    // ensure focus when popup opens
                    Component.onCompleted: forceActiveFocus()

                    Flickable {
                        id: weatherScroll
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: weatherColumn.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        interactive: contentHeight > height

                        Column {
                            id: weatherColumn
                            width: weatherScroll.width
                            spacing: 14

                            // ---- Hero row: big icon + temp on the left; location and stats stacked on the right.
                            Item {
                                id: heroRow
                                width: parent.width
                                height: Math.max(heroLeft.height, heroRight.height)

                                Row {
                                    id: heroLeft
                                    anchors.left: parent.left
                                    anchors.leftMargin: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 16

                                    Text {
                                        id: heroIcon
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.verticalCenterOffset: 5
                                        text: root.label || "—"
                                        color: Config.foreground
                                        font.family: Config.fontFamily
                                        font.pixelSize: 64
                                    }

                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        Text {
                                            id: tempBig
                                            text: root.reportTempNum || "—"
                                            color: Config.foreground
                                            font.family: Config.fontFamily
                                            font.pixelSize: 56
                                            font.bold: true
                                        }
                                        Text {
                                            text: root.current ? root.tempUnit : ""
                                            color: Config.foreground
                                            font.family: Config.fontFamily
                                            font.pixelSize: 20
                                            anchors.top: tempBig.top
                                            anchors.topMargin: 10
                                        }
                                    }
                                }

                                Column {
                                    id: heroRight
                                    width: weatherStats.implicitWidth
                                    anchors.right: parent.right
                                    anchors.rightMargin: 20
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 12

                                    Row {
                                        visible: !root.editingLocation && root.reportLocation !== ""
                                        spacing: 6

                                        TapHandler { onTapped: root.startEditingLocation() }
                                        HoverHandler { cursorShape: Qt.PointingHandCursor }

                                        Text {
                                            text: ""
                                            color: Qt.darker(Config.foreground, 1.4)
                                            font.family: Config.fontFamily
                                            font.pixelSize: Config.fontSize
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: (root.reportLocation || "").toUpperCase()
                                            color: Qt.darker(Config.foreground, 1.4)
                                            font.family: Config.fontFamily
                                            font.pixelSize: Config.fontSize
                                            font.letterSpacing: 1
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Row {
                                        visible: root.editingLocation
                                        spacing: 6

                                        // text field background similar to other panels
                                        Rectangle {
                                            width: 190
                                            height: 26
                                            radius: Math.max(1, Math.round(Config.buttonBorderRadius/2))
                                            color: Config.backgroundColoredTertiary
                                            anchors.verticalCenter: parent.verticalCenter

                                            TextInput {
                                                id: locationField
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                verticalAlignment: TextInput.AlignVCenter
                                                enabled: !root.savingLocation
                                                focus: true
                                                activeFocusOnPress: true
                                                activeFocusOnTab: true
                                                selectByMouse: true
                                                cursorVisible: true
                                                persistentSelection: true
                                                color: Config.foreground
                                                selectionColor: Config.accent
                                                selectedTextColor: Config.foregroundSelected
                                                font.family: Config.fontFamily
                                                font.pixelSize: Config.fontSize
                                                clip: true

                                                Component.onCompleted: root.locationFieldRef = locationField
                                                Component.onDestruction: if (root.locationFieldRef === locationField) root.locationFieldRef = null

                                                // Ensure we actually own activeFocus when row becomes visible
                                                onVisibleChanged: if (visible && root.editingLocation) Qt.callLater(function(){ var f = root.locationFieldRef || locationField; f.forceActiveFocus(Qt.OtherFocusReason) })

                                                onTextChanged: if (root.editingLocation && !root.savingLocation) geocodeDebounce.restart()
                                                // TextInput's accepted signal is more reliable than Keys for Enter
                                                onAccepted: root.commitLocation()

                                                Keys.onPressed: function(event) {
                                                    if (event.key === Qt.Key_Escape) {
                                                        root.cancelEditingLocation()
                                                        event.accepted = true
                                                    } else if (event.key === Qt.Key_Down) {
                                                        if (root.suggestionIndex < root.locationSuggestions.length - 1) root.suggestionIndex++
                                                        event.accepted = true
                                                    } else if (event.key === Qt.Key_Up) {
                                                        if (root.suggestionIndex > 0) root.suggestionIndex--
                                                        event.accepted = true
                                                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                                        root.commitLocation()
                                                        event.accepted = true
                                                    }
                                                }
                                            }

                                            Text {
                                                visible: locationField.text.length === 0
                                                anchors.fill: locationField
                                                anchors.leftMargin: 8
                                                verticalAlignment: Text.AlignVCenter
                                                text: "Search city"
                                                color: Config.foregroundSecondary
                                                font.family: Config.fontFamily
                                                font.pixelSize: Config.fontSize
                                            }
                                        }

                                        Rectangle {
                                            width: 18
                                            height: 18
                                            anchors.verticalCenter: parent.verticalCenter
                                            radius: Math.min(4, Config.borderRadius)
                                            color: !root.savingLocation && clearLocationArea.containsMouse ? Config.backgroundHovered : "transparent"

                                            Text {
                                                id: clearIcon
                                                anchors.centerIn: parent
                                                text: root.savingLocation ? "󰦖" : "✕"
                                                font.family: Config.fontFamily
                                                color: Qt.darker(Config.foreground, 1.4)
                                                font.pixelSize: Config.fontSize - 2
                                                rotation: 0
                                                transformOrigin: Item.Center
                                                RotationAnimator on rotation {
                                                    running: root.savingLocation
                                                    from: 0; to: 360
                                                    duration: 800
                                                    loops: Animation.Infinite
                                                }
                                                Connections {
                                                    target: root
                                                    function onSavingLocationChanged() {
                                                        if (!root.savingLocation) clearIcon.rotation = 0
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                id: clearLocationArea
                                                anchors.fill: parent
                                                enabled: !root.savingLocation
                                                hoverEnabled: true
                                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                onClicked: root.clearLocation()
                                            }
                                        }
                                    }

                                    Row {
                                        id: weatherStats
                                        visible: !!root.current
                                        spacing: 36

                                        Column {
                                            spacing: 5
                                            Text { text: "FEELS"; color: Qt.darker(Config.foreground, 1.5); font.family: Config.fontFamily; font.pixelSize: Config.fontSize - 4; font.letterSpacing: 1 }
                                            Text { text: root.reportFeels; color: Config.foreground; font.family: Config.fontFamily; font.pixelSize: Config.fontSize + 2 }
                                        }
                                        Column {
                                            spacing: 5
                                            Text { text: "WIND"; color: Qt.darker(Config.foreground, 1.5); font.family: Config.fontFamily; font.pixelSize: Config.fontSize - 4; font.letterSpacing: 1 }
                                            Text { text: root.reportWind; color: Config.foreground; font.family: Config.fontFamily; font.pixelSize: Config.fontSize + 2 }
                                        }
                                        Column {
                                            spacing: 5
                                            Text { text: "HUMID"; color: Qt.darker(Config.foreground, 1.5); font.family: Config.fontFamily; font.pixelSize: Config.fontSize - 4; font.letterSpacing: 1 }
                                            Text { text: root.reportHumidity; color: Config.foreground; font.family: Config.fontFamily; font.pixelSize: Config.fontSize + 2 }
                                        }
                                    }
                                }
                            }

                            // ---- Geocoding suggestions while editing
                            Column {
                                visible: root.editingLocation && !root.savingLocation && root.locationSuggestions.length > 0
                                width: parent.width
                                spacing: 0

                                Repeater {
                                    model: root.locationSuggestions

                                    Rectangle {
                                        required property var modelData
                                        required property int index
                                        width: parent.width
                                        height: suggestionRow.implicitHeight + 12
                                        radius: Config.borderRadius
                                        color: index === root.suggestionIndex ? Config.backgroundHovered : "transparent"

                                        Row {
                                            id: suggestionRow
                                            anchors.left: parent.left
                                            anchors.leftMargin: 16
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 8

                                            Text {
                                                text: modelData.name
                                                color: index === root.suggestionIndex ? Config.foreground : Config.foreground
                                                font.family: Config.fontFamily
                                                font.pixelSize: Config.fontSize
                                            }
                                            Text {
                                                visible: text !== ""
                                                text: modelData.description
                                                color: Qt.darker(Config.foreground, 1.5)
                                                font.family: Config.fontFamily
                                                font.pixelSize: Config.fontSize - 2
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onPositionChanged: root.suggestionIndex = index
                                            onClicked: root.pickSuggestion(modelData)
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: !root.current
                                text: "Fetching forecast…"
                                color: Qt.darker(Config.foreground, 1.5)
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSize - 2
                                font.italic: true
                            }

                            Rectangle {
                                visible: root.forecastDays.length > 0
                                width: parent.width
                                height: 1
                                color: Config.foreground
                                opacity: 0.12
                            }

                            Item {
                                visible: root.forecastDays.length > 0
                                width: parent.width
                                height: forecastRow.height

                                Row {
                                    id: forecastRow
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 44

                                    Repeater {
                                        model: root.forecastDays

                                        Row {
                                            required property var modelData
                                            required property int index
                                            spacing: 10

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: root.dayIcon(modelData)
                                                color: Config.foreground
                                                font.family: Config.fontFamily
                                                font.pixelSize: 24
                                            }

                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 2

                                                Text {
                                                    text: root.dayName(modelData.date).toUpperCase()
                                                    color: Qt.darker(Config.foreground, 1.4)
                                                    font.family: Config.fontFamily
                                                    font.pixelSize: Config.fontSize - 4
                                                    font.letterSpacing: 1
                                                }

                                                Row {
                                                    spacing: 6

                                                    Text {
                                                        text: root.bareTempForDay(modelData, "max")
                                                        color: Config.foreground
                                                        font.family: Config.fontFamily
                                                        font.pixelSize: Config.fontSize
                                                    }
                                                    Text {
                                                        text: root.bareTempForDay(modelData, "min")
                                                        color: Qt.darker(Config.foreground, 1.5)
                                                        font.family: Config.fontFamily
                                                        font.pixelSize: Config.fontSize
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    property bool barInGrab: false

    Timer {
        id: barWhitelistTimer
        interval: 80
        onTriggered: {
            if (root.popupOpen) {
                root.barInGrab = true
                var p = root.popupRef || popupLoader.item
                if (p && p.focusInput) Qt.callLater(function(){ p.focusInput() })
            }
        }
    }

    onPopupOpenChanged: {
        if (popupOpen) {
            barInGrab = false
            barWhitelistTimer.restart()
        } else {
            barWhitelistTimer.stop()
            barInGrab = false
        }
    }

    onEditingLocationChanged: {
        if (editingLocation && popupOpen) {
            // Re-prime exclusive grab so TextInput gets wl_keyboard focus,
            // then restore bar whitelist after focus is acquired.
            barInGrab = false
            barWhitelistTimer.restart()
        }
    }

    HyprlandFocusGrab {
        active: root.popupOpen && popupLoader.item !== null
        windows: {
            if (!popupLoader.item) return []
            if (root.barInGrab && root.barWindow) return [popupLoader.item, root.barWindow]
            return [popupLoader.item]
        }
        onActiveChanged: {
            if (active) {
                var p = root.popupRef || popupLoader.item
                if (p && p.focusInput) Qt.callLater(function(){ p.focusInput() })
            }
        }
        onCleared: {
            if (root.editingLocation) root.cancelEditingLocation()
            root.popupOpen = false
        }
    }
}
