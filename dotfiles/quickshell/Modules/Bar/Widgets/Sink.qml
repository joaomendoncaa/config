import qs.Core
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Rectangle {
    id: root

    property real volumeRatio: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio.volume : 0
    property bool isHeadphones: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.name === Config.sinkHeadphones : false
    property bool isMuted: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio.muted : false
    readonly property bool sinkReady: Pipewire.defaultAudioSink !== null && Pipewire.defaultAudioSink.audio !== null
    readonly property string iconSource: {
        if (root.isHeadphones)
            return root.isMuted ? "../../../Assets/sink-headphones-muted.svg" : "../../../Assets/sink-headphones.svg";

        return root.isMuted ? "../../../Assets/sink-speakers-muted.svg" : "../../../Assets/sink-speakers.svg";
    }

    function scaleForBar(value) {
        if (value <= 0)
            return 0;

        return Math.pow(value, 0.66);
    }

    function writeVolumeState() {
        if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio)
            return;

        var percent = Math.round(Pipewire.defaultAudioSink.audio.volume * 100);
        var muted = Pipewire.defaultAudioSink.audio.muted ? "true" : "false";
        var stateDir = Quickshell.env("XDG_RUNTIME_DIR") + "/volume-osd";
        Quickshell.execDetached(["sh", "-c", "mkdir -p " + stateDir + " && echo '" + percent + " " + muted + "' > " + stateDir + "/state"]);
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

        // Skeleton loading background, shown until the sink is resolved
        Item {
            id: skeleton

            anchors.fill: parent
            clip: true
            visible: opacity > 0
            opacity: root.sinkReady ? 0 : 1

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            Item {
                id: shimmerSource

                anchors.fill: parent
                clip: true
                visible: false

                Rectangle {
                    anchors.fill: parent
                    color: Config.hexWithAlpha(Config.foreground, "66")
                }

                Item {
                    id: shimmerBand

                    width: shimmerSource.width * 1.8
                    height: shimmerSource.height * 1.8

                    LinearGradient {
                        anchors.fill: parent
                        start: Qt.point(0, 0)
                        end: Qt.point(parent.width, parent.height)
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: "transparent"
                            }
                            GradientStop {
                                position: 0.5
                                color: Config.foreground
                            }
                            GradientStop {
                                position: 1
                                color: "transparent"
                            }
                        }
                    }

                    ParallelAnimation {
                        running: !root.sinkReady
                        loops: Animation.Infinite

                        NumberAnimation {
                            target: shimmerBand
                            property: "x"
                            from: -shimmerBand.width
                            to: shimmerSource.width
                            duration: 1170
                            easing.type: Easing.Linear
                        }

                        NumberAnimation {
                            target: shimmerBand
                            property: "y"
                            from: -shimmerBand.height
                            to: shimmerSource.height
                            duration: 1170
                            easing.type: Easing.Linear
                        }
                    }

                }

            }

            OpacityMask {
                anchors.fill: parent
                source: shimmerSource
                maskSource: maskImage
            }

        }

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
            visible: root.sinkReady
        }

        // Foreground layer: same icon in primary color, clipped to volume height
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: parent.height * scaleForBar(Math.max(0, Math.min(1, root.volumeRatio)))
            clip: true
            color: "transparent"
            visible: root.sinkReady

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
            else if (mouse.button === Qt.RightButton) {
                if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio)
                    return ;

                Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
                root.writeVolumeState();
            } else
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
            root.writeVolumeState();
        }
    }

}
