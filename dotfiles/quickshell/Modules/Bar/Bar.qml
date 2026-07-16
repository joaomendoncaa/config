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
import qs.Modules.Notifications

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
    property bool isRecording: false

    readonly property alias notificationCenterOpen: notifButton.popupOpen

    signal toggleLauncher()
    signal togglePowerMenu()
    signal toggleUpdatePanel()
    signal toggleZen()
    signal zenDismissed()

    required property var priceLabels
    required property var notificationService

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

            Workspaces {
            }

            Opencode {
                barWindow: bar
            }

        }

        CenterBar {
            id: centerBar

            notificationService: bar.notificationService
            isRecording: bar.isRecording

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

            Text {
                text: "Updating prices..."
                visible: bar.priceLabels.loading
                color: Config.foreground
                font.pixelSize: Config.fontSize - 2
                font.family: Config.fontFamily
                Layout.preferredHeight: Config.buttonSize
                Layout.preferredWidth: implicitWidth + Config.gapInner * 2
                verticalAlignment: Text.AlignVCenter
            }

            Repeater {
                model: bar.priceLabels.loading ? [] : bar.priceLabels.trackedTokens
                delegate: PriceLabel {
                    mint: modelData
                    priceData: bar.priceLabels.tokenData[modelData]
                }
            }

            Monitor {
            }

            Sink {
            }

            NotificationButton {
                id: notifButton
                barWindow: bar
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
