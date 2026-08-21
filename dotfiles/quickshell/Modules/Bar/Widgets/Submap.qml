import qs.Core
import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    property string submapName: ""

    // Friendly labels for known submaps; falls back to raw name
    readonly property var labels: ({
            "toggles": "SUPER+T",
            "twitter": "SUPER+X",
            "comms": "SUPER+C"
        })

    readonly property string displayText: {
        if (!submapName)
            return ""
        var prefix = labels[submapName]
        if (prefix)
            return prefix + "  ›  " + submapName
        return submapName
    }

    Layout.preferredWidth: submapName !== "" ? row.implicitWidth + Config.gapInner * 4 : 0
    Layout.preferredHeight: Config.buttonSize
    Layout.maximumWidth: submapName !== "" ? row.implicitWidth + Config.gapInner * 4 : 0
    implicitWidth: row.implicitWidth + Config.gapInner * 4
    radius: Config.buttonBorderRadius
    color: mouseArea.containsMouse ? Config.accent : Config.backgroundColoredSecondary
    border.width: 1
    border.color: Config.accent
    visible: submapName !== ""
    clip: true

    Behavior on Layout.preferredWidth {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        NumberAnimation { duration: 150 }
    }
    opacity: submapName !== "" ? 1 : 0

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Config.gapInner

        // Record dot indicator
        Rectangle {
            Layout.preferredWidth: 8
            Layout.preferredHeight: 8
            radius: 4
            color: Config.accent

            SequentialAnimation on opacity {
                running: root.submapName !== ""
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.4; duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.4; to: 1.0; duration: 700; easing.type: Easing.InOutSine }
            }
        }

        Text {
            id: label
            text: root.displayText
            color: root.submapName !== "" ? Config.foreground : "transparent"
            font.pixelSize: Config.fontSize - 1
            font.family: Config.fontFamily
            font.weight: Font.Medium
        }

        Text {
            text: "· ESC to cancel"
            color: Config.foregroundSecondary
            font.pixelSize: Config.fontSize - 3
            font.family: Config.fontFamily
            visible: root.submapName !== ""
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "submap", "reset"])
    }
}
