import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import "Widgets" as Widgets
import qs.Core

Item {
    id: root

    readonly property string statePath: Quickshell.env("XDG_RUNTIME_DIR") + "/voxtype/state"
    readonly property string stateJsonPath: Quickshell.env("XDG_RUNTIME_DIR") + "/voxtype/state.json"

    property string state: "idle"
    property int maxDurationSecs: 0
    property real elapsedSecs: 0
    property date startedAt: new Date()

    readonly property bool isRecording: state === "recording" || state === "streaming"
    readonly property bool showOsd: state !== "idle"
    readonly property real remainingSecs: maxDurationSecs > 0 ? maxDurationSecs - elapsedSecs : -1

    function setState(newState) {
        if (root.state === newState)
            return;

        var wasRecording = root.isRecording;
        root.state = newState;
        if (!wasRecording && root.isRecording) {
            root.startedAt = new Date();
            root.elapsedSecs = 0;
            waveform.reset();
        }
        if (newState === "clipboard")
            clipboardHideTimer.restart();
        else
            clipboardHideTimer.stop();
    }

    function formatTime(secs) {
        var s = Math.max(0, Math.floor(secs));
        var m = Math.floor(s / 60);
        var r = s % 60;
        return (m < 10 ? "0" : "") + m + ":" + (r < 10 ? "0" : "") + r;
    }

    function parseStateJson() {
        var content = stateJson.text().trim();
        if (!content)
            return;

        try {
            var d = JSON.parse(content);
            root.maxDurationSecs = d.max_duration_secs || 0;
            root.setState(d.state || "idle");
        } catch (e) {
        }
    }

    FileView {
        id: stateJson

        path: root.stateJsonPath
        watchChanges: true
        onLoaded: root.parseStateJson()
        onFileChanged: reload()
        printErrors: false
    }

    FileView {
        id: statePlain

        path: root.statePath
        watchChanges: true
        onLoaded: {
            if (!stateJson.loaded)
                root.setState(text().trim() || "idle");
        }
        onFileChanged: reload()
        printErrors: false
    }

    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: {
            stateJson.reload();
            statePlain.reload();
            if (root.isRecording)
                root.elapsedSecs = (new Date() - root.startedAt) / 1000;
        }
    }

    // "Sent to clipboard" is terminal feedback — hide shortly after.
    Timer {
        id: clipboardHideTimer

        interval: 2500
        onTriggered: {
            if (root.state === "clipboard")
                root.setState("idle");
        }
    }

    PwNodePeakMonitor {
        id: peakMonitor

        node: Pipewire.defaultAudioSource
        enabled: root.isRecording
    }

    PanelWindow {
        id: osdWindow

        visible: root.showOsd
        implicitWidth: 220
        implicitHeight: root.isRecording ? Config.fontSize * 3 : Config.fontSize * 3.4
        color: "transparent"
        anchors.bottom: true
        anchors.left: true
        margins.left: Math.round((Screen.width - implicitWidth) / 2)
        margins.bottom: 200
        WlrLayershell.namespace: "dictation-osd"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        Behavior on implicitHeight {
            NumberAnimation {
                duration: 150
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Config.borderRadius
            color: Config.hexWithAlpha(Config.backgroundColored, "80")

            // Recording: waveform + elapsed/countdown timer
            Item {
                anchors.fill: parent
                visible: root.isRecording

                Widgets.Waveform {
                    id: waveform

                    anchors.fill: parent
                    anchors.margins: 6
                    peak: peakMonitor.peak
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize * 0.65
                    font.bold: true
                    text: root.remainingSecs >= 0 ? root.formatTime(root.remainingSecs) : root.formatTime(root.elapsedSecs)
                    color: root.remainingSecs >= 0 && root.remainingSecs <= 15
                        ? "#FF5555"
                        : Config.foregroundSecondary
                }
            }

            // Transcribing / clipboard fallback: spinner + label
            Column {
                anchors.centerIn: parent
                spacing: 6
                visible: !root.isRecording
                opacity: root.isRecording ? 0 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: 100
                    }
                }

                Widgets.Spinner {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: root.state === "clipboard" ? Config.accent : Config.foreground
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize * 0.75
                    text: root.state === "clipboard" ? "Sent to clipboard" : "Transcribing…"
                    color: root.state === "clipboard" ? Config.accent : Config.foregroundSecondary
                }
            }

        }

    }

}
