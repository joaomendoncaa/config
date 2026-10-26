import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core

Rectangle {
    id: root

    required property var service
    required property var modelData
    property bool searchResult: false
    property bool expanded: false
    property bool deleteArmed: false

    signal toggleExpanded()
    signal dismissRequested()
    signal tokenAdded()

    readonly property var tokenInfo: modelData || ({})
    readonly property string mint: tokenInfo.mint || ''
    readonly property var details: {
        if (searchResult)
            return tokenInfo || {}
        return service && mint ? service.token(mint) || {} : {}
    }
    readonly property string shortMint: mint.length > 12 ? mint.substring(0, 4) + '…' + mint.substring(mint.length - 4) : mint
    readonly property int rowHeight: Math.round(Config.buttonSize * 2)
    readonly property int detailsHeight: Math.round(Config.buttonSize * 6.5)

    color: root.deleteArmed ? Config.backgroundColoredSecondary : (expanded && !searchResult ? Config.backgroundColoredSecondary : 'transparent')

    implicitHeight: rowHeight + (expanded && !searchResult ? detailsHeight : 0)

    Component.onCompleted: {
        if (!searchResult && service)
            service.requestHistory(mint)
    }

    Column {
        anchors.fill: parent
        visible: !root.deleteArmed
        spacing: 0

        Item {
            width: parent.width
            height: root.rowHeight

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Config.shellPadding
                anchors.rightMargin: Config.shellPadding
                spacing: Config.gapInner

                SolanaSparkline {
                    visible: !root.searchResult && !root.expanded
                    Layout.preferredWidth: Math.round(Config.buttonSize * 2.5)
                    Layout.preferredHeight: Config.buttonSize
                    values: root.details.history || []
                }

                Rectangle {
                    Layout.preferredWidth: Math.round(Config.buttonSize * 0.9)
                    Layout.preferredHeight: Math.round(Config.buttonSize * 0.9)
                    radius: width / 2
                    color: Config.backgroundColoredTertiary
                    clip: true

                    Text {
                        anchors.centerIn: parent
                        text: (root.details.symbol || root.mint).substring(0, 1)
                        color: Config.foregroundSecondary
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize - 4
                        font.weight: Font.Bold
                    }

                    Image {
                        id: tokenIcon
                        anchors.fill: parent
                        source: root.details.iconUrl || ''
                        asynchronous: true
                        cache: true
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: width
                        sourceSize.height: height
                        visible: false
                    }

                    Rectangle {
                        id: tokenIconMask
                        anchors.fill: parent
                        radius: width / 2
                        color: 'white'
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        visible: (root.details.iconUrl || '').length > 0
                        source: tokenIcon
                        maskSource: tokenIconMask
                        cached: true
                    }
                }

                Column {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 0

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: root.details.symbol || root.details.name || root.mint.substring(0, 6)
                        color: Config.foreground
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize
                        font.weight: Font.Bold
                    }

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: root.shortMint
                        color: Config.foregroundSecondary
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize - 4

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.clipboardText = root.mint
                        }
                    }
                }

                Column {
                    Layout.preferredWidth: Math.round(Config.buttonSize * 6.4)
                    spacing: 0

                    Text {
                        width: parent.width
                        visible: root.searchResult || !root.expanded
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                        text: '$' + (!root.searchResult && root.service.showsMarketCap(root.mint) ? root.service.compactNumber(root.details.marketCap) : root.service.prettyPrice(root.details.usdPrice))
                        color: Config.foreground
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize
                        font.weight: Font.Bold

                        MouseArea {
                            anchors.fill: parent
                            enabled: !root.searchResult && !root.expanded
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.service.toggleMarketCap(root.mint)
                        }
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                        text: 'Liq ' + root.service.compactUsd(root.details.liquidity) + '  Vol ' + root.service.compactUsd(root.details.volume24h)
                        color: Config.foregroundSecondary
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize - 5
                    }
                }

                Row {
                    visible: root.searchResult
                    Layout.preferredWidth: implicitWidth
                    spacing: Config.gapInner

                    ActionButton {
                        iconSource: '../../../Assets/solana-open.svg'
                        onClicked: root.openExternal()
                    }

                    Rectangle {
                        width: Math.round(Config.buttonSize * 1.8)
                        height: Config.buttonSize
                        radius: Math.max(1, Math.round(Config.buttonBorderRadius / 2))
                        color: root.service.isWatchlisted(root.mint) ? Config.backgroundColoredTertiary : Config.foreground

                        Text {
                            anchors.centerIn: parent
                            text: root.service.isWatchlisted(root.mint) ? '\uf00c' : 'Add'
                            color: root.service.isWatchlisted(root.mint) ? Config.foregroundSecondary : Config.foregroundSelected
                            font.family: Config.fontFamily
                            font.pixelSize: Config.fontSize - 2
                            font.weight: Font.Bold
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !root.service.isWatchlisted(root.mint)
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                root.service.addSearchResult(root.tokenInfo)
                                root.tokenAdded()
                            }
                        }
                    }
                }

                Row {
                    visible: !root.searchResult
                    Layout.preferredWidth: implicitWidth
                    spacing: Config.gapInner

                    ActionButton {
                        iconSource: '../../../Assets/solana-open.svg'
                        onClicked: root.openExternal()
                    }

                    ActionButton {
                        iconSource: '../../../Assets/solana-delete.svg'
                        onClicked: root.deleteArmed = true
                    }

                    ActionButton {
                        iconSource: '../../../Assets/solana-pin.svg'
                        background: root.service.isPinned(root.mint) ? Config.foreground : 'transparent'
                        foreground: root.service.isPinned(root.mint) ? Config.backgroundColored : Config.foreground
                        opacity: root.service.isPinned(root.mint) ? 1 : 0.45
                        onClicked: root.service.togglePin(root.mint)
                    }

                    ActionButton {
                        text: root.expanded ? '\uf077' : '\uf078'
                        onClicked: root.toggleExpanded()
                    }
                }
            }
        }

        Rectangle {
            visible: root.expanded && !root.searchResult
            width: parent.width
            height: root.detailsHeight
            color: 'transparent'

            Column {
                anchors.fill: parent
                anchors.margins: Config.shellPadding
                spacing: Config.gapInner

                SolanaSparkline {
                    width: parent.width
                    height: parent.height - metrics.height - parent.spacing
                    values: root.details.history || []
                }

                Row {
                    id: metrics
                    width: parent.width
                    height: Config.buttonSize * 1.8
                    spacing: Config.gapInner

                    Metric {
                        width: (metrics.width - metrics.spacing * 4) / 5
                        label: 'PRICE'
                        value: '$' + root.service.prettyPrice(root.details.usdPrice)
                    }

                    Metric {
                        width: (metrics.width - metrics.spacing * 4) / 5
                        label: '24H'
                        value: (Number(root.details.change24h) > 0 ? '+' : '') + Number(root.details.change24h || 0).toFixed(2) + '%'
                        valueColor: Number(root.details.change24h) < 0 ? Config.foregroundSecondary : Config.foreground
                    }

                    Metric {
                        width: (metrics.width - metrics.spacing * 4) / 5
                        label: 'MCAP'
                        value: root.service.compactUsd(root.details.marketCap)
                    }

                    Metric {
                        width: (metrics.width - metrics.spacing * 4) / 5
                        label: 'LIQ'
                        value: root.service.compactUsd(root.details.liquidity)
                    }

                    Metric {
                        width: (metrics.width - metrics.spacing * 4) / 5
                        label: 'VOL'
                        value: root.service.compactUsd(root.details.volume24h)
                    }
                }
            }
        }
    }

    function openExternal() {
        if (root.mint) {
            Quickshell.execDetached(['xdg-open', 'https://app.jtx.com/?mint=' + root.mint])
            root.dismissRequested()
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.deleteArmed
        color: Config.backgroundColoredSecondary
        z: 2

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Config.shellPadding
            anchors.rightMargin: Config.shellPadding
            spacing: Config.gapInner

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                elide: Text.ElideRight
                text: 'Are you sure you want to delete ' + (root.details.symbol || root.shortMint) + '?'
                color: Config.foreground
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize - 2
                font.weight: Font.Bold
            }

            Row {
                Layout.preferredWidth: implicitWidth
                spacing: Config.gapInner

                ConfirmButton {
                    text: 'Cancel'
                    background: Config.backgroundColoredTertiary
                    foreground: Config.foreground
                    onClicked: root.deleteArmed = false
                }

                ConfirmButton {
                    text: 'Delete'
                    background: Config.accent
                    foreground: Config.foregroundSelected
                    onClicked: root.service.removeToken(root.mint)
                }
            }
        }
    }

    component ConfirmButton: Rectangle {
        id: confirmButton
        property string text: ''
        property color background: Config.backgroundColoredTertiary
        property color foreground: Config.foreground
        signal clicked()

        width: Math.round(Config.buttonSize * 2.4)
        height: Config.buttonSize
        radius: Math.max(1, Math.round(Config.buttonBorderRadius / 2))
        color: confirmMouse.containsMouse ? Qt.lighter(confirmButton.background, 1.15) : confirmButton.background

        Text {
            anchors.centerIn: parent
            text: confirmButton.text
            color: confirmButton.foreground
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize - 2
            font.weight: Font.Bold
        }

        MouseArea {
            id: confirmMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: confirmButton.clicked()
        }
    }

    component ActionButton: Rectangle {
        id: action
        property string text: ''
        property string iconSource: ''
        property color background: 'transparent'
        property color foreground: Config.foreground
        signal clicked()
        width: Config.buttonSize
        height: Config.buttonSize
        radius: Math.max(1, Math.round(Config.buttonBorderRadius / 2))
        color: action.background

        Text {
            anchors.centerIn: parent
            visible: action.iconSource.length === 0
            text: action.text
            color: action.foreground
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize
        }

        Image {
            id: actionIconMask
            anchors.centerIn: parent
            width: Config.buttonSize * 0.7
            height: width
            source: action.iconSource
            sourceSize.width: width
            sourceSize.height: height
            visible: false
        }

        Rectangle {
            id: actionIconColor
            anchors.fill: actionIconMask
            color: action.foreground
            visible: false
        }

        OpacityMask {
            anchors.fill: actionIconMask
            visible: action.iconSource.length > 0
            source: actionIconColor
            maskSource: actionIconMask
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.clicked()
        }
    }

    component Metric: Column {
        property string label: ''
        property string value: ''
        property color valueColor: Config.foreground
        spacing: 1

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: parent.label
            color: Config.foregroundSecondary
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize - 4
            font.weight: Font.Bold
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: parent.value
            color: parent.valueColor
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize - 3
            font.weight: Font.Bold
        }
    }
}
