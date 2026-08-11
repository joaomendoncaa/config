import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs.Core
import "Widgets"
import "../Notifications"

PanelWindow {
    id: bar

    property alias powerButtonItem: powerItem
    property real powerMenuX: 0
    property real powerMenuY: 0
    property bool contentVisible: true
    property bool isRecording: false

    property alias notificationCenterOpen: notifButton.popupOpen
    property alias solanaPanelOpen: solanaWidget.popupOpen
    property alias agentPanelOpen: agentWidget.popupVisible

    Updates {
        id: barUpdates
        notificationService: bar.notificationService
        visible: false
    }

    signal toggleLauncher()
    signal togglePowerMenu()
    signal solanaPanelOpening()
    signal notificationPanelOpening()
    signal agentPanelOpening()
    signal dismissPanels()

    required property var priceLabels
    required property var agentService
    required property var notificationService

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
            anchors.left: parent.left
            anchors.leftMargin: Config.shellPadding
            anchors.right: centerBar.left
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

        }

        CenterBar {
            id: centerBar

            notificationService: bar.notificationService
            isRecording: bar.isRecording

            anchors.centerIn: parent
            anchors.verticalCenter: parent.verticalCenter
        }

        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: Config.shellPadding
            anchors.verticalCenter: parent.verticalCenter
            spacing: Config.gapInner

            SolanaTokenPinned {
                id: solanaWidget
                service: bar.priceLabels
                barWindow: bar
                onOpening: bar.solanaPanelOpening()
            }

            Monitor {
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
