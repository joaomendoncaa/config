import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

PanelWindow {
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

        Workspaces {
        }

        Opencode {
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
