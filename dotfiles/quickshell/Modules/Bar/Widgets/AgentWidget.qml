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
    signal opening()

    readonly property bool listVisible: !root.service.pinsHidden
    readonly property real arrowSlot: Config.buttonSize + Config.gapInner
    property bool arrowsVisible: false

    function scaleForBar(value) {
        if (value <= 0)
            return 0
        return Math.pow(value, 0.66)
    }

    function togglePanel() {
        root.popupVisible = !root.popupVisible
    }

    function clampContent() {
        var maxX = Math.max(0, agentList.contentWidth - agentList.width)
        if (agentList.contentX > maxX)
            agentList.contentX = maxX
    }

    function updateArrows() {
        var freeWidth = agentList.width + root.arrowSlot * 2
        root.arrowsVisible = root.listVisible && agentList.contentWidth > freeWidth + 1
    }

    function shiftList(offset) {
        var maxX = Math.max(0, agentList.contentWidth - agentList.width)
        if (maxX <= 0)
            return
        var atStart = agentList.contentX <= 1
        var atEnd = agentList.contentX >= maxX - 1
        if (offset > 0 && atEnd) {
            agentList.contentX = 0
            return
        }
        if (offset < 0 && atStart) {
            agentList.contentX = maxX
            return
        }
        var target = agentList.contentX + offset * Math.max(agentList.width * 0.8, Config.buttonSize * 4)
        agentList.contentX = Math.max(0, Math.min(maxX, target))
    }

    implicitWidth: Math.max(Math.round(Config.buttonSize * 1.55), dashboardButton.width + Config.gapInner * 2)
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

    RowLayout {
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

        Rectangle {
            id: arrowLeft

            width: Config.buttonSize
            height: Config.buttonSize
            visible: root.listVisible && root.arrowsVisible
            radius: Config.buttonBorderRadius
            color: arrowLeftMouse.containsMouse ? Config.backgroundHovered : 'transparent'

            Text {
                anchors.centerIn: parent
                text: '<'
                color: Config.foreground
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                font.weight: Font.Bold
            }

            MouseArea {
                id: arrowLeftMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.shiftList(-1)
            }
        }

        Item {
            id: listArea

            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredHeight: Config.buttonSize
            visible: root.listVisible
            clip: true

            ListView {
                id: agentList

                anchors.fill: parent
                orientation: ListView.Horizontal
                clip: true
                interactive: false
                boundsBehavior: Flickable.StopAtBounds
                spacing: Config.gapInner
                model: root.listVisible ? root.service.pinnedAgents : []

                Behavior on contentX {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                onContentWidthChanged: {
                    root.clampContent()
                    root.updateArrows()
                }
                onWidthChanged: {
                    root.clampContent()
                    root.updateArrows()
                }

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
                    color: pinChip.warningFlash || pinChip.active ? Config.foreground : (pinChip.pendingStyle ? Config.backgroundColoredSecondary : (chipMouse.containsMouse ? Config.backgroundHovered : 'transparent'))

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Config.gapInner
                        anchors.rightMargin: Config.gapInner
                        spacing: Config.gapInner

                        AgentStatus {
                            Layout.preferredWidth: Config.buttonSize * 0.7
                            Layout.preferredHeight: Config.buttonSize
                            state: pinChip.modelData.state
                            fillColor: pinChip.warningFlash || pinChip.active ? Config.backgroundColored : Config.foreground
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
                            color: pinChip.warningFlash || pinChip.active ? Config.backgroundColored : Config.foreground
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
                            color: pinChip.warningFlash || pinChip.active ? Config.backgroundColored : Config.foreground
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

                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: wheel => {
                    var maxX = Math.max(0, agentList.contentWidth - agentList.width)
                    if (maxX <= 0)
                        return
                    var delta = wheel.angleDelta.y + wheel.angleDelta.x
                    agentList.contentX = Math.max(0, Math.min(maxX, agentList.contentX - delta))
                }
            }
        }

        Rectangle {
            id: arrowRight

            width: Config.buttonSize
            height: Config.buttonSize
            visible: root.listVisible && root.arrowsVisible
            radius: Config.buttonBorderRadius
            color: arrowRightMouse.containsMouse ? Config.backgroundHovered : 'transparent'

            Text {
                anchors.centerIn: parent
                text: '>'
                color: Config.foreground
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                font.weight: Font.Bold
            }

            MouseArea {
                id: arrowRightMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.shiftList(1)
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
