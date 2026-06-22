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

    property string foreground: "white"
    property string accent: "#509475"
    property int borderSize: 2
    property int borderRadius: 5
    property int gapsOut: 10
    property string foregroundSelected: "black"
    property string foregroundSecondary: "#60FFFFFF"
    property string background: "transparent"
    property string backgroundColored: "#000000"
    property string backgroundHovered: "#40FFFFFF"
    property var themeFile

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
            foreground = c.foreground || "white";
            accent = c.accent || foreground;
            background = "transparent";
            backgroundColored = c.background || "#000000";
            foregroundSelected = c.selection_foreground || "black";
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
