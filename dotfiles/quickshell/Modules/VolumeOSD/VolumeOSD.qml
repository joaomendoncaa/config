import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Core

Item {
    id: root

    property string prevState: ""
    property bool showOsd: false
    property int volumePercent: 0
    property bool isMuted: false
    readonly property string statePath: Quickshell.env("XDG_RUNTIME_DIR") + "/volume-osd/state"

    readonly property string iconChar: {
        if (root.isMuted || root.volumePercent === 0) return "\uf026"
        if (root.volumePercent < 50) return "\uf027"
        return "\uf028"
    }

    FileView {
        id: stateFile

        path: root.statePath
        watchChanges: true
        onLoaded: {
            var content = text().trim();
            if (!content || content === root.prevState)
                return;

            root.prevState = content;
            var parts = content.split(" ");
            if (parts.length < 2)
                return;

            root.volumePercent = parseInt(parts[0]) || 0;
            root.isMuted = parts[1] === "true";
            root.showOsd = true;
            hideTimer.restart();
        }
        onFileChanged: stateFile.reload()
        onLoadFailed: function(err) {}
    }

    Timer {
        interval: 300
        running: true
        repeat: true
        onTriggered: stateFile.reload()
    }

    Timer {
        id: hideTimer
        interval: 1200
        onTriggered: root.showOsd = false
    }

    PanelWindow {
        id: osdWindow

        visible: root.showOsd
        implicitWidth: 240
        implicitHeight: Config.fontSize * 3
        color: "transparent"
        anchors.bottom: true
        anchors.left: true
        margins.left: Math.round((Screen.width - implicitWidth) / 2)
        margins.bottom: 240
        WlrLayershell.namespace: "volume-osd"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            radius: Config.borderRadius
            color: Config.hexWithAlpha(Config.foreground, "10")

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Text {
                    text: root.iconChar
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize * 1.2
                    color: Config.foreground
                    Layout.preferredWidth: Config.fontSize * 1.5
                    Layout.alignment: Qt.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    Layout.alignment: Qt.AlignVCenter
                    radius: 3
                    color: Config.hexWithAlpha(Config.foreground, "20")

                    Rectangle {
                        width: parent.width * (root.volumePercent / 100)
                        height: parent.height
                        radius: 3
                        color: root.isMuted ? Config.foregroundSecondary : Config.accent
                    }
                }

                Text {
                    text: root.volumePercent + "%"
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize * 0.85
                    color: Config.foreground
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}
