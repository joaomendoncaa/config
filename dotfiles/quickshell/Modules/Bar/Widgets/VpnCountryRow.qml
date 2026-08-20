import QtQuick
import qs.Core

Rectangle {
    id: root

    required property var modelData
    property string countryCode: modelData ? (modelData.code || "") : ""
    property string countryName: modelData ? (modelData.name || "") : ""
    property int countryLoad: modelData && typeof modelData.load === "number" ? modelData.load : -1
    property bool current: false
    property bool connecting: false
    property bool disabled: false

    signal clicked(string code)

    height: Math.round(Config.buttonSize * 1.7)
    radius: Config.buttonBorderRadius
    color: {
        if (root.current)
            return Config.hexWithAlpha(Config.accent, "22")
        if (mouseArea.containsMouse && !root.disabled)
            return Config.backgroundHovered
        return "transparent"
    }

    // Convert the ISO country code into its Unicode emoji flag
    // (regional indicator symbols, e.g. "NL" -> U+1F1F3 U+1F1F1).
    property string flagEmoji: root.countryCode.length === 2
        ? String.fromCodePoint(0x1F1E6 + root.countryCode.charCodeAt(0) - 65,
                               0x1F1E6 + root.countryCode.charCodeAt(1) - 65)
        : ""

    Text {
        id: flagText

        anchors.left: parent.left
        anchors.leftMargin: Config.shellPadding
        anchors.verticalCenter: parent.verticalCenter
        text: root.flagEmoji
        font.family: "Noto Color Emoji"
        font.pixelSize: Config.fontSize + 2
    }

    Text {
        id: nameText

        anchors.left: flagText.right
        anchors.leftMargin: Config.gapInner * 2
        anchors.right: loadText.left
        anchors.rightMargin: Config.gapInner
        anchors.verticalCenter: parent.verticalCenter
        text: root.countryName
        color: root.current ? Config.accent : Config.foreground
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize
        font.bold: true
        elide: Text.ElideRight
    }

    Text {
        id: loadText

        anchors.right: parent.right
        anchors.rightMargin: Config.shellPadding
        anchors.verticalCenter: parent.verticalCenter
        visible: !root.connecting
        text: root.countryLoad >= 0 ? root.countryLoad + "%" : ""
        color: root.current ? Config.accent : Config.foregroundSecondary
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize - 2
        font.bold: true
    }

    // Spinner shown on the row that is currently establishing a connection.
    Text {
        id: connectingGlyph

        anchors.right: parent.right
        anchors.rightMargin: Config.shellPadding
        anchors.verticalCenter: parent.verticalCenter
        visible: root.connecting
        text: "\uf110"
        color: Config.accent
        font.family: Config.fontFamily
        font.pixelSize: Config.fontSize

        RotationAnimator {
            target: connectingGlyph
            from: 0
            to: 360
            duration: 1000
            running: root.connecting
            loops: Animation.Infinite
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.disabled
        cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: root.clicked(root.countryCode)
    }
}