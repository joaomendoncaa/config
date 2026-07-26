import QtQuick
import Quickshell

QtObject {
    id: manager

    required property var modelData // screen object
    required property var popupService // NotificationService reference
    property int topMargin: 0
    property var popupWindows: []
    property var destroyingIds: ({})

    readonly property int maxVisible: 4

    // Sync popup windows with the visible popup list from the service
    property var serviceConnections: Connections {
        target: manager.popupService
        ignoreUnknownSignals: true

        function onVisiblePopupsChanged() {
            manager._sync(manager.popupService.visiblePopups)
        }
    }

    function _sync(newPopups) {
        if (!newPopups) return
        var needsReposition = false

        // Sweep destroyed/finalized windows out of popupWindows
        for (var i = popupWindows.length - 1; i >= 0; i--) {
            var win = popupWindows[i]
            if (!win || win._finalized) {
                popupWindows.splice(i, 1)
                needsReposition = true
                continue
            }
            // Force-exit any window whose wrapper was removed from visiblePopups
            if (!win.exiting && win.wrapper && newPopups.indexOf(win.wrapper) === -1) {
                win.wrapper.popup = false
                win.forceExit()
                needsReposition = true
                continue
            }
        }

        // Create windows for new popups
        for (var j = 0; j < newPopups.length; j++) {
            var wrapper = newPopups[j]
            if (wrapper && wrapper.popup && !_hasWindowFor(wrapper)) {
                needsReposition = _insertAtTop(wrapper, true) || needsReposition
            }
        }

        if (needsReposition) _queueReposition()
    }

    function _hasWindowFor(wrapper) {
        for (var i = 0; i < popupWindows.length; i++) {
            var win = popupWindows[i]
            if (win && win.wrapper === wrapper && !win._finalized)
                return true
        }
        return false
    }

    function _insertAtTop(wrapper, deferReposition) {
        var comp = Qt.createComponent("NotificationPopup.qml")
        if (comp.status !== Component.Ready) {
            console.warn("NotificationPopup not ready:", comp.errorString())
            return false
        }
        var win = comp.createObject(null, {
            wrapper: wrapper,
            screen: modelData,
            stackY: topMargin
        })
        if (!win) return false

        win.exitStarted.connect(manager._onExitStarted)
        win.exitFinished.connect(manager._onExitFinished)
        win.popupHeightChanged.connect(manager._queueReposition)

        popupWindows.unshift(win)
        if (!deferReposition) _repositionAll()
        return true
    }

    function _repositionAll() {
        var currentY = topMargin
        for (var i = 0; i < popupWindows.length; i++) {
            var win = popupWindows[i]
            if (!win || win._finalized || win.exiting) continue
            try {
                win.stackY = currentY
                currentY += (win.implicitHeight || 0) + 8
            } catch (e) {
                popupWindows.splice(i, 1)
                i--
            }
        }
    }

    property bool _repositionPending: false
    function _queueReposition() {
        if (_repositionPending) return
        _repositionPending = true
        Qt.callLater(_flushReposition)
    }
    function _flushReposition() {
        _repositionPending = false
        _repositionAll()
    }

    function _onExitStarted(win) {
        if (!win) return
        _queueReposition()
    }

    function _onExitFinished(win) {
        if (!win) return
        var key = win.toString()
        if (destroyingIds[key]) return
        destroyingIds[key] = true

        var idx = popupWindows.indexOf(win)
        if (idx !== -1) {
            popupWindows.splice(idx, 1)
            popupWindows = popupWindows.slice()
        }

        // Release the wrapper in the service
        if (win.wrapper && manager.popupService && manager.popupService.releasePopup) {
            manager.popupService.releasePopup(win.wrapper)
        }

        Qt.callLater(function() {
            delete destroyingIds[key]
            win.destroy()
        })

        _queueReposition()
    }

    function cleanupAll() {
        for (var i = popupWindows.length - 1; i >= 0; i--) {
            var win = popupWindows[i]
            if (win) win.forceExit()
        }
        popupWindows = []
    }

    Component.onCompleted: {
        if (manager.popupService && manager.popupService.visiblePopups) {
            _sync(manager.popupService.visiblePopups)
        }
    }
}
