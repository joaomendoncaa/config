import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Core
import "../../../Widgets"

Item {
    id: root

    required property var service
    property QtObject barWindow: null
    property bool popupVisible: false
    property int carouselStart: 0
    signal opening()

    readonly property var visiblePins: {
        if (root.service.pinsHidden)
            return []
        var pins = root.service.pinnedAgents || []
        if (pins.length <= 3)
            return pins
        var start = ((root.carouselStart % pins.length) + pins.length) % pins.length
        return [pins[start], pins[(start + 1) % pins.length], pins[(start + 2) % pins.length]]
    }

    function scaleForBar(value) {
        if (value <= 0)
            return 0
        return Math.pow(value, 0.66)
    }

    function shiftPins(offset) {
        var count = root.service.pinnedAgents.length
        if (count > 3)
            root.carouselStart = (root.carouselStart + offset + count) % count
    }

    function togglePanel() {
        root.popupVisible = !root.popupVisible
    }

    implicitWidth: Math.max(Math.round(Config.buttonSize * 1.55), content.implicitWidth)
    implicitHeight: Config.buttonSize
    Layout.fillWidth: true
    Layout.minimumWidth: Math.round(Config.buttonSize * 1.55)
    Layout.preferredWidth: root.implicitWidth
    Layout.preferredHeight: Config.buttonSize

    onPopupVisibleChanged: {
        root.service.panelOpen = root.popupVisible
        if (root.popupVisible)
            root.opening()
    }

    Connections {
        target: root.service

        function onPinnedAgentIdsChanged() {
            var count = root.service.pinnedAgents.length
            root.carouselStart = count > 0 ? root.carouselStart % count : 0
        }

        function onAgentsChanged() {
            var count = root.service.pinnedAgents.length
            root.carouselStart = count > 0 ? root.carouselStart % count : 0
        }
    }

    MouseArea {
        id: wheelScroller
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            if (root.service.pinnedAgents.length > 3)
                root.shiftPins(wheel.angleDelta.y > 0 ? -1 : 1)
        }
    }

    Row {
        id: content
        anchors.fill: parent
        spacing: Config.gapInner

        Rectangle {
            id: dashboardButton
            width: Math.round(Config.buttonSize * 1.55)
            height: Config.buttonSize
            radius: Config.buttonBorderRadius
            color: dashboardMouse.containsMouse || root.popupVisible ? Config.backgroundHovered : 'transparent'

            Row {
                anchors.centerIn: parent
                spacing: Config.gapInner

                Item {
                    width: Config.buttonSize * 0.7
                    height: width
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: logoMask
                        anchors.fill: parent
                        source: root.service.iconSource
                        sourceSize.width: width
                        sourceSize.height: height
                        visible: false
                    }

                    Rectangle {
                        id: logoColor
                        anchors.fill: parent
                        color: Config.foreground
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: logoColor
                        maskSource: logoMask
                    }
                }

                Rectangle {
                    width: 8
                    height: Config.buttonSize * 0.55
                    visible: root.service.usageSupported
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 2
                    color: Config.foregroundSecondary
                    opacity: root.service.usageAvailable ? 1 : 0.35

                    Rectangle {
                        visible: root.service.usageAvailable
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottomMargin: 2
                        width: parent.width - 4
                        height: (parent.height - 4) * root.scaleForBar(root.service.primaryUsageRemaining)
                        radius: 1
                        color: Config.foreground
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !root.service.usageLoading && !root.service.usageAvailable
                        text: '?'
                        color: Config.foreground
                        font.family: Config.fontFamily
                        font.pixelSize: 8
                        font.weight: Font.Bold
                    }
                }
            }

            MouseArea {
                id: dashboardMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton)
                        root.service.togglePinsHidden()
                    else
                        root.togglePanel()
                }
            }
        }

        Repeater {
            model: root.visiblePins

            delegate: Rectangle {
                id: pinChip
                required property var modelData
                readonly property bool pendingStyle: pinChip.modelData.state === 'pending'
                readonly property bool warningFlash: pinChip.modelData.state === 'blocked' && root.service.blockedWarningFrame
                readonly property bool active: root.service.activeAgentId === pinChip.modelData.id
                readonly property real desiredWidth: Config.gapInner * 4 + Config.buttonSize * 0.7 + Math.min(repoText.implicitWidth, Config.buttonSize * 3.5) + Math.min(titleText.implicitWidth, Config.buttonSize * 5)

                width: Math.max(Config.buttonSize * 4, Math.min(Config.buttonSize * 9, desiredWidth))
                height: Config.buttonSize
                radius: Config.buttonBorderRadius
                color: pinChip.warningFlash || pinChip.pendingStyle ? Config.foreground : (chipMouse.containsMouse ? Config.backgroundHovered : 'transparent')

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Config.gapInner
                    anchors.rightMargin: Config.gapInner
                    spacing: Config.gapInner

                    AgentStatus {
                        Layout.preferredWidth: Config.buttonSize * 0.7
                        Layout.preferredHeight: Config.buttonSize
                        state: pinChip.modelData.state
                        fillColor: pinChip.warningFlash || pinChip.pendingStyle ? Config.backgroundColored : Config.foreground
                        fontFamily: Config.fontFamily
                        fontSize: Config.fontSize
                        runningFrame: root.service.runningFrame
                        blockedFrame: root.service.blockedFrame
                    }

                    Text {
                        id: repoText
                        Layout.maximumWidth: Config.buttonSize * 3.5
                        elide: Text.ElideRight
                        text: pinChip.modelData.repo
                        textFormat: Text.PlainText
                        color: pinChip.warningFlash || pinChip.pendingStyle ? Config.backgroundColored : Config.foreground
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize
                        font.weight: Font.Bold
                    }

                    Text {
                        id: titleText
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        elide: Text.ElideRight
                        text: pinChip.modelData.title
                        textFormat: Text.PlainText
                        color: pinChip.warningFlash || pinChip.pendingStyle ? Config.backgroundColored : Config.foreground
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize
                    }
                }

                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.popupVisible = false
                        root.service.focusAgent(pinChip.modelData.id)
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 3
                    width: 4
                    height: 4
                    radius: 2
                    visible: pinChip.active
                    color: Config.foreground
                }
            }
        }

        Rectangle {
            width: Config.buttonSize * 0.7
            height: Config.buttonSize
            visible: !root.service.pinsHidden && root.service.pinnedAgents.length > 3
            radius: Config.buttonBorderRadius
            color: carouselMouse.containsMouse ? Config.backgroundHovered : 'transparent'

            Text {
                anchors.centerIn: parent
                text: '>'
                color: Config.foreground
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                font.weight: Font.Bold
            }

            MouseArea {
                id: carouselMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.shiftPins(1)
            }
        }
    }

    LazyLoader {
        id: popupLoader
        active: root.popupVisible || item !== null

        PopupWindow {
            id: popup

            function positionPanel() {
                if (!root.barWindow)
                    return
                var position = root.mapToItem(root.barWindow.contentItem, 0, 0)
                var screenWidth = root.barWindow.screen ? root.barWindow.screen.width : 1920
                anchor.rect.x = Math.max(Config.gapsOut, Math.min(position.x, screenWidth - width - Config.gapsOut))
                anchor.rect.y = position.y + root.height + Config.gapsOut + Config.borderSize
            }

            visible: root.popupVisible
            anchor.window: root.barWindow
            color: 'transparent'
            implicitWidth: Math.min(panel.panelWidth, (root.barWindow && root.barWindow.screen ? root.barWindow.screen.width : 1920) - Config.gapsOut * 2)
            implicitHeight: Math.min(panel.desiredHeight, Math.max(Config.buttonSize * 8, (root.barWindow && root.barWindow.screen ? root.barWindow.screen.height : 1080) - anchor.rect.y - Config.gapsOut))

            onVisibleChanged: {
                if (!visible && root.popupVisible)
                    root.popupVisible = false
                if (visible) {
                    Qt.callLater(popup.positionPanel)
                    Qt.callLater(panel.forceActiveFocus)
                }
            }

            Component.onCompleted: Qt.callLater(popup.positionPanel)

            AgentPanel {
                id: panel
                anchors.fill: parent
                service: root.service
                onDismissed: root.popupVisible = false
            }
        }
    }

    HyprlandFocusGrab {
        active: root.popupVisible && popupLoader.item !== null
        windows: popupLoader.item ? (root.barWindow ? [popupLoader.item, root.barWindow] : [popupLoader.item]) : []
        onCleared: root.popupVisible = false
    }
}
