import qs.Core
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
    color: mouseArea.containsMouse && root.updateCount > 0 ? Config.foreground : "transparent"
    opacity: root.updateCount > 0 ? 1 : 0

    Rectangle {
        id: badge

        anchors.centerIn: parent
        width: Config.buttonSize * 0.7
        height: Config.buttonSize * 0.7
        radius: width / 2
        color: Config.foreground

        Text {
            id: badgeText

            anchors.centerIn: parent
            text: root.updateCount
            color: Config.foregroundSelected
            font.pixelSize: Config.fontSize * 0.75
            font.family: Config.fontFamily
            font.bold: true
        }

    }

    Timer {
        id: updateTimer

        interval: 1.2e+06
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
            # Omarchy decides if we show updates
            if omarchy-update-available 2>/dev/null | grep -qi "up to date"; then
                echo 0
            else
                pacman_updates=$(pacman -Qu 2>/dev/null | wc -l)
                aur_updates=$(yay -Qua 2>/dev/null | wc -l)
                flatpak_updates=$(flatpak remote-ls --updates 2>/dev/null | wc -l)
                echo $((pacman_updates + aur_updates + flatpak_updates + 1))
            fi
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
