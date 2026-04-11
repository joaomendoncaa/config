import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

PanelWindow {
    implicitHeight: 30
    color: config.background
    anchors.top: true
    anchors.left: true
    anchors.right: true
    margins.top: config.shellPadding

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    QtObject {
        id: config

        readonly property int fontSize: 16
        readonly property int buttonSize: 26
        readonly property int buttonBorderRadius: 4
        readonly property int gapOuter: 12
        readonly property int gapInner: 4
        readonly property string fontFamily: "JetBrainsMonoNL Nerd Font"
        readonly property string foreground: "white"
        readonly property string foregroundSelected: "black"
        readonly property string background: "transparent"
        readonly property string backgroundHovered: "#40FFFFFF"
        readonly property int shellPadding: 10
    }

    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: config.shellPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: config.gapInner

        Workspaces {
            foreground: config.foreground
            foregroundSelected: config.foregroundSelected
            background: config.background
            backgroundHovered: config.backgroundHovered
            buttonSize: config.buttonSize
            buttonBorderRadius: config.buttonBorderRadius
            fontSize: config.fontSize
        }

        Opencode {
            foreground: config.foreground
            buttonSize: config.buttonSize
        }

    }

    RowLayout {
        anchors.centerIn: parent
        anchors.verticalCenter: parent.verticalCenter
        spacing: config.gapInner

        Clock {
            foreground: config.foreground
            backgroundHovered: config.backgroundHovered
            buttonSize: config.buttonSize
            buttonBorderRadius: config.buttonBorderRadius
            fontSize: config.fontSize
            gapInner: config.gapInner
            fontFamily: config.fontFamily
        }

    }

    RowLayout {
        anchors.right: parent.right
        anchors.rightMargin: config.shellPadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: config.gapInner

        Monitor {
            foreground: config.foreground
            backgroundHovered: config.backgroundHovered
            buttonSize: config.buttonSize
            buttonBorderRadius: config.buttonBorderRadius
        }

        Sink {
            foreground: config.foreground
            backgroundHovered: config.backgroundHovered
            buttonSize: config.buttonSize
            buttonBorderRadius: config.buttonBorderRadius
            fontSize: config.fontSize
            fontFamily: config.fontFamily
        }

        Power {
            foreground: config.foreground
            backgroundHovered: config.backgroundHovered
            buttonSize: config.buttonSize
            buttonBorderRadius: config.buttonBorderRadius
            fontSize: config.fontSize
        }

    }

}
