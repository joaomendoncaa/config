import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.Core

Rectangle {
    id: root

    property var notificationService: null
    property bool popupOpen: false

    signal dismissed()

    readonly property int notificationCount: notificationService ? notificationService.pendingModel.count : 0
    readonly property bool dnd: notificationService ? notificationService.doNotDisturb : false

    readonly property string emptyIcon: {
        if (dnd) return "../../Assets/notifs-muted.svg"
        return "../../Assets/notifs.svg"
    }

    // Grouped notifications by desktopEntry/appName
    readonly property var groupedNotifications: {
        if (!notificationService) return []
        var groups = {}
        var order = []
        for (var i = 0; i < notificationService.pendingModel.count; i++) {
            var entry = notificationService.pendingModel.get(i)
            if (!entry) continue
            var key = (entry._desktopEntry || entry.app || "").toLowerCase()
            if (!key) key = entry.app || "unknown"
            if (!groups[key]) {
                groups[key] = {
                    key: key,
                    appName: entry.app || "",
                    appIcon: entry.appIcon || "",
                    notifications: [],
                    latestTimestamp: 0,
                    highestUrgency: 0,
                    count: 0
                }
                order.push(key)
            }
            groups[key].notifications.push({
                index: i,
                entry: entry
            })
            if (entry.timestamp > groups[key].latestTimestamp)
                groups[key].latestTimestamp = entry.timestamp
            if (entry.urgency > groups[key].highestUrgency)
                groups[key].highestUrgency = entry.urgency
            groups[key].count++
        }
        order.sort(function(a, b) {
            var ga = groups[a], gb = groups[b]
            if (ga.highestUrgency !== gb.highestUrgency)
                return gb.highestUrgency - ga.highestUrgency
            return gb.latestTimestamp - ga.latestTimestamp
        })
        return order.map(function(k) { return groups[k] })
    }

    // Flat list for keyboard navigation
    readonly property var flatNotifications: {
        if (!notificationService) return []
        var flat = []
        for (var i = 0; i < notificationService.pendingModel.count; i++) {
            var entry = notificationService.pendingModel.get(i)
            if (entry) flat.push({ index: i, entry: entry })
        }
        return flat
    }

    property int selectedIndex: -1
    property string activeTab: "active" // "active" or "history"
    property string historyFilter: "all" // "all", "today", "hour", "week"

    implicitWidth: 400
    radius: Config.borderRadius
    color: Config.backgroundColored
    clip: true

    focus: true
    Keys.onEscapePressed: root.dismissed()

    // Keyboard navigation
    Keys.onUpPressed: {
        if (root.flatNotifications.length === 0) return
        if (root.selectedIndex <= 0) {
            root.selectedIndex = root.flatNotifications.length - 1
        } else {
            root.selectedIndex--
        }
    }
    Keys.onDownPressed: {
        if (root.flatNotifications.length === 0) return
        if (root.selectedIndex >= root.flatNotifications.length - 1) {
            root.selectedIndex = 0
        } else {
            root.selectedIndex++
        }
    }
    Keys.onReturnPressed: {
        if (root.selectedIndex < 0 || root.selectedIndex >= root.flatNotifications.length) return
        var item = root.flatNotifications[root.selectedIndex]
        if (root.notificationService) root.notificationService.invokePendingDefault(item.index)
        root.dismissed()
    }
    Keys.onDeletePressed: {
        if (root.selectedIndex < 0 || root.selectedIndex >= root.flatNotifications.length) return
        var item = root.flatNotifications[root.selectedIndex]
        if (root.notificationService) root.notificationService.dismissPending(item.index)
        if (root.selectedIndex >= root.flatNotifications.length)
            root.selectedIndex = root.flatNotifications.length - 1
    }
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Backspace) {
            if (root.selectedIndex < 0 || root.selectedIndex >= root.flatNotifications.length) return
            var item = root.flatNotifications[root.selectedIndex]
            if (root.notificationService) root.notificationService.dismissPending(item.index)
            if (root.selectedIndex >= root.flatNotifications.length)
                root.selectedIndex = root.flatNotifications.length - 1
            event.accepted = true
        }
    }

    // Tab through groups
    Keys.onTabPressed: {
        if (root.flatNotifications.length === 0) return
        if (root.selectedIndex < 0) {
            root.selectedIndex = 0
        } else {
            // Jump to next group
            var currentApp = ""
            if (root.selectedIndex < root.flatNotifications.length) {
                var entry = root.flatNotifications[root.selectedIndex].entry
                currentApp = (entry._desktopEntry || entry.app || "").toLowerCase()
            }
            for (var i = root.selectedIndex + 1; i < root.flatNotifications.length; i++) {
                var e = root.flatNotifications[i].entry
                var app = (e._desktopEntry || e.app || "").toLowerCase()
                if (app !== currentApp) {
                    root.selectedIndex = i
                    return
                }
            }
            root.selectedIndex = 0 // wrap
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

            // Header row — title + icon buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: "Notifications"
                    color: Config.foreground
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                    font.bold: true
                }

                // Clear all
                Rectangle {
                    Layout.preferredWidth: clearText2.implicitWidth + 16
                    Layout.preferredHeight: 28
                    radius: 4
                    visible: root.activeTab !== "history" && root.notificationCount > 0
                    color: clearArea2.containsMouse ? Config.backgroundHovered : "transparent"

                    Text {
                        id: clearText2
                        anchors.centerIn: parent
                        text: "Clear All"
                        color: Config.foreground
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize
                    }

                    MouseArea {
                        id: clearArea2
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!root.notificationService) return
                            for (var i = root.notificationService.visiblePopups.length - 1; i >= 0; i--)
                                root.notificationService.visiblePopups[i].popup = false
                            root.notificationService.markAllSeen()
                        }
                    }
                }

                // History toggle
                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 4
                    color: histArea.containsMouse ? Config.backgroundHovered
                         : (root.activeTab === "history" ? Config.backgroundColoredSecondary : "transparent")

                    Text {
                        anchors.centerIn: parent
                        text: "☰"
                        color: root.activeTab === "history" ? Config.accent : Config.foreground
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize
                    }

                    MouseArea {
                        id: histArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = root.activeTab === "history" ? "active" : "history"
                    }
                }

                // DnD toggle
                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 4
                    color: dndArea.containsMouse ? Config.backgroundHovered : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: root.dnd ? "󰂠" : "󰂚"
                        color: root.dnd ? Config.accent : Config.foreground
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize
                    }

                    MouseArea {
                        id: dndArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.notificationService)
                                root.notificationService.setDoNotDisturb(!root.dnd)
                        }
                    }
                }
            }

        // History filter chips (only visible in history tab)
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: root.activeTab === "history"

            Repeater {
                model: [
                    { label: "All", key: "all" },
                    { label: "Hour", key: "hour" },
                    { label: "Today", key: "today" },
                    { label: "Week", key: "week" }
                ]

                Rectangle {
                    required property var modelData
                    Layout.preferredWidth: filterText.implicitWidth + 12
                    Layout.preferredHeight: 22
                    radius: 11
                    color: root.historyFilter === modelData.key ? Config.accent : Config.backgroundColoredSecondary

                    Text {
                        id: filterText
                        anchors.centerIn: parent
                        text: modelData.label
                        color: root.historyFilter === modelData.key ? Config.foregroundSelected : Config.foreground
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize - 6
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.historyFilter = modelData.key
                    }
                }
            }
        }

        // Active tab — grouped notification list
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8

            model: root.activeTab === "active" ? root.groupedNotifications : []
            visible: count > 0 && root.activeTab === "active"

            delegate: ColumnLayout {
                required property var modelData
                width: listView.width
                spacing: 4

                // Notifications in this group
                Repeater {
                    model: modelData.notifications

                    NotificationCard {
                        required property var modelData
                        required property int index

                        property bool keyboardSelected: {
                            if (root.selectedIndex < 0) return false
                            var flatItem = root.flatNotifications[root.selectedIndex]
                            return flatItem && flatItem.index === modelData.index
                        }

                        Layout.fillWidth: true
                        app: modelData.entry.app
                        appIcon: modelData.entry.appIcon
                        summary: modelData.entry.summary
                        body: modelData.entry.body
                        image: modelData.entry.image
                        urgency: modelData.entry.urgency
                        timestamp: modelData.entry.timestamp
                        expireTimeout: modelData.entry.expireTimeout
                        duplicateCount: modelData.entry.duplicateCount
                        busy: !!modelData.entry._busy
                        cornerRadius: Config.borderRadius
                        showCloseButton: true
                        iconSize: 32
                        titleFontSize: Config.fontSize - 2
                        bodyFontSize: Config.fontSize - 4
                        bodyMaxLines: 2
                        cardBackground: keyboardSelected ? Config.backgroundColoredTertiary : Config.backgroundColoredSecondary
                        cardBorderColor: keyboardSelected ? Config.accent : Config.foregroundSecondary
                        cardBorderWidth: keyboardSelected ? 2 : 1

                        onCloseRequested: {
                            if (root.notificationService) root.notificationService.dismissPending(modelData.index)
                        }
                        onCardClicked: {
                            if (root.notificationService) root.notificationService.invokePendingDefault(modelData.index)
                            root.dismissed()
                        }
                    }
                }
            }
        }

        // History tab — filtered past notifications
        ListView {
            id: historyListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            visible: root.activeTab === "history" && count > 0

            model: {
                if (!root.notificationService || root.activeTab !== "history") return []
                var entries = []
                var cutoff = 0
                var now = Date.now()
                if (root.historyFilter === "hour") cutoff = now - 3600000
                else if (root.historyFilter === "today") {
                    var d = new Date()
                    d.setHours(0, 0, 0, 0)
                    cutoff = d.getTime()
                } else if (root.historyFilter === "week") cutoff = now - 604800000

                for (var i = 0; i < root.notificationService.pastModel.count; i++) {
                    var entry = root.notificationService.pastModel.get(i)
                    if (!entry) continue
                    if (root.historyFilter !== "all" && entry.timestamp < cutoff) continue
                    entries.push({ index: i, entry: entry })
                }
                return entries
            }

            delegate: NotificationCard {
                required property var modelData
                required property int index

                width: historyListView.width
                app: modelData.entry.app
                appIcon: modelData.entry.appIcon
                summary: modelData.entry.summary
                body: modelData.entry.body
                urgency: modelData.entry.urgency
                timestamp: modelData.entry.timestamp
                expireTimeout: 0
                duplicateCount: modelData.entry.duplicateCount
                image: ""
                cornerRadius: Config.borderRadius
                showCloseButton: false
                iconSize: 32
                titleFontSize: Config.fontSize - 2
                bodyFontSize: Config.fontSize - 4
                bodyMaxLines: 2
                cardBackground: Config.backgroundColoredSecondary
                cardBorderColor: Config.foregroundSecondary
                cardBorderWidth: 1

                onCardClicked: {
                    if (root.notificationService) root.notificationService.invokePastDefault(modelData.index)
                    root.dismissed()
                }
            }
        }

        // Empty state
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: (root.activeTab === "active" && listView.count === 0) || (root.activeTab === "history" && historyListView.count === 0)

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48

                    Image {
                        id: emptyMaskImage
                        anchors.fill: parent
                        source: root.emptyIcon
                        sourceSize.width: 48
                        sourceSize.height: 48
                        smooth: true
                        visible: false
                    }

                    Rectangle {
                        id: emptyFgColor
                        anchors.fill: parent
                        color: Config.foreground
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: emptyFgColor
                        maskSource: emptyMaskImage
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.activeTab === "history" ? "No history" : (root.dnd ? "Do Not Disturb" : "No notifications")
                    color: Qt.darker(Config.foreground, 1.4)
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                }
            }
        }
    }
}
