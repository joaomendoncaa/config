import "../Notifications"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import "Widgets"
import qs.Core

PanelWindow {
    id: bar

    property alias powerButtonItem: powerItem
    property real powerMenuX: 0
    property real powerMenuY: 0
    property bool contentVisible: true
    property bool isRecording: false
    property string submapName: ""
    property alias notificationCenterOpen: notifButton.popupOpen
    property alias solanaPanelOpen: solanaWidget.popupOpen
    property alias agentPanelOpen: agentWidget.popupVisible
    property alias vpnPanelOpen: vpnButton.popupOpen
    required property var priceLabels
    required property var agentService
    required property var notificationService
    required property var vpnService

    signal toggleLauncher()
    signal togglePowerMenu()
    signal solanaPanelOpening()
    signal notificationPanelOpening()
    signal agentPanelOpening()
    signal vpnPanelOpening()
    signal dismissPanels()

    function updatePowerMenuPosition() {
        var pos = powerItem.mapToItem(null, 0, 0);
        powerMenuX = pos.x + powerItem.width - 160;
        powerMenuY = Config.shellPadding + Config.height + Config.gapsOut;
    }

    implicitHeight: Config.height + Config.shellPadding
    exclusiveZone: Config.height
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shell-bar"
    anchors.top: true
    anchors.left: true
    anchors.right: true
    margins.top: Config.shellPadding

    Updates {
        id: barUpdates

        notificationService: bar.notificationService
        visible: false
    }

    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Config.height
        opacity: contentVisible ? 1 : 0
        enabled: contentVisible
        focus: true
        Keys.onEscapePressed: bar.dismissPanels()

        Rectangle {
            anchors.fill: parent
            color: Config.background
        }

        RowLayout {
            id: leftLayout

            anchors.left: parent.left
            anchors.leftMargin: Config.shellPadding
            anchors.right: rightLayout.left
            anchors.rightMargin: Config.gapInner
            anchors.verticalCenter: parent.verticalCenter
            spacing: Config.gapInner

            Workspaces {
                Layout.fillWidth: false
                Layout.minimumWidth: implicitWidth
                Layout.preferredWidth: implicitWidth
                Layout.maximumWidth: implicitWidth
                Layout.preferredHeight: Config.buttonSize
            }

            AgentWidget {
                id: agentWidget

                barWindow: bar
                service: bar.agentService
                onOpening: bar.agentPanelOpening()
            }

            Submap {
                submapName: bar.submapName
            }

        }

        RowLayout {
            id: rightLayout

            anchors.right: parent.right
            anchors.rightMargin: Config.shellPadding
            anchors.verticalCenter: parent.verticalCenter
            spacing: Config.gapInner

            Recording {
                isRecording: bar.isRecording
            }

            SolanaTokenPinned {
                id: solanaWidget

                service: bar.priceLabels
                barWindow: bar
                onOpening: bar.solanaPanelOpening()
            }

            Monitor {
            }

            VpnButton {
                id: vpnButton

                service: bar.vpnService
                barWindow: bar
                onOpening: bar.vpnPanelOpening()
            }

            Sink {
            }

            NotificationButton {
                id: notifButton

                barWindow: bar
                notificationService: bar.notificationService
                updatesItem: barUpdates
                onOpening: bar.notificationPanelOpening()
            }

            Clock {
                notificationService: bar.notificationService
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

}
