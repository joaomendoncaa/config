import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core

Rectangle {
    id: root

    property var notificationService: null
    property bool popupOpen: false

    signal dismissed()

    readonly property int notificationCount: notificationService ? notificationService.pendingModel.count : 0
    readonly property bool dnd: notificationService ? notificationService.doNotDisturb : false

    readonly property string emptyIcon: {
        if (dnd) return "../../Assets/notifs-muted.svg"
        return "../../Assets/notifs.svg"
    }

    implicitWidth: 400
    implicitHeight: 540
    radius: Config.borderRadius
    color: Config.backgroundColored
    clip: true

    focus: true
    Keys.onEscapePressed: root.dismissed()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        // Action row
        RowLayout {
            Layout.fillWidth: true
            visible: root.notificationCount > 0
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: 4
                color: actionArea.containsMouse ? Qt.lighter(Config.foreground, 1.2) : Config.foreground

                Text {
                    id: actionLabel
                    anchors.centerIn: parent
                    text: "CLEAR ALL"
                    color: Config.foregroundSelected
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize - 2
                }

                MouseArea {
                    id: actionArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.notificationService) root.notificationService.clearPending()
                    }
                }
            }
        }

        // List
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8

            model: root.notificationService ? root.notificationService.pendingModel : null
            visible: count > 0

            delegate: Rectangle {
                required property int index
                required property string app
                required property string appIcon
                required property string summary
                required property string body
                required property string image
                required property int urgency
                required property double timestamp
                required property double expireTimeout
                required property int duplicateCount

                width: listView.width
                implicitHeight: card.implicitHeight
                color: "transparent"

                NotificationCard {
                    id: card
                    anchors.left: parent.left
                    anchors.right: parent.right
                    app: parent.app
                    appIcon: parent.appIcon
                    summary: parent.summary
                    body: parent.body
                    image: parent.image
                    urgency: parent.urgency
                    timestamp: parent.timestamp
                    expireTimeout: parent.expireTimeout
                    duplicateCount: parent.duplicateCount
                    cornerRadius: Config.borderRadius
                    showCloseButton: true
                    iconSize: 32
                    titleFontSize: Config.fontSize - 2
                    bodyFontSize: Config.fontSize - 4
                    bodyMaxLines: 2
                    cardBackground: Config.backgroundColoredSecondary
                    cardBorderColor: Config.foregroundSecondary
                    cardBorderWidth: 1

                    onCloseRequested: {
                        if (root.notificationService) root.notificationService.dismissPending(index)
                    }
                    onCardClicked: {
                        if (root.notificationService) root.notificationService.invokePendingDefault(index)
                        root.dismissed()
                    }
                }
            }
        }

        // Empty state
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: listView.count === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48

                    Image {
                        id: emptyMaskImage
                        anchors.fill: parent
                        source: root.emptyIcon
                        sourceSize.width: 48
                        sourceSize.height: 48
                        smooth: true
                        visible: false
                    }

                    Rectangle {
                        id: emptyFgColor
                        anchors.fill: parent
                        color: Config.foreground
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: parent
                        source: emptyFgColor
                        maskSource: emptyMaskImage
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No notifications"
                    color: Qt.darker(Config.foreground, 1.4)
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                }
            }
        }
    }
}
