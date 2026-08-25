import qs.Core
import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    property string submapName: ""

    readonly property var labels: ({
            "toggles": "SUPER+T",
            "twitter": "SUPER+X",
            "comms": "SUPER+C"
        })

    readonly property string displayText: {
        if (!submapName)
            return ""
        return labels[submapName] || submapName
    }

    Layout.preferredWidth: submapName !== "" ? row.implicitWidth + Config.gapInner * 4 : 0
    Layout.preferredHeight: Config.buttonSize
    Layout.maximumWidth: submapName !== "" ? row.implicitWidth + Config.gapInner * 4 : 0
    implicitWidth: row.implicitWidth + Config.gapInner * 4
    radius: Config.buttonBorderRadius
    color: Config.backgroundSecondary
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

        Text {
            id: label
            text: root.displayText
            color: Config.foreground
            font.pixelSize: Config.fontSize - 1
            font.family: Config.fontFamily
            font.weight: Font.Medium
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
