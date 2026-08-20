import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Core

// Bar button for Proton VPN.
//
//  - Left click  : opens the server-selection panel below the button.
//  - Right click : toggles the VPN (connect/disconnect).
Item {
    id: root

    required property var service
    property QtObject barWindow: null
    property bool popupOpen: false

    signal opening()

    Layout.preferredWidth: Config.buttonSize
    Layout.preferredHeight: Config.buttonSize
    implicitWidth: Config.buttonSize
    implicitHeight: Config.buttonSize

    function togglePanel() {
        if (root.popupOpen) {
            popupOpen = false
            return
        }
        popupOpen = true
        opening()
    }

    function toggleConnection() {
        root.service.toggle()
    }

    Rectangle {
        id: button

        anchors.fill: parent
        radius: Config.buttonBorderRadius
        color: mouseArea.containsMouse || root.popupOpen ? Config.backgroundHovered : "transparent"

        Item {
            id: iconContainer

            anchors.centerIn: parent
            width: Config.buttonSize * 0.7
            height: Config.buttonSize * 0.7

            Image {
                id: maskImage

                anchors.fill: parent
                source: "../../../Assets/vpn-shield.svg"
                sourceSize.width: width
                sourceSize.height: height
                smooth: true
                visible: false
            }

            // Static states: foreground when connected, muted when disconnected
            Rectangle {
                id: fgColor

                anchors.fill: parent
                color: root.service.connected ? Config.foreground : Config.foregroundSecondary
                visible: false
            }

            OpacityMask {
                anchors.fill: parent
                source: fgColor
                maskSource: maskImage
                visible: !root.service.busy
            }

            // Shimmer loading state (mirrors Sink.qml skeleton)
            Item {
                id: shimmerContainer

                anchors.fill: parent
                clip: true
                visible: root.service.busy

                Item {
                    id: shimmerSource

                    anchors.fill: parent
                    clip: true
                    visible: false

                    Rectangle {
                        anchors.fill: parent
                        color: Config.hexWithAlpha(Config.foreground, "66")
                    }

                    Item {
                        id: shimmerBand

                        width: shimmerSource.width * 1.8
                        height: shimmerSource.height * 1.8

                        LinearGradient {
                            anchors.fill: parent
                            start: Qt.point(0, 0)
                            end: Qt.point(parent.width, parent.height)
                            gradient: Gradient {
                                GradientStop {
                                    position: 0
                                    color: "transparent"
                                }
                                GradientStop {
                                    position: 0.5
                                    color: Config.foreground
                                }
                                GradientStop {
                                    position: 1
                                    color: "transparent"
                                }
                            }
                        }

                        ParallelAnimation {
                            running: root.service.busy
                            loops: Animation.Infinite

                            NumberAnimation {
                                target: shimmerBand
                                property: "x"
                                from: -shimmerBand.width
                                to: shimmerSource.width
                                duration: 1170
                                easing.type: Easing.Linear
                            }

                            NumberAnimation {
                                target: shimmerBand
                                property: "y"
                                from: -shimmerBand.height
                                to: shimmerSource.height
                                duration: 1170
                                easing.type: Easing.Linear
                            }
                        }
                    }
                }

                OpacityMask {
                    anchors.fill: parent
                    source: shimmerSource
                    maskSource: maskImage
                }
            }
        }

        MouseArea {
            id: mouseArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton)
                    root.toggleConnection()
                else
                    root.togglePanel()
            }
        }
    }

    // --- Popup panel ---------------------------------------------------------

    LazyLoader {
        id: popupLoader

        active: root.popupOpen || item !== null

        PopupWindow {
            id: popup

            visible: root.popupOpen
            anchor.window: root.barWindow
            color: "transparent"
            implicitWidth: panel.panelWidth
            implicitHeight: Math.min(
                panel.desiredHeight,
                Math.max(
                    Config.buttonSize * 6,
                    (root.barWindow && root.barWindow.screen ? root.barWindow.screen.height : 1080)
                        - anchor.rect.y - Config.gapsOut))

            onVisibleChanged: {
                if (!visible && root.popupOpen)
                    root.popupOpen = false
            }

            Component.onCompleted: {
                if (!root.barWindow)
                    return
                var position = root.mapToItem(root.barWindow.contentItem, 0, 0)
                anchor.rect.x = position.x + root.width - popup.width
                anchor.rect.y = position.y + root.height + Config.gapsOut + Config.borderSize
            }

            VpnPanel {
                id: panel
                anchors.fill: parent
                service: root.service
                onDismissed: root.popupOpen = false
            }
        }
    }

    HyprlandFocusGrab {
        id: focusGrab

        active: root.popupOpen && popupLoader.item !== null
        windows: popupLoader.item ? (root.barWindow ? [popupLoader.item, root.barWindow] : [popupLoader.item]) : []
        onCleared: root.popupOpen = false
    }
}