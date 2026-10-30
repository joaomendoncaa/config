import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Core

Rectangle {
    id: root

    property QtObject barWindow: null
    property var notificationService: null
    property bool popupOpen: false

    signal toggle()
    signal opening()

    Layout.preferredWidth: Config.buttonSize
    Layout.preferredHeight: Config.buttonSize
    radius: Config.buttonBorderRadius
    color: mouseArea.containsMouse || popupOpen ? Config.backgroundHovered : "transparent"

    readonly property int pendingCount: notificationService ? notificationService.pendingModel.count : 0
    readonly property bool dnd: notificationService ? notificationService.doNotDisturb : false

    readonly property string iconSource: {
        if (dnd) return "../../Assets/notifs-muted.svg"
        if (pendingCount > 0) return "../../Assets/notifs-dirty.svg"
        return "../../Assets/notifs.svg"
    }

    Item {
        id: iconContainer
        anchors.centerIn: parent
        width: Config.buttonSize * 0.7
        height: Config.buttonSize * 0.7

        Image {
            id: maskImage
            anchors.fill: parent
            source: root.iconSource
            sourceSize.width: width
            sourceSize.height: height
            smooth: true
            visible: false
        }

        Rectangle {
            id: fgColor
            anchors.fill: parent
            color: Config.foreground
            visible: false
        }

        OpacityMask {
            anchors.fill: parent
            source: fgColor
            maskSource: maskImage
        }
    }

    onPopupOpenChanged: {
        if (popupOpen && root.notificationService) {
            root.opening()
            root.notificationService.popupsBlocked = true
            root.notificationService.clearPopupsSoft()
        } else {
            if (root.notificationService) root.notificationService.popupsBlocked = false
        }
    }

    Connections {
        target: root.notificationService
        ignoreUnknownSignals: true
        function onHistoryOpenRequested() {
            root.popupOpen = true
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                if (notificationService) notificationService.setDoNotDisturb(!dnd)
            } else {
                root.popupOpen = !root.popupOpen
            }
        }
    }

    LazyLoader {
        id: popupLoader
        active: root.popupOpen || item !== null

        PopupWindow {
            id: popup
            visible: root.popupOpen
            anchor.window: root.barWindow
            color: "transparent"
            implicitWidth: 480

            onVisibleChanged: {
                if (!visible && root.popupOpen)
                    root.popupOpen = false
            }

            Component.onCompleted: {
                if (root.barWindow) {
                    var pos = root.mapToItem(root.barWindow.contentItem, 0, 0)
                    anchor.rect.x = pos.x + root.width + Config.gapInner + Config.buttonSize - popup.width
                    anchor.rect.y = pos.y + root.height + Config.gapsOut + Config.borderSize

                    var globalPos = root.mapToItem(null, 0, 0)
                    var popupTop = globalPos.y + root.height + Config.gapsOut + Config.borderSize
                    var screenH = root.barWindow.screen ? root.barWindow.screen.height : 1080
                    // ponytail: overshoot the edge; xdg popup constraint margins leave a hairline per compositor
                    popup.implicitHeight = screenH - popupTop + 12
                }
            }

            Keys.onEscapePressed: root.popupOpen = false

            Item {
                id: notifWrapper

                anchors.fill: parent

                MouseArea {
                    anchors.fill: parent
                    onClicked: notifCenter.forceActiveFocus()
                }

                NotificationCenter {
                    id: notifCenter
                    anchors.fill: parent
                    notificationService: root.notificationService
                    popupOpen: true

                    onDismissed: root.popupOpen = false
                }
            }
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: root.popupOpen && popupLoader.item !== null
        windows: popupLoader.item ? (root.barWindow ? [popupLoader.item, root.barWindow] : [popupLoader.item]) : []
        onCleared: {
            if (root.popupOpen)
                root.popupOpen = false
        }
    }
}
