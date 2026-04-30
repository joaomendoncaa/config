import "."
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Rectangle {
    id: root

    property real volumeRatio: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio.volume : 0
    property bool isHeadphones: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.name === Config.sinkHeadphones : false
    property bool isMuted: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.muted : false
    readonly property string iconSource: {
        if (root.isHeadphones)
            return root.isMuted ? "assets/sink-headphones-muted.svg" : "assets/sink-headphones.svg";

        return root.isMuted ? "assets/sink-speakers-muted.svg" : "assets/sink-speakers.svg";
    }

    function scaleForBar(value) {
        if (value <= 0)
            return 0;

        return Math.pow(value, 0.66);
    }

    Layout.preferredWidth: Config.buttonSize
    Layout.preferredHeight: Config.buttonSize
    radius: Config.buttonBorderRadius
    color: mouseArea.containsMouse ? Config.backgroundHovered : "transparent"

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Item {
        id: iconContainer

        anchors.centerIn: parent
        width: Config.buttonSize * 0.7
        height: Config.buttonSize * 0.7
        visible: Pipewire.defaultAudioSink !== null

        // Shared mask image (alpha only)
        Image {
            id: maskImage

            anchors.fill: parent
            source: root.iconSource
            sourceSize.width: width
            sourceSize.height: height
            smooth: true
            visible: false
        }

        // Background layer: full icon in secondary color
        Rectangle {
            id: bgColor

            anchors.fill: parent
            color: Config.foregroundSecondary
            visible: false
        }

        OpacityMask {
            anchors.fill: parent
            source: bgColor
            maskSource: maskImage
        }

        // Foreground layer: same icon in primary color, clipped to volume height
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: parent.height * scaleForBar(Math.max(0, Math.min(1, root.volumeRatio)))
            clip: true
            color: "transparent"

            Item {
                anchors.bottom: parent.bottom
                width: parent.width
                height: iconContainer.height

                Rectangle {
                    id: fgColor

                    anchors.fill: parent
                    color: Config.foreground
                    visible: false
                }

                OpacityMask {
                    anchors.fill: parent
                    source: fgColor
                    maskSource: maskImage
                }

            }

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

            var step = 0.025;
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
