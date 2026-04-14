import "."
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root

    property int updateCount: 0
    property var updateProcess

    Layout.preferredWidth: Config.buttonSize
    Layout.preferredHeight: Config.buttonSize
    radius: Config.buttonBorderRadius
    color: mouseArea.containsMouse && root.updateCount > 0 ? Config.backgroundHovered : "transparent"
    opacity: root.updateCount > 0 ? 1 : 0

    Text {
        id: downloadIcon

        anchors.centerIn: parent
        text: "\uF409"
        color: Config.foreground
        font.pixelSize: Config.fontSize
        font.family: Config.fontFamily
    }

    Rectangle {
        id: badge

        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 1
        anchors.bottomMargin: 1
        width: Math.max(12, badgeText.implicitWidth + 4)
        height: 12
        radius: 6
        color: Config.foreground

        Text {
            id: badgeText

            anchors.centerIn: parent
            text: root.updateCount
            color: Config.foregroundSelected
            font.pixelSize: 8
            font.family: Config.fontFamily
            font.bold: true
        }

    }

    Timer {
        id: updateTimer

        interval: 3.6e+06
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: updateProcess.running = true
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        cursorShape: root.updateCount > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
        hoverEnabled: root.updateCount > 0
        enabled: root.updateCount > 0
        onClicked: Quickshell.execDetached(["omarchy-launch-floating-terminal-with-presentation", "omarchy-update"])
    }

    updateProcess: Process {
        command: ["bash", "-c", `
            # Get pacman updates (official repos)
            pacman_updates=$(pacman -Qu 2>/dev/null | wc -l)

            # Get AUR updates only (yay -Qua shows only AUR)
            aur_updates=$(yay -Qua 2>/dev/null | wc -l)

            # Get flatpak updates
            flatpak_updates=$(flatpak remote-ls --updates 2>/dev/null | wc -l)

            # Total is pacman + AUR + flatpak
            total=$((pacman_updates + aur_updates + flatpak_updates))

            echo "$total"
        `]

        stdout: StdioCollector {
            onStreamFinished: {
                var output = updateProcess.stdout.text.trim();
                var count = parseInt(output, 10);
                if (!isNaN(count))
                    root.updateCount = Math.max(0, count);

            }
        }

    }

}
