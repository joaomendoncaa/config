import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Core

// The "N more" pill under the popup stack, as Hokum does it.
PanelWindow {
    id: root

    required property var service
    property int hiddenCount: 0
    property real stackY: 0
    property bool shown: false

    anchors.top: true
    anchors.right: true
    margins.top: stackY
    margins.right: Config.shellPadding
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight
    visible: shown && hiddenCount > 0 && !Config.zenMode
    color: "transparent"

    WlrLayershell.namespace: "quickshell-notification-more"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
        id: pill

        implicitWidth: row.implicitWidth + 24
        implicitHeight: 28
        radius: 999
        color: Config.backgroundColoredSecondary
        border.width: 1
        border.color: Config.hexWithAlpha(Config.foreground, "30")

        RowLayout {
            id: row

            anchors.centerIn: parent
            spacing: 8

            Text {
                text: root.hiddenCount + " more"
                color: Config.foregroundSecondary
                font.family: Config.fontFamily
                font.pixelSize: Math.max(10, Config.fontSize - 6)
            }

            Text {
                text: "Open"
                color: Config.foreground
                font.family: Config.fontFamily
                font.pixelSize: Math.max(10, Config.fontSize - 6)
            }

        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.service.historyOpenRequested()
        }

    }

}
