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
    readonly property int rowHeight: Math.round(Config.buttonSize * 1.5)
    readonly property int detailsHeight: Math.round(Config.buttonSize * 6.5)

    color: expanded && !searchResult ? Config.backgroundColoredSecondary : 'transparent'

    implicitHeight: rowHeight + (expanded && !searchResult ? detailsHeight : 0)

    Component.onCompleted: {
        if (!searchResult && service)
            service.requestHistory(mint)
    }

    Column {
        anchors.fill: parent
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
                    visible: root.details.iconUrl && root.details.iconUrl.length > 0
                    Layout.preferredWidth: Config.buttonSize * 0.7
                    Layout.preferredHeight: Config.buttonSize * 0.7
                    radius: width / 2
                    color: Config.backgroundColoredTertiary
                    clip: false

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
                        source: tokenIcon
                        maskSource: tokenIconMask
                        cached: true
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    elide: Text.ElideRight
                    text: root.details.symbol || root.details.name || root.mint.substring(0, 6)
                    color: Config.foreground
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                    font.weight: Font.Bold
                }

                Text {
                    visible: root.searchResult || !root.expanded
                    Layout.preferredWidth: Math.round(Config.buttonSize * 4.4)
                    Layout.rightMargin: Config.gapInner
                    horizontalAlignment: Text.AlignRight
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

                Row {
                    visible: root.searchResult
                    Layout.preferredWidth: implicitWidth

                    ActionButton {
                        iconSource: '../../../Assets/solana-open.svg'
                        onClicked: root.openExternal()
                    }
                }

                Rectangle {
                    visible: root.searchResult
                    Layout.preferredWidth: Config.buttonSize
                    Layout.preferredHeight: Config.buttonSize
                    radius: Math.max(1, Math.round(Config.buttonBorderRadius / 2))
                    color: root.service.isWatchlisted(root.mint) ? Config.backgroundColoredTertiary : Config.foreground

                    Text {
                        anchors.centerIn: parent
                        text: root.service.isWatchlisted(root.mint) ? '\uf00c' : 'ADD'
                        color: root.service.isWatchlisted(root.mint) ? Config.foregroundSecondary : Config.foregroundSelected
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize
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
                        foreground: root.deleteArmed ? Config.accent : Config.foreground
                        onClicked: {
                            if (root.deleteArmed) {
                                root.service.removeToken(root.mint)
                            } else {
                                root.deleteArmed = true
                                deleteTimer.restart()
                            }
                        }
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
                        width: (metrics.width - metrics.spacing * 2) / 3
                        label: 'PRICE'
                        value: '$' + root.service.prettyPrice(root.details.usdPrice)
                    }

                    Metric {
                        width: (metrics.width - metrics.spacing * 2) / 3
                        label: 'CHANGE'
                        value: (Number(root.details.change24h) > 0 ? '+' : '') + Number(root.details.change24h || 0).toFixed(2) + '%'
                        valueColor: Number(root.details.change24h) < 0 ? Config.foregroundSecondary : Config.foreground
                    }

                    Metric {
                        width: (metrics.width - metrics.spacing * 2) / 3
                        label: 'MARKETCAP'
                        value: root.service.compactNumber(root.details.marketCap)
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

    Timer {
        id: deleteTimer
        interval: 2500
        onTriggered: root.deleteArmed = false
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
            font.pixelSize: Config.fontSize
            font.weight: Font.Bold
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: parent.value
            color: parent.valueColor
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize
            font.weight: Font.Bold
        }
    }
}
