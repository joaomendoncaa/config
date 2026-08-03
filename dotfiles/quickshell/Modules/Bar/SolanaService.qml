import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var watchlist: []
    property var pinnedTokens: []
    property var marketCapDisplayTokens: []
    property var tokenData: ({})
    property var searchResults: []
    property string searchQuery: ""
    property string searchError: ""
    property string dataError: ""
    property bool searchLoading: false
    property bool loaded: false

    property var _storage: ({})
    property var _historyQueue: []
    property var _historyQueued: ({})
    property var _priceQueue: []
    property var _statsQueue: []
    property var _metadataQueue: []
    property string _historyMint: ""
    property string _searchRequest: ""

    function clone(value) {
        return JSON.parse(JSON.stringify(value))
    }

    function token(mint) {
        return root.tokenData[mint] || null
    }

    function isWatchlisted(mint) {
        return root.watchlist.indexOf(mint) !== -1
    }

    function isPinned(mint) {
        return root.pinnedTokens.indexOf(mint) !== -1
    }

    function showsMarketCap(mint) {
        return root.marketCapDisplayTokens.indexOf(mint) !== -1
    }

    function toggleMarketCap(mint) {
        if (!root.isWatchlisted(mint))
            return

        var tokens = root.marketCapDisplayTokens.slice()
        var index = tokens.indexOf(mint)
        if (index === -1)
            tokens.push(mint)
        else
            tokens.splice(index, 1)
        root.marketCapDisplayTokens = tokens
        root.persist()
    }

    function prettyPrice(value) {
        var price = Number(value)
        if (!isFinite(price))
            return '--'
        if (price === 0)
            return '0'
        if (price >= 1000)
            return price.toFixed(2)
        if (price >= 1)
            return price.toFixed(price >= 100 ? 2 : 4).replace(/0+$/, '').replace(/\.$/, '')
        return price.toPrecision(6).replace(/0+$/, '').replace(/\.$/, '')
    }

    function compactNumber(value) {
        var number = Number(value)
        if (!isFinite(number) || number <= 0)
            return '--'
        var units = ['', 'K', 'M', 'B', 'T']
        var unit = 0
        while (number >= 1000 && unit < units.length - 1) {
            number /= 1000
            unit++
        }
        return number.toFixed(number >= 100 ? 0 : number >= 10 ? 1 : 2).replace(/\.0+$/, '') + units[unit]
    }

    function addToken(mint, initialData) {
        if (!mint || root.isWatchlisted(mint))
            return

        var data = root.clone(root.tokenData)
        data[mint] = Object.assign({}, data[mint] || {}, initialData || {})
        root.tokenData = data

        var list = root.watchlist.slice()
        list.push(mint)
        root.watchlist = list
        root.persist()
        root.refreshPrices()
        root.refreshStats()
    }

    function addSearchResult(result) {
        if (!result || !result.mint)
            return

        root.addToken(result.mint, {
            name: result.name || "",
            symbol: result.symbol || "",
            iconUrl: result.iconUrl || "",
            iconUpdatedAt: result.iconUrl ? Date.now() : 0,
            iconCheckedAt: result.iconUrl ? Date.now() : 0,
            usdPrice: result.usdPrice,
            pairAddress: result.pairAddress || "",
            dexUrl: result.dexUrl || "",
            marketCap: result.marketCap,
            change24h: result.change24h
        })
    }

    function removeToken(mint) {
        var watchIndex = root.watchlist.indexOf(mint)
        if (watchIndex === -1)
            return

        var list = root.watchlist.slice()
        list.splice(watchIndex, 1)
        root.watchlist = list

        var pins = root.pinnedTokens.slice()
        var pinIndex = pins.indexOf(mint)
        if (pinIndex !== -1) {
            pins.splice(pinIndex, 1)
            root.pinnedTokens = pins
        }

        var marketCapTokens = root.marketCapDisplayTokens.slice()
        var marketCapIndex = marketCapTokens.indexOf(mint)
        if (marketCapIndex !== -1) {
            marketCapTokens.splice(marketCapIndex, 1)
            root.marketCapDisplayTokens = marketCapTokens
        }

        var data = root.clone(root.tokenData)
        delete data[mint]
        root.tokenData = data
        root.persist()
    }

    function togglePin(mint) {
        if (!root.isWatchlisted(mint))
            return

        var pins = root.pinnedTokens.slice()
        var index = pins.indexOf(mint)
        if (index === -1)
            pins.push(mint)
        else
            pins.splice(index, 1)
        root.pinnedTokens = pins
        root.persist()
    }

    function unpin(mint) {
        var pins = root.pinnedTokens.slice()
        var index = pins.indexOf(mint)
        if (index === -1)
            return
        pins.splice(index, 1)
        root.pinnedTokens = pins
        root.persist()
    }

    function getList() {
        return JSON.stringify(root.watchlist.map(function(mint) {
            return {
                mint: mint,
                pinned: root.isPinned(mint),
                data: root.tokenData[mint] || null
            }
        }))
    }

    function mergeToken(mint, values) {
        if (!mint)
            return
        var data = root.clone(root.tokenData)
        data[mint] = Object.assign({}, data[mint] || {}, values || {})
        root.tokenData = data
    }

    function refreshPrices() {
        if (!root.loaded || root.watchlist.length === 0 || priceFetcher.running)
            return
        root._priceQueue = root._chunks(root.watchlist, 50)
        root._fetchNextPrices()
    }

    function _fetchNextPrices() {
        if (priceFetcher.running || root._priceQueue.length === 0)
            return
        var queue = root._priceQueue.slice()
        var mints = queue.shift()
        root._priceQueue = queue
        priceFetcher.command = ["curl", "-fLsS", "--max-time", "15", "https://api.jup.ag/price/v3?ids=" + mints.join(',')]
        priceFetcher.running = true
    }

    function refreshStats() {
        if (!root.loaded || root.watchlist.length === 0 || statsFetcher.running)
            return
        root._statsQueue = root._chunks(root.watchlist, 30)
        root._fetchNextStats()
    }

    function _fetchNextStats() {
        if (statsFetcher.running || root._statsQueue.length === 0)
            return
        var queue = root._statsQueue.slice()
        var mints = queue.shift()
        root._statsQueue = queue
        statsFetcher.command = ["curl", "-fLsS", "--max-time", "15", "https://api.dexscreener.com/tokens/v1/solana/" + mints.join(',')]
        statsFetcher.running = true
    }

    function _chunks(values, size) {
        var chunks = []
        for (var i = 0; i < values.length; i += size)
            chunks.push(values.slice(i, i + size))
        return chunks
    }

    function refreshMissingIcons() {
        if (metadataFetcher.running)
            return
        var missing = []
        var now = Date.now()
        for (var i = 0; i < root.watchlist.length; i++) {
            var mint = root.watchlist[i]
            var item = root.tokenData[mint] || {}
            if (!item.iconCheckedAt || now - Number(item.iconCheckedAt) >= 86400000)
                missing.push(mint)
        }
        root._metadataQueue = root._chunks(missing, 30)
        root._fetchNextMetadata()
    }

    function _fetchNextMetadata() {
        if (metadataFetcher.running || root._metadataQueue.length === 0)
            return
        var queue = root._metadataQueue.slice()
        var mints = queue.shift()
        root._metadataQueue = queue
        metadataFetcher.command = ["curl", "-fLsS", "--max-time", "15", "https://api.geckoterminal.com/api/v2/networks/solana/tokens/multi/" + mints.join(',')]
        metadataFetcher.running = true
    }

    function search(query) {
        var normalized = String(query || '').trim()
        root.searchQuery = normalized
        root.searchError = ""
        if (normalized.length < 2) {
            root.searchResults = []
            root.searchLoading = false
            return
        }
        if (searchFetcher.running) {
            root.searchLoading = true
            return
        }
        root._startSearch(normalized)
    }

    function _startSearch(query) {
        root._searchRequest = query
        root.searchLoading = true
        searchFetcher.command = ["curl", "-fLsS", "--max-time", "15", "https://api.dexscreener.com/latest/dex/search?q=" + encodeURIComponent(query)]
        searchFetcher.running = true
    }

    function requestHistory(mint) {
        var item = root.tokenData[mint]
        if (!item || !item.pairAddress || (item.history && item.history.length > 1) || root._historyQueued[mint])
            return

        var queued = root.clone(root._historyQueued)
        queued[mint] = true
        root._historyQueued = queued
        var queue = root._historyQueue.slice()
        queue.push(mint)
        root._historyQueue = queue
        if (!historyFetcher.running && !historyQueueTimer.running)
            historyQueueTimer.start()
    }

    function _fetchNextHistory() {
        if (historyFetcher.running || root._historyQueue.length === 0)
            return
        var queue = root._historyQueue.slice()
        var mint = queue.shift()
        root._historyQueue = queue
        var item = root.tokenData[mint]
        if (!item || !item.pairAddress) {
            root._finishHistory(mint)
            return
        }
        root._historyMint = mint
        historyFetcher.command = ["curl", "-fLsS", "--max-time", "15", "https://api.geckoterminal.com/api/v2/networks/solana/pools/" + item.pairAddress + "/ohlcv/hour?aggregate=1&limit=24&currency=usd"]
        historyFetcher.running = true
    }

    function _finishHistory(mint) {
        var queued = root.clone(root._historyQueued)
        delete queued[mint]
        root._historyQueued = queued
        root._historyMint = ""
        if (root._historyQueue.length > 0)
            historyQueueTimer.restart()
    }

    function persist() {
        if (!root.loaded)
            return
        persistTimer.restart()
    }

    function _writeStorage() {
        var stored = root.clone(root._storage)
        stored.tokens = root.watchlist
        stored.watchlist = root.watchlist
        stored.pinnedTokens = root.pinnedTokens
        stored.marketCapDisplayTokens = root.marketCapDisplayTokens
        var symbols = {}
        var metadata = {}
        for (var i = 0; i < root.watchlist.length; i++) {
            var mint = root.watchlist[i]
            var item = root.tokenData[mint]
            if (item && item.symbol) {
                symbols[mint] = item.symbol
                metadata[mint] = {
                    symbol: item.symbol || '',
                    name: item.name || '',
                    iconUrl: item.iconUrl || '',
                    iconUpdatedAt: item.iconUpdatedAt || 0,
                    iconCheckedAt: item.iconCheckedAt || 0,
                    pairAddress: item.pairAddress || '',
                    dexUrl: item.dexUrl || '',
                    marketCap: item.marketCap,
                    change24h: item.change24h
                }
            }
        }
        stored.tokenSymbols = symbols
        stored.tokenMetadata = metadata
        root._storage = stored
        storageFile.setText(JSON.stringify(stored, null, 2) + '\n')
    }

    FileView {
        id: storageFile
        path: Quickshell.env('HOME') + '/.config/quickshell/data.json'
        atomicWrites: true
        printErrors: false

        function loadData(raw) {
            try {
                root._storage = JSON.parse(String(raw || '{}'))
            } catch (error) {
                root._storage = {}
            }

            var oldTokens = Array.isArray(root._storage.tokens) ? root._storage.tokens : []
            root.watchlist = Array.isArray(root._storage.watchlist) ? root._storage.watchlist : oldTokens
            root.pinnedTokens = Array.isArray(root._storage.pinnedTokens) ? root._storage.pinnedTokens : oldTokens.slice()
            root.marketCapDisplayTokens = Array.isArray(root._storage.marketCapDisplayTokens) ? root._storage.marketCapDisplayTokens.filter(function(mint) {
                return root.watchlist.indexOf(mint) !== -1
            }) : []

            var symbols = root._storage.tokenSymbols || {}
            var metadata = root._storage.tokenMetadata || {}
            var data = {}
            for (var i = 0; i < root.watchlist.length; i++) {
                var mint = root.watchlist[i]
                data[mint] = Object.assign({}, metadata[mint] || {}, { symbol: (metadata[mint] || {}).symbol || symbols[mint] || '' })
            }
            root.tokenData = data
            root.loaded = true
            root.persist()
            root.refreshPrices()
            root.refreshStats()
        }

        onLoaded: loadData(storageFile.text())
        onLoadFailed: loadData('{}')
    }

    Timer {
        id: persistTimer
        interval: 250
        onTriggered: root._writeStorage()
    }

    Timer {
        interval: 5000
        running: root.loaded && root.watchlist.length > 0
        repeat: true
        onTriggered: root.refreshPrices()
    }

    Timer {
        interval: 60000
        running: root.loaded && root.watchlist.length > 0
        repeat: true
        onTriggered: root.refreshStats()
    }

    Process {
        id: priceFetcher
        command: ["true"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var raw = text.trim()
                    if (!raw) {
                        root.dataError = 'Live prices unavailable - showing saved data'
                        return
                    }
                    var response = JSON.parse(raw)
                    var data = root.clone(root.tokenData)
                    for (var mint in response) {
                        if (!response[mint] || response[mint].usdPrice === undefined)
                            continue
                        data[mint] = Object.assign({}, data[mint] || {}, { usdPrice: response[mint].usdPrice })
                    }
                    root.tokenData = data
                    root.dataError = ''
                } catch (error) {
                    root.dataError = 'Live prices unavailable - showing saved data'
                    console.warn('[solana] price fetch:', error)
                }
            }
        }

        onExited: {
            if (root._priceQueue.length > 0)
                priceQueueTimer.restart()
        }
    }

    Timer {
        id: priceQueueTimer
        interval: 0
        onTriggered: root._fetchNextPrices()
    }

    Process {
        id: statsFetcher
        command: ["true"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var raw = text.trim()
                    if (!raw) {
                        root.dataError = 'Market stats unavailable - showing saved data'
                        return
                    }
                    var pairs = JSON.parse(raw)
                    var best = {}
                    for (var i = 0; i < pairs.length; i++) {
                        var pair = pairs[i]
                        if (!pair || pair.chainId !== 'solana' || !pair.baseToken)
                            continue
                        var mint = pair.baseToken.address
                        if (root.watchlist.indexOf(mint) === -1)
                            continue
                        var liquidity = pair.liquidity ? Number(pair.liquidity.usd || 0) : 0
                        var iconUrl = pair.info ? pair.info.imageUrl || '' : ''
                        if (!best[mint] || liquidity > best[mint].liquidity)
                            best[mint] = { pair: pair, liquidity: liquidity, iconUrl: iconUrl }
                        else if (!best[mint].iconUrl && iconUrl)
                            best[mint].iconUrl = iconUrl
                    }

                    var data = root.clone(root.tokenData)
                    for (var mint in best) {
                        var pair = best[mint].pair
                        var existing = data[mint] || {}
                        var iconExpired = !existing.iconCheckedAt || Date.now() - Number(existing.iconCheckedAt) >= 86400000
                        var iconUrl = existing.iconUrl || ''
                        var iconUpdatedAt = existing.iconUpdatedAt || 0
                        var iconCheckedAt = existing.iconCheckedAt || 0
                        if (best[mint].iconUrl && (!iconUrl || iconExpired)) {
                            iconUrl = best[mint].iconUrl
                            iconUpdatedAt = Date.now()
                            iconCheckedAt = iconUpdatedAt
                        }
                        data[mint] = Object.assign({}, data[mint] || {}, {
                            name: pair.baseToken.name || '',
                            symbol: pair.baseToken.symbol || '',
                            iconUrl: iconUrl,
                            iconUpdatedAt: iconUpdatedAt,
                            iconCheckedAt: iconCheckedAt,
                            usdPrice: pair.priceUsd !== null ? Number(pair.priceUsd) : (data[mint] || {}).usdPrice,
                            pairAddress: pair.pairAddress || '',
                            dexUrl: pair.url || '',
                            marketCap: pair.marketCap !== null && pair.marketCap !== undefined ? Number(pair.marketCap) : Number(pair.fdv || 0),
                            change24h: pair.priceChange ? Number(pair.priceChange.h24 || 0) : 0
                        })
                    }
                    root.tokenData = data
                    root.persist()
                    root.refreshMissingIcons()
                    for (var mint in best)
                        root.requestHistory(mint)
                } catch (error) {
                    console.warn('[solana] stats fetch:', error)
                }
            }
        }

        onExited: {
            if (root._statsQueue.length > 0)
                statsQueueTimer.restart()
        }
    }

    Timer {
        id: statsQueueTimer
        interval: 0
        onTriggered: root._fetchNextStats()
    }

    Process {
        id: metadataFetcher
        command: ["true"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var response = JSON.parse(text.trim() || '{}')
                    var entries = Array.isArray(response.data) ? response.data : (response.data ? [response.data] : [])
                    var data = root.clone(root.tokenData)
                    var checkedAt = Date.now()
                    for (var i = 0; i < entries.length; i++) {
                        var attributes = entries[i] ? entries[i].attributes || {} : {}
                        var mint = attributes.address || ''
                        if (!mint || root.watchlist.indexOf(mint) === -1)
                            continue
                        data[mint] = Object.assign({}, data[mint] || {}, {
                            iconUrl: attributes.image_url || (data[mint] || {}).iconUrl || '',
                            iconUpdatedAt: attributes.image_url ? checkedAt : (data[mint] || {}).iconUpdatedAt || 0,
                            iconCheckedAt: checkedAt
                        })
                    }
                    root.tokenData = data
                    root.persist()
                } catch (error) {
                    console.warn('[solana] metadata fetch:', error)
                }
            }
        }

        onExited: {
            if (root._metadataQueue.length > 0)
                metadataQueueTimer.restart()
        }
    }

    Timer {
        id: metadataQueueTimer
        interval: 2200
        onTriggered: root._fetchNextMetadata()
    }

    Process {
        id: searchFetcher
        command: ["true"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (root._searchRequest !== root.searchQuery)
                    return
                try {
                    var raw = text.trim()
                    if (!raw) {
                        root.searchResults = []
                        root.searchError = 'Search failed - retry in a moment'
                        return
                    }
                    var response = JSON.parse(raw)
                    var pairs = response.pairs || []
                    var best = {}
                    for (var i = 0; i < pairs.length; i++) {
                        var pair = pairs[i]
                        if (!pair || pair.chainId !== 'solana' || !pair.baseToken || !pair.baseToken.address)
                            continue
                        var mint = pair.baseToken.address
                        var liquidity = pair.liquidity ? Number(pair.liquidity.usd || 0) : 0
                        var iconUrl = pair.info ? pair.info.imageUrl || '' : ''
                        if (!best[mint] || liquidity > best[mint].liquidity)
                            best[mint] = { pair: pair, liquidity: liquidity, iconUrl: iconUrl }
                        else if (!best[mint].iconUrl && iconUrl)
                            best[mint].iconUrl = iconUrl
                    }
                    var results = []
                    for (var mint in best) {
                        var pair = best[mint].pair
                        results.push({
                            mint: mint,
                            name: pair.baseToken.name || '',
                            symbol: pair.baseToken.symbol || '',
                            iconUrl: best[mint].iconUrl || '',
                            usdPrice: pair.priceUsd !== null ? Number(pair.priceUsd) : 0,
                            pairAddress: pair.pairAddress || '',
                            dexUrl: pair.url || '',
                            marketCap: pair.marketCap !== null && pair.marketCap !== undefined ? Number(pair.marketCap) : Number(pair.fdv || 0),
                            change24h: pair.priceChange ? Number(pair.priceChange.h24 || 0) : 0,
                            liquidity: best[mint].liquidity
                        })
                    }
                    results.sort(function(a, b) { return b.liquidity - a.liquidity })
                    root.searchResults = results.slice(0, 8)
                    root.searchError = results.length === 0 ? 'No Solana tokens found' : ''
                } catch (error) {
                    root.searchResults = []
                    root.searchError = 'Search failed - retry in a moment'
                }
            }
        }

        onExited: {
            root.searchLoading = false
            if (root.searchQuery.length >= 2 && root.searchQuery !== root._searchRequest)
                searchRestartTimer.restart()
        }
    }

    Timer {
        id: searchRestartTimer
        interval: 0
        onTriggered: root._startSearch(root.searchQuery)
    }

    Timer {
        id: historyQueueTimer
        interval: 2200
        onTriggered: root._fetchNextHistory()
    }

    Process {
        id: historyFetcher
        command: ["true"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var response = JSON.parse(text.trim() || '{}')
                    var rows = response.data && response.data.attributes ? response.data.attributes.ohlcv_list || [] : []
                    var values = []
                    for (var i = rows.length - 1; i >= 0; i--)
                        values.push(Number(rows[i][4]))
                    if (values.length > 1)
                        root.mergeToken(root._historyMint, { history: values })
                } catch (error) {
                    console.warn('[solana] history fetch:', error)
                }
            }
        }

        onExited: root._finishHistory(root._historyMint)
    }
}
