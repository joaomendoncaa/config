import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Rectangle {
    id: root

    property real volumeRatio: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio.volume : 0
    property bool isHeadphones: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.name === "alsa_output.usb-Razer_Razer_Barracuda_X-00.analog-stereo" : false
    property bool isMuted: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.muted : false

    Layout.preferredWidth: Config.buttonSize
    Layout.preferredHeight: Config.buttonSize
    radius: Config.buttonBorderRadius
    color: mouseArea.containsMouse ? Config.backgroundHovered : "transparent"

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Canvas {
        id: audioIcon

        anchors.centerIn: parent
        width: Config.buttonSize
        height: Config.buttonSize
        visible: Pipewire.defaultAudioSink !== null
        onPaint: {
            var ctx = getContext('2d');
            ctx.clearRect(0, 0, width, height);
            var iconText = root.isMuted ? root.isHeadphones ? "󰟎" : "󰓄" : root.isHeadphones ? "" : "󰓃";
            var x = root.isHeadphones ? width / 2 - 2.5 : width / 2;
            var y = root.isHeadphones ? height / 2 + 2 : height / 2 + 2;
            var volStop = root.volumeRatio.toFixed(2);
            var gradient = ctx.createLinearGradient(0, height, 0, 0);
            gradient.addColorStop(0, Config.foreground);
            gradient.addColorStop(Math.max(0, volStop - 0.01), Config.foreground);
            gradient.addColorStop(volStop, Config.foregroundSecondary);
            gradient.addColorStop(1, Config.foregroundSecondary);
            ctx.font = Config.fontSize + "px '" + Config.fontFamily + "'";
            ctx.fillStyle = gradient;
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText(iconText, x, y);
        }

        Connections {
            function onVolumeRatioChanged() {
                audioIcon.requestPaint();
            }

            function onIsHeadphonesChanged() {
                audioIcon.requestPaint();
            }

            function onIsMutedChanged() {
                audioIcon.requestPaint();
            }

            target: root
        }

        Connections {
            function onForegroundChanged() {
                audioIcon.requestPaint();
            }

            target: Config
        }

    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.MiddleButton)
                Quickshell.execDetached(["omarchy-launch-audio"]);
            else if (mouse.button === Qt.RightButton)
                Quickshell.execDetached(["pamixer", "-t"]);
            else
                Quickshell.execDetached(["/home/joao/.config.jmmm.sh/bin/toggle-sink"]);
        }
        onWheel: function(wheel) {
            if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio)
                return ;

            var step = 0.05;
            var currentVol = Pipewire.defaultAudioSink.audio.volume;
            var newVol;
            if (wheel.angleDelta.y > 0)
                newVol = Math.min(1, currentVol + step);
            else
                newVol = Math.max(0, currentVol - step);
            Pipewire.defaultAudioSink.audio.volume = newVol;
        }
    }

}
