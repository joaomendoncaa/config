import ".."
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

PanelWindow {
    id: bar

    property bool searchOpen: false

    signal toggleSearch()

    implicitHeight: Config.height
    color: Config.background
    anchors.top: true
    anchors.left: true
    anchors.right: true
    margins.top: Config.shellPadding

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
                    source: "../assets/search.svg"
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
                onClicked: bar.toggleSearch()
            }

        }

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

        Power {
        }

    }

}
