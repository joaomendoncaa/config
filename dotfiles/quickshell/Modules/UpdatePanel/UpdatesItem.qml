import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core

Rectangle {
    id: root

    property string pkgName: ""
    property string currentVersion: ""
    property string newVersion: ""
    property string pkgSource: ""
    property int installEpoch: 0
    property bool isUpgrading: false
    property bool isQueued: false
    property bool isUpgradingAll: false
    property bool errored: false
    property string errorText: ""

    signal upgradeRequested(string name, string source)

    function formatVersion(v) {
        return v || "?";
    }

    function formatDate(epoch) {
        if (!epoch)
            return "";

        var d = new Date(epoch * 1000);
        return String(d.getMonth() + 1).padStart(2, "0") + "/" + String(d.getDate()).padStart(2, "0");
    }

    height: root.errored ? 70 : 44
    radius: 4
    color: root.isUpgrading || root.isUpgradingAll ? Config.hexWithAlpha(Config.accent, "20") : (root.errored ? Config.hexWithAlpha(Config.accent, "10") : Config.backgroundColoredSecondary)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        Item {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            Layout.alignment: root.errored ? Qt.AlignTop : Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: root.errored ? "\uf071" : "\uf4ce"
                color: root.errored ? Config.accent : Config.foregroundSecondary
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize + 2
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: root.errored ? Qt.AlignTop : Qt.AlignVCenter
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.pkgName
                color: Config.foreground
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize - 2
                font.bold: true
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: root.formatDate(root.installEpoch)
                    color: Config.foregroundSecondary
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize - 4
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    text: root.formatVersion(root.currentVersion) + " \u2192 " + root.formatVersion(root.newVersion)
                    color: Config.foregroundSecondary
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize - 4
                    elide: Text.ElideRight
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.errored
                text: root.errorText
                color: Config.accent
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize - 5
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.preferredWidth: 76
            Layout.preferredHeight: 30
            Layout.alignment: root.errored ? Qt.AlignTop : Qt.AlignVCenter
            radius: 4
            color: {
                if (root.isUpgradingAll)
                    return Config.foregroundSecondary;
                if (root.isUpgrading)
                    return Config.accent;
                if (root.isQueued)
                    return Config.foregroundSecondary;
                if (root.errored)
                    return Config.hexWithAlpha(Config.accent, "30");
                if (upgradeMouse.containsMouse)
                    return Config.accent;
                return Config.backgroundColoredTertiary;
            }

            Text {
                anchors.centerIn: parent
                text: {
                    if (root.isUpgradingAll || root.isUpgrading)
                        return "\uf110";
                    if (root.isQueued)
                        return "Queued";
                    if (root.errored)
                        return "Retry";
                    return "Upgrade";
                }
                color: {
                    if (upgradeMouse.containsMouse && !root.isUpgradingAll && !root.isUpgrading && !root.errored)
                        return Config.foregroundSelected;
                    return Config.foreground;
                }
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
            }

            MouseArea {
                id: upgradeMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: !root.isUpgradingAll && !root.isUpgrading
                onClicked: {
                    root.upgradeRequested(root.pkgName, root.pkgSource);
                }
            }
        }
    }
}