import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs.Core
import qs.Modules.Bar.Widgets
import qs.Modules.ZenBar

PanelWindow {
    id: bar

    property alias powerButtonItem: powerItem
    property alias updatePanelButtonItem: centerBar.updatesItem
    property real powerMenuX: 0
    property real powerMenuY: 0
    property real updatePanelX: 0
    property real updatePanelY: 0
    readonly property int updatePanelWidth: 480
    readonly property int updatePanelHeight: 420
    property bool contentVisible: true
    property bool zenActive: false

    signal toggleLauncher()
    signal togglePowerMenu()
    signal toggleUpdatePanel()
    signal toggleZen()
    signal zenDismissed()

    function updatePowerMenuPosition() {
        var pos = powerItem.mapToItem(null, 0, 0);
        powerMenuX = pos.x + powerItem.width - 160;
        powerMenuY = Config.shellPadding + Config.height + Config.gapsOut;
    }

    function updateUpdatePanelPosition() {
        var btn = centerBar.updatesItem;
        var pos = btn.mapToItem(null, 0, 0);
        updatePanelX = pos.x + btn.width / 2 - bar.updatePanelWidth / 2;
        updatePanelY = Config.shellPadding + Config.height + Config.gapsOut;
    }

    implicitHeight: Config.height
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shell-bar"
    anchors.top: true
    anchors.left: true
    anchors.right: true
    margins.top: Config.shellPadding

    Item {
        anchors.fill: parent
        opacity: !zenActive && contentVisible ? 1 : 0
        enabled: !zenActive && contentVisible

        Rectangle {
            anchors.fill: parent
            color: Config.background
        }

        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: Config.shellPadding
            anchors.right: centerBar.left
            anchors.rightMargin: Config.gapInner
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

                    // TODO make a component for these buttons
                    // this is how we correctly color those icons
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
            id: centerBar

            anchors.centerIn: parent
            anchors.verticalCenter: parent.verticalCenter
            updatesItem.onToggle: {
                bar.updateUpdatePanelPosition();
                bar.toggleUpdatePanel();
            }
            zenmodeItem.onActivated: bar.toggleZen()
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
                    bar.updatePowerMenuPosition();
                    bar.togglePowerMenu();
                }
            }

        }

    }

    Item {
        anchors.fill: parent
        opacity: zenActive ? 1 : 0
        enabled: zenActive

        ZenBarContent {
            anchors.fill: parent
            active: zenActive
            onDismissed: bar.zenDismissed()
        }

    }

}
