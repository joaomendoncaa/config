import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Core

Item {
    id: root

    required property var service
    property QtObject barWindow: null
    property bool popupOpen: false
    property int carouselStart: 0
    property string expandedMint: ''

    signal opening()

    readonly property var visiblePins: {
        if (root.service.pinsHidden)
            return []
        var pins = service.pinnedTokens || []
        if (pins.length <= 2)
            return pins
        var start = ((carouselStart % pins.length) + pins.length) % pins.length
        return [pins[start], pins[(start + 1) % pins.length]]
    }

    function shiftPins(offset) {
        var count = service.pinnedTokens.length
        if (count > 2)
            carouselStart = (carouselStart + offset + count) % count
    }

    function togglePanel() {
        if (popupOpen) {
            popupOpen = false
            return
        }

        popupOpen = true
        opening()
    }

    Layout.preferredHeight: Config.buttonSize
    Layout.preferredWidth: content.implicitWidth
    implicitWidth: content.implicitWidth
    implicitHeight: Config.buttonSize

    Connections {
        target: root.service
        function onPinnedTokensChanged() {
            if (root.service.pinnedTokens.length === 0)
                root.carouselStart = 0
            else
                root.carouselStart %= root.service.pinnedTokens.length
        }
        function onWatchlistChanged() {
            if (root.service.watchlist.indexOf(root.expandedMint) === -1)
                root.expandedMint = ''
        }
    }

    Row {
        id: content
        anchors.fill: parent
        spacing: Config.gapInner

        Repeater {
            model: root.visiblePins

            delegate: Rectangle {
                id: pinChip
                required property string modelData
                readonly property var tokenData: root.service.token(modelData) || {}

                width: chipRow.implicitWidth + Config.gapInner * 2
                height: Config.buttonSize
                radius: Config.buttonBorderRadius
                color: 'transparent'

                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: Config.gapInner

                    Text {
                        height: Config.buttonSize
                        verticalAlignment: Text.AlignVCenter
                        text: pinChip.tokenData.symbol || pinChip.modelData.substring(0, 5)
                        color: Config.foreground
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize - 2
                        font.weight: Font.Bold
                    }

                    Text {
                        height: Config.buttonSize
                        verticalAlignment: Text.AlignVCenter
                        text: '⬥'
                        color: Config.foreground
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize - 2
                        font.weight: Font.Bold
                    }

                    Text {
                        height: Config.buttonSize
                        verticalAlignment: Text.AlignVCenter
                        text: '$' + (root.service.showsMarketCap(pinChip.modelData) ? root.service.compactNumber(pinChip.tokenData.marketCap) : root.service.prettyPrice(pinChip.tokenData.usdPrice))
                        color: Config.foreground
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize - 2
                        font.weight: Font.Bold

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.service.toggleMarketCap(pinChip.modelData)
                        }
                    }

                }
            }
        }

        CarouselButton {
            visible: !root.service.pinsHidden && root.service.pinnedTokens.length > 2
            text: '>'
            onClicked: root.shiftPins(1)
        }

        Rectangle {
            id: logoButton
            width: Config.buttonSize
            height: Config.buttonSize
            radius: Config.buttonBorderRadius
            color: logoMouse.containsMouse || root.popupOpen ? Config.backgroundHovered : 'transparent'

            Image {
                id: logoMask
                anchors.centerIn: parent
                width: Config.buttonSize * 0.78
                height: width
                source: '../../../Assets/solana-logo.svg'
                sourceSize.width: width
                sourceSize.height: height
                visible: false
            }

            Rectangle {
                id: logoColor
                anchors.fill: logoMask
                color: Config.foreground
                visible: false
            }

            OpacityMask {
                anchors.fill: logoMask
                source: logoColor
                maskSource: logoMask
            }

            MouseArea {
                id: logoMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.togglePanel()
            }
        }
    }

    LazyLoader {
        id: popupLoader
        active: root.popupOpen || item !== null

        PopupWindow {
            id: popup

            function focusSearch() {
                panel.focusSearch()
            }

            visible: root.popupOpen
            anchor.window: root.barWindow
            color: 'transparent'
            implicitWidth: panel.panelWidth
            implicitHeight: Math.min(panel.desiredHeight, Math.max(Config.buttonSize * 6, (root.barWindow && root.barWindow.screen ? root.barWindow.screen.height : 1080) - anchor.rect.y - Config.gapsOut))

            onVisibleChanged: {
                if (!visible && root.popupOpen)
                    root.popupOpen = false
                if (visible)
                    Qt.callLater(popup.focusSearch)
            }

            Component.onCompleted: {
                if (!root.barWindow)
                    return
                var position = root.mapToItem(root.barWindow.contentItem, 0, 0)
                anchor.rect.x = position.x + root.width - popup.width
                anchor.rect.y = position.y + root.height + Config.gapsOut + Config.borderSize
                Qt.callLater(popup.focusSearch)
            }

            SolanaPanel {
                id: panel
                anchors.fill: parent
                service: root.service
                expandedMint: root.expandedMint
                onDismissed: root.popupOpen = false
                onExpansionRequested: mint => root.expandedMint = mint
            }
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: root.popupOpen && popupLoader.item !== null
        windows: popupLoader.item ? (root.barWindow ? [popupLoader.item, root.barWindow] : [popupLoader.item]) : []
        onActiveChanged: {
            if (active && popupLoader.item)
                Qt.callLater(popupLoader.item.focusSearch)
        }
        onCleared: root.popupOpen = false
    }

    component CarouselButton: Rectangle {
        id: carouselButton
        property string text: ''
        signal clicked()
        width: Config.buttonSize * 0.7
        height: Config.buttonSize
        radius: Config.buttonBorderRadius
        color: carouselMouse.containsMouse ? Config.backgroundHovered : 'transparent'

        Text {
            anchors.centerIn: parent
            text: carouselButton.text
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
            onClicked: carouselButton.clicked()
        }
    }
}
