import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Core

PanelWindow {
    id: root

    property real popupX: 0
    property real popupY: 0

    signal dismissed()

    visible: true
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "power-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    readonly property var powerActions: [
        { icon: "\uf023", text: "Lock", cmd: "qs-power-lock" },
        { icon: "\uf021", text: "Reboot", cmd: "qs-power-reboot" },
        { icon: "\uf011", text: "Shutdown", cmd: "qs-power-shutdown" },
    ]

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.2)

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismissed()
        }

    }

    Rectangle {
        id: card

        x: 0
        y: 0
        width: 160
        height: 112
        color: Config.hexWithAlpha(Config.backgroundColored, "CC")
        radius: Config.borderRadius
        focus: true

        property int selectedIndex: 0

        function activateItem(index) {
            var action = root.powerActions[index]
            if (action)
                Quickshell.execDetached([action.cmd])
            root.dismissed()
        }

        Keys.onEscapePressed: root.dismissed()
        Keys.onUpPressed: selectedIndex = Math.max(0, selectedIndex - 1)
        Keys.onDownPressed: selectedIndex = Math.min(root.powerActions.length - 1, selectedIndex + 1)
        Keys.onReturnPressed: activateItem(selectedIndex)

        Keys.onPressed: function(event) {
            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_N) {
                    selectedIndex = Math.min(root.powerActions.length - 1, selectedIndex + 1)
                    event.accepted = true
                } else if (event.key === Qt.Key_P) {
                    selectedIndex = Math.max(0, selectedIndex - 1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Y) {
                    activateItem(selectedIndex)
                    event.accepted = true
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 2

            Repeater {
                model: root.powerActions

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 4
                    color: {
                        if (index === card.selectedIndex)
                            return Config.backgroundHovered
                        return "transparent"
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: modelData.icon
                            color: Config.foreground
                            font.family: Config.fontFamily
                            font.pixelSize: Config.fontSize - 2
                        }

                        Text {
                            text: modelData.text
                            color: Config.foreground
                            font.family: Config.fontFamily
                            font.pixelSize: Config.fontSize - 2
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: card.selectedIndex = index
                        onClicked: card.activateItem(index)
                    }

                }

            }

        }

    }

    Component.onCompleted: {
        card.x = root.popupX
        card.y = root.popupY
        card.forceActiveFocus()
    }

}
