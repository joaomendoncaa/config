import QtQuick
import QtQuick.Layouts
import qs.Core

Rectangle {
    id: root

    property string mint: ""
    property var priceData: null

    Layout.preferredHeight: Config.buttonSize
    Layout.preferredWidth: label.implicitWidth + Config.gapInner * 2
    radius: Config.buttonBorderRadius
    color: "transparent"
    visible: mint.length > 0

    Text {
        id: label

        anchors.fill: parent
        anchors.leftMargin: Config.gapInner
        anchors.rightMargin: Config.gapInner
        verticalAlignment: Text.AlignVCenter
        text: {
            var sym = root.priceData.symbol || root.mint.substring(0, 4) + "..";
            if (!root.priceData || root.priceData.usdPrice === undefined || root.priceData.usdPrice === null) {
                var s = root.mint.length > 6 ? root.mint.substring(0, 4) + ".." : root.mint;
                return sym ? sym : s + "$...";
            }
            var p = Number(root.priceData.usdPrice);
            var pp;
            if (p === 0)
                pp = "0";
            else if (p < 0.0001)
                pp = p.toExponential(2);
            else if (p < 1)
                pp = p.toFixed(6);
            else if (p < 100)
                pp = p.toFixed(4);
            else
                pp = p.toFixed(2);
            return sym + "$" + pp;
        }
        color: Config.foreground
        font.pixelSize: Config.fontSize - 2
        font.family: Config.fontFamily
    }

}
