import "NotificationLogic.js" as N
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core

Rectangle {
    id: root

    property string app: ""
    property string appIcon: ""
    property string summary: ""
    property string body: ""
    property string image: ""
    property string glyph: ""
    property int urgency: 1
    property double timestamp: 0
    property double expireTimeout: 0
    property int cornerRadius: 5
    property int duplicateCount: 1
    property bool showCloseButton: false
    property bool dismissing: false
    property real popupProgress: -1
    property int iconSize: 40
    property real titleFontSize: Config.fontSize
    property real bodyFontSize: Config.fontSize
    property int bodyMaxLines: 3
    property color cardBackground: Config.backgroundColored
    property color cardBorderColor: Config.accent
    property int cardBorderWidth: Config.borderSize
    readonly property bool hovered: hoverTracker.hovered
    readonly property string smallIconSource: image.length > 0 ? image : iconSource(appIcon)
    readonly property bool hasGlyph: glyph.length > 0
    readonly property bool compactGlyph: N.shouldRenderCompactGlyph(glyph, smallIconSource)
    readonly property bool hasSmallIcon: smallIconSource.length > 0
    readonly property bool summaryStartsWithGlyph: N.summaryStartsWithGlyph(summary)
    readonly property bool singleLineToast: sanitizedBody.length === 0
    readonly property bool collapseRedundantIcon: singleLineToast && !hasGlyph && summaryStartsWithGlyph
    readonly property string sanitizedBody: N.sanitizeBody(body, app, appIcon)
    readonly property string styledBody: sanitizedBody.replace(/\r\n|\r|\n/g, "<br/>")
    readonly property string displaySummary: root.duplicateCount > 1 ? root.summary + " [" + root.duplicateCount + "]" : root.summary
    property real _expiryProgress: 1
    readonly property color dimColor: Qt.darker(Config.foreground, 1.4)
    readonly property color bodyColor: Qt.darker(Config.foreground, 1.15)
    readonly property color accentColor: urgency === 2 ? Config.accent : (urgency === 0 ? dimColor : Config.accent)

    signal closeRequested()
    signal cardClicked()

    function _recomputeExpiryProgress() {
        if (expireTimeout <= 0)
            return ;

        var elapsed = Date.now() - timestamp;
        var total = expireTimeout * 1000;
        _expiryProgress = Math.max(0, 1 - elapsed / total);
    }

    function iconSource(icon) {
        var value = String(icon || "");
        if (value.length === 0)
            return "";

        if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0)
            return value;

        if (value.charAt(0) === "/")
            return "file://" + value;

        return Quickshell.iconPath(value, true);
    }

    Component.onCompleted: _recomputeExpiryProgress()
    onDuplicateCountChanged: {
        if (expireTimeout > 0)
            _expiryProgress = 1;

    }
    implicitWidth: 380
    implicitHeight: mainColumn.implicitHeight
    radius: cornerRadius
    color: root.cardBackground
    clip: true

    Timer {
        interval: 50
        repeat: true
        running: root.expireTimeout > 0
        onTriggered: root._recomputeExpiryProgress()
    }

    HoverHandler {
        id: hoverTracker
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: {
            if (mouse.button === Qt.RightButton)
                root.closeRequested()
            else
                root.cardClicked()
        }
    }

    ColumnLayout {
        id: mainColumn

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 0
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            Layout.topMargin: root.singleLineToast ? 7 : 10
            Layout.bottomMargin: root.singleLineToast ? 7 : 10
            spacing: root.collapseRedundantIcon ? 0 : (root.compactGlyph ? 8 : 12)

            Item {
                id: smallIconSlot

                Layout.preferredWidth: visible ? root.iconSize : 0
                Layout.preferredHeight: visible ? root.iconSize : 0
                Layout.alignment: Qt.AlignVCenter
                visible: !root.collapseRedundantIcon && !root.compactGlyph && root.hasSmallIcon && (root.hasGlyph || smallIconImage.status !== Image.Error)

                Image {
                    id: smallIconImage

                    anchors.fill: parent
                    source: root.smallIconSource
                    sourceSize.width: smallIconSlot.width * Screen.devicePixelRatio
                    sourceSize.height: smallIconSlot.height * Screen.devicePixelRatio
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    visible: !root.hasGlyph || smallIconImage.status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.hasGlyph && smallIconImage.status !== Image.Ready
                    text: root.glyph
                    color: Config.foreground
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize + 8
                }

            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                visible: root.compactGlyph
                text: root.glyph
                color: Config.foreground
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    visible: root.summary.length > 0
                    text: root.displaySummary
                    color: Config.foreground
                    font.family: Config.fontFamily
                    font.pixelSize: root.titleFontSize
                    font.bold: true
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    visible: root.sanitizedBody.length > 0
                    text: root.styledBody
                    textFormat: Text.StyledText
                    color: root.bodyColor
                    font.family: Config.fontFamily
                    font.pixelSize: root.bodyFontSize
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: root.bodyMaxLines
                }

            }

            Rectangle {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                Layout.alignment: Qt.AlignVCenter
                visible: root.showCloseButton
                radius: Math.min(4, Config.borderRadius)
                color: closeArea.containsMouse ? Config.foregroundSecondary : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\u2715"
                    color: root.dimColor
                    font.family: Config.fontFamily
                    font.pixelSize: root.bodyFontSize
                }

                MouseArea {
                    id: closeArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }

            }

        }

    }

    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        height: 3
        visible: !root.dismissing && (root.popupProgress >= 0 || root.expireTimeout > 0)
        z: 1
        color: Config.foreground
        width: root.width * (root.popupProgress >= 0 ? root.popupProgress : root._expiryProgress)
        bottomLeftRadius: root.cornerRadius
        bottomRightRadius: root.cornerRadius
        topLeftRadius: 0
        topRightRadius: 0
    }

}
