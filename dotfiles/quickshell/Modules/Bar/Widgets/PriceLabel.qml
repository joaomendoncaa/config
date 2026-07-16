import QtQuick
import QtQuick.Layouts
import qs.Core

Rectangle {
    id: root

    property string mint: ""
    property var priceData: null

    function toSuperscript(n) {
        var chars = ['⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹'];
        var s = String(n);
        var r = '';
        for (var i = 0; i < s.length; i++) r += chars[parseInt(s[i], 10)]
        return r;
    }

    function pretiffyPrice(price) {
        if (price === 0)
            return "0";

        if (price >= 1) {
            for (var d = 6; d >= 0; d--) {
                var s = price.toFixed(d);
                if (s.length <= 8)
                    return s;

            }
            return price.toFixed(0).substring(0, 8);
        }
        var bestStandard = null;
        for (var d = 8; d >= 1; d--) {
            var s = price.toFixed(d);
            if (s.length <= 8 && parseFloat(s) !== 0) {
                bestStandard = s;
                break;
            }
        }
        var fixed = price.toFixed(15);
        var dec = fixed.split('.')[1] || '';
        var z = 0;
        while (z < dec.length && dec[z] === '0')z++
        if (z > 0 && z < dec.length) {
            var sup = toSuperscript(z);
            var avail = Math.max(0, 8 - 3 - sup.length);
            var supStr = "0.0" + sup + dec.substring(z, z + avail);
            var standardSig = bestStandard ? countNonZero(bestStandard.split('.')[1] || '') : 0;
            var supSig = countNonZero(supStr.split('.')[1] || '');
            if (supSig > standardSig)
                return supStr;

        }
        return bestStandard || "0";
    }

    function countNonZero(s) {
        var c = 0;
        for (var i = 0; i < s.length; i++) {
            if (s[i] !== '0')
                c++;

        }
        return c;
    }

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
            if (!root.priceData || root.priceData.usdPrice === undefined || root.priceData.usdPrice === null) {
                var s = root.mint.length > 6 ? root.mint.substring(0, 4) + ".." : root.mint;
                var sym = root.priceData && root.priceData.symbol;
                return sym ? sym : s + "$0.000000";
            }
            var sym = root.priceData.symbol || root.mint.substring(0, 4) + "..";
            var p = Number(root.priceData.usdPrice);
            return sym + "$" + pretiffyPrice(p);
        }
        color: Config.foreground
        font.pixelSize: Config.fontSize - 2
        font.family: Config.fontFamily
        font.weight: Font.Bold
    }

}
