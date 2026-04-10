import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

PanelWindow {
    implicitHeight: 30
    color: config.background
    anchors.top: true
    anchors.left: true
    anchors.right: true
    margins.top: config.shellPadding

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    QtObject {
        id: config

        readonly property int fontSize: 16
        readonly property int buttonSize: 26
        readonly property int buttonBorderRadius: 4
        readonly property int gapOuter: 12
        readonly property int gapInner: 4
        readonly property string fontFamily: "JetBrainsMonoNL Nerd Font"
        readonly property string foreground: "white"
        readonly property string foregroundSelected: "black"
        readonly property string background: "transparent"
        readonly property string backgroundHovered: "#40FFFFFF"
        readonly property int shellPadding: 10
    }

    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: config.shellPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: config.gapInner

        Repeater {
            model: Hyprland.workspaces

            delegate: Rectangle {
                required property var modelData

                Layout.preferredWidth: config.buttonSize
                Layout.preferredHeight: config.buttonSize
                radius: config.buttonBorderRadius
                color: modelData.focused ? config.foreground : workspaceMouseArea.containsMouse ? config.backgroundHovered : config.background

                Text {
                    anchors.centerIn: parent
                    text: modelData.id
                    color: modelData.focused ? config.foregroundSelected : config.foreground
                    font.pixelSize: config.fontSize
                }

                MouseArea {
                    id: workspaceMouseArea

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.activate()
                    hoverEnabled: true
                }

            }

        }

        Canvas {
            id: circleCanvas

            property real circleRotation: 0

            Layout.leftMargin: config.gapOuter
            Layout.preferredWidth: config.buttonSize
            Layout.preferredHeight: config.buttonSize
            onPaint: {
                var ctx = getContext('2d');
                ctx.clearRect(0, 0, width, height);
                ctx.save();
                ctx.translate(width / 2, height / 2);
                ctx.rotate(circleRotation * Math.PI / 180);
                ctx.strokeStyle = config.foreground;
                ctx.lineWidth = 3;
                ctx.setLineDash([0.5, 0.5]);
                ctx.beginPath();
                ctx.arc(0, 0, 10, 0, Math.PI * 2);
                ctx.stroke();
                ctx.restore();
            }

            Timer {
                interval: 16
                running: true
                repeat: true
                onTriggered: {
                    circleCanvas.circleRotation = (circleCanvas.circleRotation + 2) % 360;
                    circleCanvas.requestPaint();
                }
            }

        }

    }

    RowLayout {
        anchors.centerIn: parent
        anchors.verticalCenter: parent.verticalCenter
        spacing: config.gapInner

        Rectangle {
            id: clockRectangle

            Layout.preferredWidth: clockText.implicitWidth + config.gapInner * 4
            Layout.preferredHeight: config.buttonSize
            radius: config.buttonBorderRadius
            color: clockMouseArea.containsMouse ? config.backgroundHovered : "transparent"

            Text {
                id: clockText

                anchors.centerIn: parent
                text: Qt.formatDateTime(clock.date, "dd MMM dddd hh:mm:ss")
                color: config.foreground
                font.pixelSize: config.fontSize
                font.family: config.fontFamily
            }

            MouseArea {
                id: clockMouseArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["notify-send", "TODO: integrate calendar"])
            }

        }

    }

    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: config.shellPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: config.gapInner

        Rectangle {
            id: audioSinkButton

            property real volumeRatio: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio ? Pipewire.defaultAudioSink.audio.volume : 0
            property bool isHeadphones: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.name === "alsa_output.usb-Razer_Razer_Barracuda_X-00.analog-stereo" : false
            property bool isMuted: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio.muted : false

            Layout.preferredWidth: config.buttonSize
            Layout.preferredHeight: config.buttonSize
            radius: config.buttonBorderRadius
            color: audioSinkMouseArea.containsMouse ? config.backgroundHovered : "transparent"

            Canvas {
                id: audioIcon

                anchors.centerIn: parent
                width: config.buttonSize
                height: config.buttonSize
                visible: Pipewire.defaultAudioSink !== null
                onPaint: {
                    var ctx = getContext('2d');
                    ctx.clearRect(0, 0, width, height);
                    var iconText = audioSinkButton.isMuted ? audioSinkButton.isHeadphones ? "󰟎" : "󰓄" : iconText = audioSinkButton.isHeadphones ? "" : "󰓃";
                    var x = audioSinkButton.isHeadphones ? width / 2 - 3 : width / 2;
                    var y = audioSinkButton.isHeadphones ? height / 2 + 2 : height / 2 + 2;
                    var volStop = audioSinkButton.volumeRatio.toFixed(2);
                    var gradient = ctx.createLinearGradient(0, height, 0, 0);
                    gradient.addColorStop(0, "rgba(255, 255, 255, 1.0)");
                    gradient.addColorStop(Math.max(0, volStop - 0.01), "rgba(255, 255, 255, 1.0)");
                    gradient.addColorStop(volStop, "rgba(255, 255, 255, 0.5)");
                    gradient.addColorStop(1, "rgba(255, 255, 255, 0.5)");
                    ctx.font = config.fontSize + "px '" + config.fontFamily + "'";
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

                    target: audioSinkButton
                }

            }

            MouseArea {
                id: audioSinkMouseArea

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["/home/joao/.config.jmmm.sh/bin/toggle-sink"])
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

        Rectangle {
            id: powerButton

            Layout.preferredWidth: config.buttonSize
            Layout.preferredHeight: config.buttonSize
            radius: config.buttonBorderRadius
            color: powerArea.containsMouse ? config.backgroundHovered : "transparent"

            Text {
                anchors.centerIn: parent
                text: ""
                color: config.foreground
                font.pixelSize: config.fontSize
            }

            MouseArea {
                id: powerArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["omarchy-menu", "system"])
            }

        }

    }

}
