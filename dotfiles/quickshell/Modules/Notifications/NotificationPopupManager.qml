import QtQuick
import Quickshell
import qs.Core

QtObject {
    id: manager

    required property var popupService // NotificationService reference
    required property var modelData // resolved main-monitor screen (from NotificationService)
    property int topMargin: 0
    // Single manager — popups live on the main monitor only, never workspace-aware.
    property var popupWindows: []
    property var overflowWindow: null
    property var destroyingIds: ({
    })
    readonly property int maxVisible: 4
    // Sync popup windows with the visible popup list from the service
    property var serviceConnections

    serviceConnections: Connections {
        function onVisiblePopupsChanged() {
            manager._sync(manager.popupService.visiblePopups);
        }

        target: manager.popupService
        ignoreUnknownSignals: true
    }

    property var pendingConnections

    pendingConnections: Connections {
        function onCountChanged() {
            manager._queueReposition();
        }

        target: manager.popupService ? manager.popupService.pendingModel : null
        ignoreUnknownSignals: true
    }

    // Safety net: a missed exit signal must never leave the pill floating.
    property var overflowTicker

    overflowTicker: Timer {
        interval: 1000
        repeat: true
        running: manager.popupService !== null
        onTriggered: {
            manager._pruneStale();
            manager._queueReposition();
        }
    }

    property bool _repositionPending: false

    function _sync(newPopups) {
        if (!manager.modelData || !newPopups)
            return ;

        var needsReposition = false;
        // Sweep destroyed/finalized windows out of popupWindows
        // (iterate a copy: forceExit() re-enters via exitFinished/releasePopup)
        var snapshot = popupWindows.slice();
        for (var i = snapshot.length - 1; i >= 0; i--) {
            var win = snapshot[i];
            if (!win || win._finalized) {
                var deadIdx = popupWindows.indexOf(win);
                if (deadIdx !== -1)
                    popupWindows.splice(deadIdx, 1);

                needsReposition = true;
                continue;
            }
            // Force-exit any window whose wrapper was removed from visiblePopups
            if (!win.exiting && win.wrapper && newPopups.indexOf(win.wrapper) === -1) {
                win.wrapper.popup = false;
                win.forceExit();
                needsReposition = true;
                continue;
            }
        }
        // Create windows for new popups (oldest-first so unshift preserves service order)
        for (var j = newPopups.length - 1; j >= 0; j--) {
            var wrapper = newPopups[j];
            if (wrapper && wrapper.popup && !_hasWindowFor(wrapper))
                needsReposition = _insertAtTop(wrapper, true) || needsReposition;

        }
        // Recompute the "N more" pill even when no window was added or removed
        _queueReposition();
    }

    function _hasWindowFor(wrapper) {
        for (var i = 0; i < popupWindows.length; i++) {
            var win = popupWindows[i];
            if (win && win.wrapper === wrapper && !win._finalized)
                return true;

        }
        return false;
    }

    function _insertAtTop(wrapper, deferReposition) {
        var comp = Qt.createComponent("NotificationPopup.qml");
        if (comp.status !== Component.Ready) {
            console.warn("NotificationPopup not ready:", comp.errorString());
            return false;
        }
        var win = comp.createObject(null, {
            "wrapper": wrapper,
            "screen": modelData,
            "stackY": topMargin
        });
        if (!win)
            return false;

        win.exitStarted.connect(manager._onExitStarted);
        win.exitFinished.connect(manager._onExitFinished);
        win.popupHeightChanged.connect(manager._queueReposition);
        popupWindows.unshift(win);
        if (!deferReposition)
            _repositionAll();

        return true;
    }

    function _windowFor(wrapper) {
        for (var i = 0; i < popupWindows.length; i++) {
            var win = popupWindows[i];
            if (win && win.wrapper === wrapper && !win._finalized)
                return win;

        }
        return null;
    }

    function _repositionAll() {
        // Follow service order (source of truth) so surviving popups
        // always collapse into the freed slots, regardless of creation order
        var ordered = [];
        var servicePopups = manager.popupService ? manager.popupService.visiblePopups : null;
        if (servicePopups) {
            for (var k = 0; k < servicePopups.length; k++) {
                var w = _windowFor(servicePopups[k]);
                if (w)
                    ordered.push(w);

            }
        }
        for (var m = 0; m < popupWindows.length; m++) {
            var extra = popupWindows[m];
            if (extra && ordered.indexOf(extra) === -1)
                ordered.push(extra);

        }
        var currentY = topMargin;
        for (var i = 0; i < ordered.length; i++) {
            var win = ordered[i];
            try {
                if (!win || win._finalized || win.exiting)
                    continue;

                win.stackY = currentY;
                currentY += (win.implicitHeight || win.height || 0) + 8;
            } catch (e) {
                var idx = popupWindows.indexOf(win);
                if (idx !== -1)
                    popupWindows.splice(idx, 1);

            }
        }
        _updateOverflow(currentY);
    }

    function _updateOverflow(bottom) {
        if (!overflowWindow)
            return ;

        var svc = manager.popupService;
        var hidden = 0;
        var active = 0;
        for (var w = 0; w < popupWindows.length; w++) {
            var win = popupWindows[w];
            if (win && !win._finalized && !win.exiting && win.visible)
                active++;

        }
        if (svc) {
            var ids = svc._overflowIds || [];
            for (var i = 0; i < ids.length; i++) {
                if (svc.hasPendingByOriginalId(ids[i]))
                    hidden++;

            }
        }
        overflowWindow.hiddenCount = hidden;
        overflowWindow.stackY = bottom;
        overflowWindow.shown = hidden > 0 && active > 0;
    }

    function _pruneStale() {
        var svc = manager.popupService;
        if (!svc)
            return ;

        var list = svc.visiblePopups;
        for (var i = list.length - 1; i >= 0; i--) {
            var wrapper = list[i];
            if (!wrapper)
                continue;

            if (!wrapper.popup && !_windowFor(wrapper))
                svc.releasePopup(wrapper);

        }
    }

    function _ensureOverflow() {
        if (manager.overflowWindow || !manager.modelData || !manager.popupService)
            return ;

        var comp = Qt.createComponent("NotificationOverflow.qml");
        if (comp.status !== Component.Ready) {
            console.warn("NotificationOverflow not ready:", comp.errorString());
            return ;
        }
        manager.overflowWindow = comp.createObject(null, {
            "service": manager.popupService,
            "screen": manager.modelData
        });
        manager._queueReposition();
    }

    function _queueReposition() {
        if (_repositionPending)
            return ;

        _repositionPending = true;
        Qt.callLater(_flushReposition);
    }

    function _flushReposition() {
        _repositionPending = false;
        _repositionAll();
    }

    function _onExitStarted(win) {
        if (!win)
            return ;

        _queueReposition();
    }

    function _onExitFinished(win) {
        if (!win)
            return ;

        var key = win.toString();
        if (destroyingIds[key])
            return ;

        destroyingIds[key] = true;
        var idx = popupWindows.indexOf(win);
        if (idx !== -1) {
            popupWindows.splice(idx, 1);
            popupWindows = popupWindows.slice();
        }
        // Release the wrapper in the service
        if (win.wrapper && manager.popupService && manager.popupService.releasePopup)
            manager.popupService.releasePopup(win.wrapper);

        Qt.callLater(function() {
            delete destroyingIds[key];
            win.destroy();
        });
        _queueReposition();
    }

    function cleanupAll() {
        for (var i = popupWindows.length - 1; i >= 0; i--) {
            var win = popupWindows[i];
            if (win)
                win.forceExit();

        }
        popupWindows = [];
    }

    onModelDataChanged: _ensureOverflow()
    Component.onCompleted: {
        _ensureOverflow();
        if (manager.popupService && manager.popupService.visiblePopups)
            _sync(manager.popupService.visiblePopups);

    }
}
