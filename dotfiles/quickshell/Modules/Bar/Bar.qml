import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs.Core
import qs.Modules.Bar.Widgets

PanelWindow {
    id: bar

    signal toggleLauncher()
    signal togglePowerMenu()

    property alias powerButtonItem: powerItem

    property real powerMenuX: 0
    property real powerMenuY: 0

    property bool contentVisible: true
    mask: contentVisible ? Qt.region(0, 0, bar.width, bar.height) : Qt.region()

    function updatePowerMenuPosition() {
        var pos = powerItem.mapToItem(null, 0, 0)
        powerMenuX = pos.x + powerItem.width - 160
        powerMenuY = Config.shellPadding + Config.height + Config.gapsOut
    }

    implicitHeight: Config.height
    color: Config.background
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shell-bar"
    anchors.top: true
    anchors.left: true
    anchors.right: true
    margins.top: Config.shellPadding

    Item {
        anchors.fill: parent
        opacity: contentVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: Config.shellPadding
            anchors.verticalCenter: parent.verticalCenter
            spacing: Config.gapInner

        Rectangle {
            Layout.preferredWidth: Config.buttonSize
            Layout.preferredHeight: Config.buttonSize
            radius: Config.buttonBorderRadius
            color: mouseArea.containsMouse ? Config.backgroundHovered : "transparent"

            Item {
                id: iconContainer

                anchors.centerIn: parent
                width: Config.buttonSize * 0.7
                height: Config.buttonSize * 0.7

                Image {
                    id: maskImage

                    anchors.fill: parent
                    source: "../../Assets/search.svg"
                    sourceSize.width: width
                    sourceSize.height: height
                    smooth: true
                    visible: false
                }

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

            MouseArea {
                id: mouseArea

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                onClicked: bar.toggleLauncher()
            }

        }

        Workspaces {
        }

        Opencode {
            barWindow: bar
        }

    }

    CenterBar {
        anchors.centerIn: parent
        anchors.verticalCenter: parent.verticalCenter
    }

    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: Config.shellPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.gapInner

        Monitor {
        }

        Sink {
        }

        Power {
            id: powerItem
            barWindow: bar
            onToggle: {
                bar.updatePowerMenuPosition()
                bar.togglePowerMenu()
            }
        }

    }

}

}
