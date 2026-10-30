import "NotificationLogic.js" as N
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core

Rectangle {
    id: root

    property string app: ""
    property string appIcon: ""
    property string desktopEntry: ""
    property string summary: ""
    property string body: ""
    property string image: ""
    property string glyph: ""
    property real value: -1
    property int urgency: 1
    property double timestamp: 0
    property double expireTimeout: 0
    property int cornerRadius: 5
    property int duplicateCount: 1
    property bool busy: false
    property bool showCloseButton: false
    property bool showExpiryBar: false
    property bool dismissing: false
    property real popupProgress: -1
    property int iconSize: 22
    property real titleFontSize: Config.fontSize
    property real bodyFontSize: Config.fontSize
    property int bodyMaxLines: 3
    property color cardBackground: Config.backgroundColored
    property color cardBorderColor: Config.accent
    property int cardBorderWidth: Config.borderSize
    property var notificationActions: []
    property bool hideActionButtons: false
    readonly property bool hovered: hoverTracker.hovered
    readonly property bool critical: urgency >= 2
    readonly property color dangerColor: "#e5534b"
    readonly property color appTint: Qt.hsla(N.appHue(app) / 360, 0.42, 0.52, 1)
    readonly property color badgeColor: critical ? dangerColor : appTint
    readonly property string badgeText: critical ? "⚠" : (glyph.length > 0 ? glyph : N.appInitial(app))
    readonly property string resolvedIcon: {
        var candidates = [appIcon, desktopEntry, app];
        for (var i = 0; i < candidates.length; i++) {
            var src = root.iconSource(candidates[i]);
            if (src.length > 0)
                return src;
        }
        return "";
    }
    readonly property bool iconReady: !critical && resolvedIcon.length > 0 && badgeImage.status === Image.Ready
    readonly property string sanitizedBody: N.sanitizeBody(body, app, appIcon)
    readonly property string styledBody: sanitizedBody.replace(/\r\n|\r|\n/g, "<br/>")
    readonly property string displaySummary: duplicateCount > 1 ? summary + " [" + duplicateCount + "]" : summary
    readonly property string timeLabel: timestamp > 0 ? Qt.formatTime(new Date(timestamp), "HH:mm") : ""
    property real _expiryProgress: 1
    readonly property color dimColor: Qt.darker(Config.foreground, 1.4)
    readonly property color bodyColor: Qt.darker(Config.foreground, 1.15)

    signal closeRequested()
    signal cardClicked()
    signal actionInvoked(var action)

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
    implicitHeight: mainColumn.implicitHeight + 24
    radius: cornerRadius
    color: root.cardBackground
    border.width: root.cardBorderWidth
    border.color: root.cardBorderColor
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
                root.closeRequested();
            else
                root.cardClicked();
        }
    }

    ColumnLayout {
        id: mainColumn

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        spacing: 6

        // Header: app badge, sender name, time, dismiss
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                id: badge

                Layout.preferredWidth: root.iconSize
                Layout.preferredHeight: root.iconSize
                Layout.alignment: Qt.AlignVCenter
                radius: Math.max(4, Math.min(10, root.iconSize * 0.35))
                color: root.iconReady ? "transparent" : root.badgeColor

                Image {
                    id: badgeImage

                    anchors.fill: parent
                    source: root.resolvedIcon
                    sourceSize.width: root.iconSize * Screen.devicePixelRatio
                    sourceSize.height: root.iconSize * Screen.devicePixelRatio
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                    visible: root.iconReady
                }

                Text {
                    anchors.centerIn: parent
                    visible: !root.iconReady
                    text: root.badgeText
                    color: "#FFFFFF"
                    font.family: Config.fontFamily
                    font.pixelSize: Math.round(root.iconSize * 0.5)
                    font.bold: true
                }

            }

            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: root.app
                color: Config.foregroundSecondary
                font.family: Config.fontFamily
                font.pixelSize: Math.max(10, root.titleFontSize - 4)
                elide: Text.ElideRight
                maximumLineCount: 1
                visible: text.length > 0
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: root.timeLabel
                color: root.dimColor
                font.family: Config.fontFamily
                font.pixelSize: Math.max(10, root.titleFontSize - 4)
                visible: text.length > 0
            }

            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter
                visible: root.showCloseButton
                radius: Math.min(4, Config.borderRadius)
                color: closeArea.containsMouse ? Config.backgroundHovered : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: root.dimColor
                    font.family: Config.fontFamily
                    font.pixelSize: Math.max(10, root.bodyFontSize - 3)
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

        // Summary and body, with the notification's picture beside them
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    visible: root.displaySummary.length > 0
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
                    visible: root.sanitizedBody.length > 0
                    text: root.styledBody
                    textFormat: Text.StyledText
                    color: root.bodyColor
                    linkColor: Config.accent
                    font.family: Config.fontFamily
                    font.pixelSize: root.bodyFontSize
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: root.bodyMaxLines
                }

                // Freedesktop `value`: volume, brightness, downloads
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    Layout.preferredHeight: 5
                    visible: root.value >= 0
                    radius: 2.5
                    color: Config.hexWithAlpha(Config.foreground, "28")
                    clip: true

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, root.value))
                        height: parent.height
                        radius: 2.5
                        color: Config.foregroundSecondary
                    }

                }

            }

            Rectangle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                Layout.alignment: Qt.AlignVCenter
                visible: root.image.length > 0 && bodyImage.status !== Image.Error
                radius: 8
                clip: true
                color: "transparent"

                Image {
                    id: bodyImage

                    anchors.fill: parent
                    source: root.image
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                }

            }

        }

        // Action buttons — visible for as long as the card is
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            spacing: 4
            visible: !root.hideActionButtons && root.notificationActions.length > 0

            Repeater {
                model: root.notificationActions

                Rectangle {
                    required property var modelData
                    required property int index
                    property bool isHovered: false

                    Layout.preferredHeight: 26
                    Layout.preferredWidth: Math.max(actionText.implicitWidth + 20, 48)
                    radius: Math.max(2, Math.min(8, root.cornerRadius * 0.6))
                    color: index === 0 ? Config.hexWithAlpha(Config.foreground, "14") : (isHovered ? Config.backgroundHovered : "transparent")

                    Text {
                        id: actionText

                        anchors.centerIn: parent
                        text: modelData.text || modelData.identifier || "Open"
                        color: index === 0 ? Config.foreground : root.bodyColor
                        font.family: Config.fontFamily
                        font.pixelSize: Math.max(10, root.bodyFontSize - 3)
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        onEntered: parent.isHovered = true
                        onExited: parent.isHovered = false
                        onClicked: {
                            if (modelData && modelData.invoke)
                                modelData.invoke();

                            root.actionInvoked(modelData);
                            root.closeRequested();
                        }
                    }
                }
            }
        }

    }

    // Expiry countdown; a value bar already occupies the bottom edge when present
    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        height: 2
        visible: root.showExpiryBar && !root.dismissing && !root.busy && root.value < 0 && (root.popupProgress >= 0 || root.expireTimeout > 0)
        z: 1
        color: Config.hexWithAlpha(Config.foreground, "33")
        width: root.width * (root.popupProgress >= 0 ? root.popupProgress : root._expiryProgress)
        bottomLeftRadius: root.cornerRadius
        bottomRightRadius: root.cornerRadius
        topLeftRadius: 0
        topRightRadius: 0
    }

    Rectangle {
        id: busyBar

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 3
        visible: !root.dismissing && root.busy
        z: 1
        clip: true
        color: Config.hexWithAlpha(Config.foreground, "28")
        bottomLeftRadius: root.cornerRadius
        bottomRightRadius: root.cornerRadius

        Rectangle {
            id: busyIndicator

            width: parent.width * 0.38
            height: parent.height
            color: Config.foreground
            x: -width

            SequentialAnimation on x {
                loops: Animation.Infinite
                running: busyBar.visible

                NumberAnimation {
                    from: -busyIndicator.width
                    to: busyBar.width
                    duration: 1050
                    easing.type: Easing.InOutQuad
                }

                PauseAnimation {
                    duration: 100
                }
            }
        }
    }

}
