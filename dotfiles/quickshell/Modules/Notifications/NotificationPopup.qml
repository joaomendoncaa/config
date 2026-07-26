import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.Core

PanelWindow {
    id: win

    required property var wrapper
    required property var screen
    property bool exiting: false
    property bool _finalized: false
    readonly property bool hovered: hoverHandler.hovered
    readonly property real entryTravel: 40
    readonly property real exitTravel: 60
    readonly property real cardWidth: 380

    signal entered()
    signal exitStarted()
    signal exitFinished()
    signal popupHeightChanged()

    property real stackY: 0

    anchors.right: true
    anchors.top: true
    margins.right: Config.shellPadding
    margins.top: stackY

    implicitWidth: cardWidth
    implicitHeight: card.implicitHeight

    WlrLayershell.namespace: "quickshell-notification-popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    visible: !_finalized

    HoverHandler { id: hoverHandler }

    // Pause auto-dismiss while hovered
    onHoveredChanged: {
        if (!win.wrapper) return
        if (hovered) {
            win.wrapper.stopPopupTimer()
        } else if (win.wrapper.popup && !win.exiting) {
            win.wrapper.startPopupTimer()
        }
    }

    // Swipe-to-dismiss via DragHandler on the card
    DragHandler {
        id: swipeHandler
        target: card
        enabled: !win.exiting && !win._finalized
        xAxis.minimum: 0
        xAxis.maximum: card.width

        readonly property real swipeThreshold: card.width * 0.35

        onActiveChanged: {
            if (active) return
            if (target.x > swipeThreshold) {
                swipeDismissAnim.restart()
            } else {
                snapBackAnim.restart()
            }
        }
    }

    NumberAnimation {
        id: snapBackAnim
        target: card
        property: "x"
        to: 0
        duration: 150
        easing.type: Easing.OutQuad
    }

    SequentialAnimation {
        id: swipeDismissAnim
        onFinished: { if (win.wrapper) win.wrapper.popup = false }

        ParallelAnimation {
            NumberAnimation {
                target: card; property: "x"
                to: card.width + 20
                duration: 150; easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: contentWrapper; property: "opacity"
                to: 0; duration: 120; easing.type: Easing.InQuad
            }
        }
    }

    // Wrapper item for opacity + transform animations (PanelWindow doesn't support them)
    Item {
        id: contentWrapper
        anchors.fill: parent
        opacity: 0

        transform: Translate {
            id: entryTx
            x: entryTravel
        }

        NotificationCard {
            id: card
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 0
            anchors.rightMargin: 0

            app: win.wrapper ? win.wrapper.app : ""
            appIcon: win.wrapper ? win.wrapper.appIcon : ""
            summary: win.wrapper ? win.wrapper.summary : ""
            body: win.wrapper ? win.wrapper.body : ""
            image: win.wrapper ? win.wrapper.image : ""
            glyph: win.wrapper ? win.wrapper.glyph : ""
            urgency: win.wrapper ? win.wrapper.urgency : 1
            timestamp: win.wrapper ? win.wrapper.timestamp : 0
            expireTimeout: win.wrapper ? win.wrapper.expireTimeout : 0
            duplicateCount: win.wrapper ? win.wrapper.duplicateCount : 1
            cornerRadius: Config.borderRadius
            popupProgress: -1
            notificationActions: win.wrapper ? win.wrapper.actions : []
            hideActionButtons: true

            onCloseRequested: {
                if (win.wrapper) {
                    win.wrapper.popup = false
                    if (win.wrapper.service && win.wrapper.originalId)
                        win.wrapper.service.dismissPendingByOriginalId(win.wrapper.originalId)
                }
            }
            onCardClicked: {
                if (win.wrapper) {
                    win.wrapper.popup = false
                    win.invokeDefaultAction()
                    if (win.wrapper.service && win.wrapper.originalId)
                        win.wrapper.service.dismissPendingByOriginalId(win.wrapper.originalId)
                }
            }
        }
    }

    // Entry — slide in from right + fade in
    ParallelAnimation {
        id: enterAnim
        onFinished: { contentWrapper.opacity = 1; entryTx.x = 0; win.entered() }

        NumberAnimation {
            target: entryTx; property: "x"
            from: entryTravel; to: 0
            duration: 250
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.25, 0.8, 0.25, 1.0]
        }
        NumberAnimation {
            target: contentWrapper; property: "opacity"
            from: 0; to: 1; duration: 200
        }
    }

    // Exit — slide right + fade out
    ParallelAnimation {
        id: exitAnim
        onFinished: win.finalizeExit()

        NumberAnimation {
            target: card; property: "x"
            from: card.x; to: card.x + exitTravel
            duration: 200; easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: contentWrapper; property: "opacity"
            to: 0; duration: 180; easing.type: Easing.InQuad
        }
    }

    function startExit() {
        if (exiting || _finalized) return
        exiting = true
        exitStarted()
        exitAnim.restart()
    }

    function forceExit() {
        if (_finalized) return
        _finalized = true
        exiting = true
        visible = false
        exitFinished()
    }

    function finalizeExit() {
        if (_finalized) return
        _finalized = true
        exiting = true
        exitFinished()
    }

    function invokeDefaultAction() {
        if (!win.wrapper || !win.wrapper.service) return
        win.wrapper.service.invokeDefaultFromWrapper(win.wrapper)
    }

    // Poll wrapper.popup — Connections on QtObject/vars are unreliable in QML
    Timer {
        id: popupWatchdog
        interval: 50
        repeat: true
        running: !win.exiting && !win._finalized && win.wrapper !== null
        onTriggered: {
            if (win.wrapper && !win.wrapper.popup && !win.exiting && !win._finalized)
                win.startExit()
        }
    }

    // Watch for notification dropped by sender
    Connections {
        target: win.wrapper && win.wrapper.ref ? win.wrapper.ref : null
        ignoreUnknownSignals: true
        function onDropped() {
            if (win.wrapper) win.wrapper.popup = false
        }
    }

    Component.onCompleted: {
        if (win.wrapper) {
            enterAnim.restart()
        } else {
            forceExit()
        }
    }

    Component.onDestruction: {
        if (win.wrapper) win.wrapper.stopPopupTimer()
    }
}
