import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.Core

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

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    visible: parent.text.length === 0

                    Item {
                        width: Config.fontSize + 8
                        height: Config.fontSize + 8
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            id: placeholderMask

                            anchors.fill: parent
                            source: "../../Assets/search.svg"
                            sourceSize.width: width
                            sourceSize.height: height
                            smooth: true
                            visible: false
                        }

                        Rectangle {
                            id: placeholderFg

                            anchors.fill: parent
                            color: Config.foregroundSecondary
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: placeholderFg
                            maskSource: placeholderMask
                        }

                    }

                    Text {
                        text: "Search..."
                        color: Config.foregroundSecondary
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize + 8
                    }

                }
            }
        }
    }
}
