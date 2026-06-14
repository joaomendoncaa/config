import QtQuick
import QtWebEngine
import Quickshell

Item {
  id: root

  property string symbol: "BINANCE:BTCUSDT"

  WebEngineView {
    id: webview
    anchors.fill: parent
    backgroundColor: "#1e1e1e"
    url: "https://www.tradingview.com/widgetembed/?symbol=" + encodeURIComponent(root.symbol) + "&interval=D&theme=dark&locale=en&toolbar_bg=%231e1e1e&enable_publishing=0&hideideas=1&allow_symbol_change=1"

    onLoadingChanged: function(load) {
      console.log("Chart: load status:", load.status, load.errorString || "")
    }
  }
}
