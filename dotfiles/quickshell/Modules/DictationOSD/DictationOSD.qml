import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
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

    PanelWindow {
        id: osdWindow

        visible: root.showOsd
        implicitWidth: 150
        implicitHeight: Config.fontSize * 3
        color: "transparent"
        anchors.bottom: true
        anchors.left: true
        margins.left: osdWindow.screen ? Math.round((osdWindow.screen.width - 150) / 2) : 0
        margins.bottom: 200
        WlrLayershell.namespace: "dictation-osd"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            radius: Config.borderRadius
            color: Config.hexWithAlpha(Config.foreground, "10")

            Text {
                anchors.centerIn: parent
                text: "TRANSCRIBING"
                color: Config.foreground
                font.pixelSize: Config.fontSize
                font.bold: true
                font.family: Config.fontFamily
            }

        }

    }

}
