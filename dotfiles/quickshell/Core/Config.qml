import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

QtObject {
    readonly property string sinkHeadphones: "alsa_output.usb-Razer_Razer_Barracuda_X-00.analog-stereo"
    readonly property int height: 30
    readonly property int fontSize: 16
    readonly property int buttonSize: 26
    readonly property int buttonBorderRadius: 4
    readonly property int gapOuter: 12
    readonly property int gapInner: 4
    readonly property int idleLockTimeout: 600
    readonly property int cursorBlinkInterval: 530
    readonly property string fontFamily: "JetBrainsMonoNL Nerd Font"
    readonly property int shellPadding: 10

    property string foreground: "#FFFFFF"
    property string accent: "#509475"
    property int borderSize: 2
    property int borderRadius: 5
    property int gapsOut: 10
    property string foregroundSelected: "#000000"
    property string foregroundSecondary: "#60FFFFFF"
    property string background: "transparent"
    property string backgroundColored: "#000000"
    property string backgroundColoredSecondary: "#131313"
    property string backgroundColoredTertiary: "#262626"
    property string backgroundHovered: "#40FFFFFF"
    property var themeFile

    function hexToRgb(hexColor) {
        if (!hexColor || hexColor.length !== 7 || !hexColor.startsWith("#")) {
            return {r: 0, g: 0, b: 0};
        }
        return {
            r: parseInt(hexColor.substring(1, 3), 16) / 255,
            g: parseInt(hexColor.substring(3, 5), 16) / 255,
            b: parseInt(hexColor.substring(5, 7), 16) / 255
        };
    }

    function rgbToHex(r, g, b) {
        var toHex = function(v) {
            var s = Math.round(v * 255).toString(16);
            return s.length === 1 ? "0" + s : s;
        };
        return "#" + toHex(r) + toHex(g) + toHex(b);
    }

    function rgbToHsl(r, g, b) {
        var max = Math.max(r, g, b);
        var min = Math.min(r, g, b);
        var h, s, l = (max + min) / 2;

        if (max === min) {
            h = s = 0;
        } else {
            var d = max - min;
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
            switch (max) {
                case r: h = ((g - b) / d + (g < b ? 6 : 0)) / 6; break;
                case g: h = ((b - r) / d + 2) / 6; break;
                case b: h = ((r - g) / d + 4) / 6; break;
            }
        }
        return {h: h, s: s, l: l};
    }

    function hslToRgb(h, s, l) {
        if (s === 0) {
            return {r: l, g: l, b: l};
        }
        var hue2rgb = function(p, q, t) {
            if (t < 0) t += 1;
            if (t > 1) t -= 1;
            if (t < 1/6) return p + (q - p) * 6 * t;
            if (t < 1/2) return q;
            if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
            return p;
        };
        var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        var p = 2 * l - q;
        return {
            r: hue2rgb(p, q, h + 1/3),
            g: hue2rgb(p, q, h),
            b: hue2rgb(p, q, h - 1/3)
        };
    }

    function lighten(hexColor, amount) {
        var rgb = hexToRgb(hexColor);
        var hsl = rgbToHsl(rgb.r, rgb.g, rgb.b);
        hsl.l = Math.min(1, hsl.l + amount);
        var newRgb = hslToRgb(hsl.h, hsl.s, hsl.l);
        return rgbToHex(newRgb.r, newRgb.g, newRgb.b);
    }

    function hexWithAlpha(hexColor, alphaHex) {
        if (!hexColor || hexColor.length !== 7 || !hexColor.startsWith("#")) {
            console.warn("[Config] Expected #RRGGBB format, got:", hexColor);
            return hexColor;
        }
        return "#" + alphaHex + hexColor.substring(1);
    }

    function applyColors(raw) {
        try {
            var c = JSON.parse(String(raw || '{}'));
            foreground = c.foreground || "#FFFFFF";
            accent = c.accent || foreground;
            background = "transparent";
            backgroundColored = c.background || "#000000";
            backgroundColoredSecondary = lighten(backgroundColored, 0.075);
            backgroundColoredTertiary = lighten(backgroundColored, 0.15);
            foregroundSelected = c.selection_foreground || "#000000";
            foregroundSecondary = hexWithAlpha(foreground, "60");
            backgroundHovered = hexWithAlpha(foreground, "40");
        } catch (e) {
            console.warn("[Config] Failed to parse colors.json:", e);
        }
    }

    themeFile: FileView {
        path: Quickshell.env("HOME") + "/.config/theme/colors.json"
        watchChanges: true
        onLoaded: applyColors(text())
        onFileChanged: reload()
        printErrors: false
    }
}
