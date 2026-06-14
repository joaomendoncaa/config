import QtQuick
import QtWebEngine
import Quickshell

Item {
  id: root

  property string symbol: "BINANCE:BTCUSDT"
  property bool pageReady: false

  function embedUrl(sym) {
    return "https://www.tradingview.com/widgetembed/?symbol=" + encodeURIComponent(sym)
      + "&interval=D&theme=dark&locale=en&toolbar_bg=%231e1e1e"
      + "&enable_publishing=0&hideideas=1&allow_symbol_change=1"
      + "&hide_side_toolbar=0&details=0&hotlist=0"
  }

  WebEngineView {
    id: webview
    anchors.fill: parent
    backgroundColor: "#1e1e1e"
    opacity: root.pageReady ? 1 : 0
    url: root.embedUrl(root.symbol)

    Behavior on opacity { NumberAnimation { duration: 150 } }

    onLoadingChanged: function(load) {
      if (load.status === 0) {
        root.pageReady = false
      } else if (load.status === 2) {
        webview.runJavaScript(
          "var s=document.createElement('style');" +
          "s.textContent='" +
          "body{background:#0f0f0f!important;overflow:hidden!important;margin:0;padding:0}" +
          "';" +
          "document.head.appendChild(s)",
          function() { root.pageReady = true }
        )
      }
    }
  }
}
