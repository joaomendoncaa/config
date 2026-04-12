import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Rectangle {
    id: root

    property color foreground: "white"
    property color backgroundHovered: "#40FFFFFF"
    property int buttonSize: 26
    property int buttonBorderRadius: 4
    property int fontSize: 16
    property string fontFamily: "JetBrainsMonoNL Nerd Font"
    property real volumeRatio: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio.volume : 0
    property bool isHeadphones: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.name === "alsa_output.usb-Razer_Razer_Barracuda_X-00.analog-stereo" : false
    property bool isMuted: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.muted : false

    Layout.preferredWidth: buttonSize
    Layout.preferredHeight: buttonSize
    radius: buttonBorderRadius
    color: mouseArea.containsMouse ? backgroundHovered : "transparent"

    Canvas {
        id: audioIcon

        anchors.centerIn: parent
        width: buttonSize
        height: buttonSize
        visible: Pipewire.defaultAudioSink !== null
        onPaint: {
            var ctx = getContext('2d');
            ctx.clearRect(0, 0, width, height);
            var iconText = root.isMuted ? root.isHeadphones ? "󰟎" : "󰓄" : root.isHeadphones ? "" : "󰓃";
            var x = root.isHeadphones ? width / 2 - 2.5 : width / 2;
            var y = root.isHeadphones ? height / 2 + 2 : height / 2 + 2;
            var volStop = root.volumeRatio.toFixed(2);
            var gradient = ctx.createLinearGradient(0, height, 0, 0);
            gradient.addColorStop(0, "rgba(255, 255, 255, 1.0)");
            gradient.addColorStop(Math.max(0, volStop - 0.01), "rgba(255, 255, 255, 1.0)");
            gradient.addColorStop(volStop, "rgba(255, 255, 255, 0.5)");
            gradient.addColorStop(1, "rgba(255, 255, 255, 0.5)");
            ctx.font = fontSize + "px '" + fontFamily + "'";
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
