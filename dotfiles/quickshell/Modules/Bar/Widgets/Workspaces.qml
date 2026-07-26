import qs.Core
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

RowLayout {
    id: root

    spacing: Config.gapInner

    Repeater {
        model: {
            var ids = [];
            var values = Hyprland.workspaces.values;
            for (var i = 0; i < values.length; i++) {
                var id = values[i].id;
                if (id >= 1 && id <= 10 && ids.indexOf(id) === -1) {
                    ids.push(id);
                }
            }
            ids.sort(function(a, b) { return a - b; });
            return ids;
        }

        delegate: Rectangle {
            required property int modelData

            readonly property var workspace: {
                var values = Hyprland.workspaces.values;
                for (var i = 0; i < values.length; i++) {
                    if (values[i].id === modelData) return values[i];
                }
                return null;
            }

            Layout.preferredWidth: Config.buttonSize
            Layout.preferredHeight: Config.buttonSize
            radius: Config.buttonBorderRadius
            color: (workspace && workspace.focused) ? Config.foreground : mouseArea.containsMouse ? Config.backgroundHovered : Config.background

            Text {
                anchors.centerIn: parent
                text: modelData
                color: (workspace && workspace.focused) ? Config.foregroundSelected : Config.foreground
                font.pixelSize: Config.fontSize
                font.family: Config.fontFamily
            }

            MouseArea {
                id: mouseArea

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { if (workspace) workspace.activate(); }
                hoverEnabled: true
            }

        }

    }

    Rectangle {
        Layout.preferredWidth: Config.buttonSize
        Layout.preferredHeight: Config.buttonSize
        radius: Config.buttonBorderRadius
        color: plusMouseArea.containsMouse ? Config.backgroundHovered : Config.background

        Text {
            anchors.centerIn: parent
            text: "+"
            color: Config.foreground
            font.pixelSize: Config.fontSize
        }

        MouseArea {
            id: plusMouseArea

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.focus({ workspace = "empty" })'])
            hoverEnabled: true
        }

    }

}
