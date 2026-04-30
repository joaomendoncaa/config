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
    readonly property string fontFamily: "JetBrainsMonoNL Nerd Font"
    readonly property int shellPadding: 10
    // Colors - computed from theme (not readonly so we can update them)
    // All colors must be in 6-digit hex format (#RRGGBB) for proper alpha derivation
    property string foreground: "white"
    property string foregroundSelected: "black"
    property string foregroundSecondary: "#60FFFFFF"
    property string background: "transparent"
    property string backgroundColored: "#000000"
    property string backgroundHovered: "#40FFFFFF"
    // Process to run the extraction script
    property var stdoutCollector
    property var colorProcess

    // Combines a 6-digit hex color (#RRGGBB) with an alpha value
    // Returns #AARRGGBB format for Qt Quick color property
    // Assumes input is valid 6-digit hex (validated in parsing functions)
    function hexWithAlpha(hexColor, alphaHex) {
        if (!hexColor || hexColor.length !== 7 || !hexColor.startsWith("#")) {
            console.warn("[Config] Expected #RRGGBB format, got:", hexColor);
            return hexColor;
        }
        return "#" + alphaHex + hexColor.substring(1);
    }

    function applyColors(fore, selFore, back) {
        foreground = fore || "white";
        background = "transparent";
        backgroundColored = back || "#000000";
        foregroundSelected = selFore || "black";
        foregroundSecondary = hexWithAlpha(foreground, "60");
        backgroundHovered = hexWithAlpha(foreground, "40");
        console.log("[Config] Theme loaded - foreground:", foreground, "selected:", foregroundSelected, "secondary:", foregroundSecondary, "backgroundColored:", backgroundColored);
    }

    function parseColorOutput() {
        var output = stdoutCollector.text.trim();
        console.log("[Config] Script output:", output);
        try {
            var colors = JSON.parse(output);
            applyColors(colors.foreground, colors.selection_foreground, colors.background);
        } catch (e) {
            console.warn("[Config] Failed to parse colors JSON:", e);
        }
    }

    Component.onCompleted: {
        console.log("[Config] Loading theme colors...");
        colorProcess.running = true;
    }

    stdoutCollector: StdioCollector {
        onStreamFinished: parseColorOutput()
    }

    colorProcess: Process {
        command: [Quickshell.env("HOME") + "/.config.jmmm.sh/bin/omarchy-theme-get-colors"]
        stdout: stdoutCollector
    }

}
