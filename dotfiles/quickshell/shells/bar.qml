import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import ".."

PanelWindow {
    id: bar
    implicitHeight: Config.height
    color: Config.background
    anchors.top: true
    anchors.left: true
    anchors.right: true
    margins.top: Config.shellPadding

    property bool searchOpen: false
    signal toggleSearch

    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: Config.shellPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.gapInner

        Workspaces {
        }

        Opencode {
            barWindow: bar
        }

    }

    RowLayout {
        anchors.centerIn: parent
        anchors.verticalCenter: parent.verticalCenter
        spacing: Config.gapInner

        Recording {
        }

        Clock {
        }

        Updates {
        }

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

        Item {
            width: Config.buttonSize
            height: Config.buttonSize

            Rectangle {
                anchors.fill: parent
                radius: Config.buttonSize / 2
                color: bar.searchOpen ? Config.accent : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\u{1F50D}"
                    color: bar.searchOpen ? Config.backgroundColored : Config.foreground
                    font.pixelSize: Config.fontSize + 4
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: bar.toggleSearch()
                }
            }
        }

        Power {
        }

    }

}
