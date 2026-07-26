import QtQuick
import Quickshell.Services.Notifications

QtObject {
    id: wrapper

    property int id: 0
    property int originalId: 0
    property string app: ""
    property string appIcon: ""
    property string summary: ""
    property string body: ""
    property string image: ""
    property string glyph: ""
    property int urgency: NotificationUrgency.Normal
    property double expireTimeout: 0
    property double timestamp: 0
    property string contentHash: ""
    property int duplicateCount: 1
    property bool popup: false
    property bool popupClosing: false
    property real popupProgress: 1.0
    property var ref: null
    property var service: null
    property string _clickCommand: ""
    property string _desktopEntry: ""

    // Actions from the DBus notification (list of {identifier, text, invoke})
    readonly property var actions: ref && ref.actions ? ref.actions : []

    property Timer popupTimer: Timer {
        repeat: false
        onTriggered: {
            if (wrapper.popup) wrapper.popup = false
        }
    }

    function startPopupTimer() {
        if (!popupTimer) return
        var duration = service ? service.durationFor(wrapper.urgency, wrapper.expireTimeout) : 8000
        if (duration <= 0) return
        popupTimer.interval = duration
        wrapper.popupProgress = 1.0
        popupTimer.start()
    }

    function stopPopupTimer() {
        if (popupTimer) popupTimer.stop()
    }
}
