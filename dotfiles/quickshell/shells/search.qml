import QtQuick
import Quickshell
import ".."

PanelWindow {
    id: root

    signal dismissed

    exclusiveZone: 0
    color: "transparent"

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    Component.onCompleted: {
        content.forceActiveFocus()
        input.forceActiveFocus()
        input.selectAll()
    }

    FocusScope {
        id: content

        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.dismissed()

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.4)

            MouseArea {
                anchors.fill: parent
                onClicked: root.dismissed()
            }
        }

        Rectangle {
            id: searchBox

            width: parent.width * 0.4
            height: 52
            radius: 12
            color: Config.backgroundColored
            border.color: Config.accent
            border.width: 2
            anchors.centerIn: parent

            TextInput {
                id: input

                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                verticalAlignment: TextInput.AlignVCenter
                color: Config.foreground
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize + 8
                clip: true

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\u{1F50D}  Search..."
                    color: Config.foregroundSecondary
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize + 8
                    visible: parent.text.length === 0
                }
            }
        }
    }
}
