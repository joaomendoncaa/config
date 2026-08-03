import Qt5Compat.GraphicalEffects
import QtQuick
import qs.Core

Rectangle {
    id: root

    required property var service
    property string expandedMint: ""
    readonly property int panelWidth: Math.round(Config.buttonSize * 18)
    readonly property int searchHeight: Config.buttonSize + Config.shellPadding + Config.gapInner
    readonly property int maximumListHeight: Math.round(Config.buttonSize * 16)
    readonly property int tokenRowHeight: Math.round(Config.buttonSize * 1.5)
    readonly property int tokenDetailsHeight: Math.round(Config.buttonSize * 6.5)
    readonly property bool searchMode: searchInput.text.trim().length >= 2
    readonly property int visibleTokenCount: searchMode ? service.searchResults.length : service.watchlist.length
    readonly property string statusMessage: {
        if (service.searchLoading)
            return 'Searching...'
        if (searchMode)
            return service.searchError
        if (service.watchlist.length === 0)
            return 'Search for a token to build your watchlist'
        return service.dataError || ''
    }
    readonly property int statusHeight: statusMessage.length > 0 ? Math.round(Config.buttonSize * 1.7) : 0
    readonly property int listContentHeight: visibleTokenCount * tokenRowHeight + (!searchMode && visibleTokenCount > 0 ? tokenDetailsHeight : 0) + statusHeight
    readonly property int desiredHeight: searchHeight + Math.min(maximumListHeight, Math.max(tokenRowHeight, listContentHeight)) + Config.shellPadding

    signal dismissed()
    signal expansionRequested(string mint)

    function focusSearch() {
        searchInput.forceActiveFocus()
    }

    color: Config.backgroundColored
    radius: Config.borderRadius
    clip: true
    focus: true
    Keys.onEscapePressed: root.dismissed()

    Rectangle {
        id: searchArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.searchHeight
        color: Config.backgroundColored

        Rectangle {
            id: inputBackground
            anchors.left: parent.left
            anchors.right: searchButton.left
            anchors.top: parent.top
            anchors.topMargin: Config.shellPadding
            anchors.leftMargin: Config.shellPadding
            anchors.rightMargin: Config.gapInner
            height: Config.buttonSize
            radius: Math.max(1, Math.round(Config.buttonBorderRadius / 2))
            color: Config.backgroundColoredTertiary

            TextInput {
                id: searchInput
                anchors.fill: parent
                anchors.leftMargin: Config.shellPadding
                anchors.rightMargin: Config.shellPadding
                verticalAlignment: TextInput.AlignVCenter
                color: Config.foreground
                selectionColor: Config.accent
                selectedTextColor: Config.foregroundSelected
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                clip: true

                onTextChanged: searchDebounce.restart()
                Keys.onEscapePressed: root.dismissed()
            }

            Text {
                visible: searchInput.text.length === 0
                anchors.fill: parent
                anchors.leftMargin: Config.shellPadding
                verticalAlignment: Text.AlignVCenter
                text: 'Search Solana tokens'
                color: Config.foregroundSecondary
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
            }
        }

        Rectangle {
            id: searchButton
            anchors.right: parent.right
            anchors.rightMargin: Config.shellPadding
            anchors.top: parent.top
            anchors.topMargin: Config.shellPadding
            width: Config.buttonSize
            height: Config.buttonSize
            radius: Math.max(1, Math.round(Config.buttonBorderRadius / 2))
            color: Config.foreground

            Image {
                id: searchMask
                anchors.centerIn: parent
                width: Config.buttonSize * 0.7
                height: width
                source: '../../../Assets/search.svg'
                sourceSize.width: width
                sourceSize.height: height
                visible: false
            }

            Rectangle {
                id: searchColor
                anchors.fill: searchMask
                color: Config.foregroundSelected
                visible: false
            }

            OpacityMask {
                anchors.fill: searchMask
                source: searchColor
                maskSource: searchMask
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    searchDebounce.stop()
                    root.service.search(searchInput.text)
                }
            }
        }
    }

    ListView {
        id: tokenList
        anchors.top: searchArea.bottom
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Config.shellPadding
        anchors.left: parent.left
        anchors.right: parent.right
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: {
            if (root.searchMode)
                return root.service.searchResults
            return root.service.watchlist.map(function(mint) { return { mint: mint } })
        }

        delegate: SolanaTokenRow {
            width: tokenList.width
            service: root.service
            searchResult: root.searchMode
            expanded: !searchResult && root.expandedMint === mint
            onToggleExpanded: root.expansionRequested(root.expandedMint === mint ? '' : mint)
            onDismissRequested: root.dismissed()
            onTokenAdded: {
                searchDebounce.stop()
                searchInput.clear()
                root.service.search('')
                searchInput.forceActiveFocus()
            }
        }

        footer: Item {
            width: tokenList.width
            height: root.statusHeight

            Text {
                anchors.centerIn: parent
                visible: text.length > 0
                text: root.statusMessage
                color: Config.foregroundSecondary
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
            }
        }
    }

    Timer {
        id: searchDebounce
        interval: 350
        onTriggered: root.service.search(searchInput.text)
    }

    Component.onCompleted: Qt.callLater(root.focusSearch)
}
