import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Core

PanelWindow {
    id: zenBar

    property bool active: false

    signal dismissed()

    implicitHeight: Config.height
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "shell-zenbar"
    anchors.top: true
    anchors.left: true
    anchors.right: true
    margins.top: Config.shellPadding
    margins.left: Config.shellPadding
    margins.right: Config.shellPadding

    ZenBarContent {
        anchors.fill: parent
        active: zenBar.active
        onDismissed: zenBar.dismissed()
    }

}
