import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import "Widgets" as Widgets
import qs.Core

Item {
    id: root

    property string prevState: ""
    property bool showOsd: false
    readonly property string statePath: Quickshell.env("XDG_RUNTIME_DIR") + "/voxtype/state"

    FileView {
        id: stateFile

        path: root.statePath
        watchChanges: true
        onLoaded: {
            var content = text().trim();
            if (!content || content === root.prevState)
                return ;

            root.prevState = content;
            root.showOsd = content !== "idle";
        }
        onFileChanged: stateFile.reload()
        onLoadFailed: function(err) {
        }
    }

    Timer {
        interval: 300
        running: true
        repeat: true
        onTriggered: stateFile.reload()
    }

    PwNodePeakMonitor {
        id: peakMonitor

        node: Pipewire.defaultAudioSource
        enabled: root.showOsd
    }

    PanelWindow {
        id: osdWindow

        visible: root.showOsd
        implicitWidth: 200
        implicitHeight: Config.fontSize * 3
        color: "transparent"
        anchors.bottom: true
        anchors.left: true
        margins.left: Math.round((Screen.width - implicitWidth) / 2)
        margins.bottom: 200
        WlrLayershell.namespace: "dictation-osd"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            radius: Config.borderRadius
            color: Config.hexWithAlpha(Config.foreground, "10")

            Widgets.Waveform {
                id: waveform

                anchors.fill: parent
                anchors.margins: 6
                peak: peakMonitor.peak
            }

        }

    }

}
