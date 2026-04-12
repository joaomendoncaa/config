import QtQuick
pragma Singleton

QtObject {
    readonly property int height: 30
    readonly property int fontSize: 16
    readonly property int buttonSize: 26
    readonly property int buttonBorderRadius: 4
    readonly property int gapOuter: 12
    readonly property int gapInner: 4
    readonly property string fontFamily: "JetBrainsMonoNL Nerd Font"
    readonly property string foreground: "white"
    readonly property string foregroundSelected: "black"
    readonly property string foregroundSecondary: "#60FFFFFF"
    readonly property string background: "transparent"
    readonly property string backgroundHovered: "#40FFFFFF"
    readonly property int shellPadding: 10
}
