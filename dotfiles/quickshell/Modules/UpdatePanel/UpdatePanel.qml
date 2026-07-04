import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Core

PanelWindow {
    id: root

    property real popupX: 0
    property real popupY: 0
    property QtObject updatesItem: null

    signal dismissed()
    signal requestBrief(var packages)

    visible: true
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "update-panel"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    Component.onCompleted: {
        card.refreshModel();
        card.forceActiveFocus();
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.2)

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismissed()
        }

    }

    Rectangle {
        id: card

        property var modelData: []

        function refreshModel() {
            if (!root.updatesItem)
                return ;

            var now = Date.now() / 1000;
            var weekAgo = now - 7 * 24 * 3600;
            var pkgs = root.updatesItem.packages || [];
            var result = [];
            for (var i = 0; i < pkgs.length; i++) {
                var pkg = pkgs[i];
                var epoch = pkg.installEpoch || 0;
                var section = epoch > weekAgo ? "Recent" : "Old";
                result.push({
                    "section": section,
                    "name": pkg.name,
                    "currentVersion": pkg.currentVersion,
                    "newVersion": pkg.newVersion,
                    "source": pkg.source
                });
            }
            result.sort(function(a, b) {
                if (a.section !== b.section)
                    return a.section === "Recent" ? -1 : 1;

                return a.name.localeCompare(b.name);
            });
            card.modelData = result;
        }

        function timeAgo(date) {
            if (!date || !date.getTime)
                return "";

            var diff = Math.floor((Date.now() - date.getTime()) / 1000);
            if (diff < 60)
                return "just now";

            if (diff < 3600)
                return Math.floor(diff / 60) + "m ago";

            if (diff < 86400)
                return Math.floor(diff / 3600) + "h ago";

            return Math.floor(diff / 86400) + "d ago";
        }

        function isPackageUpgrading(pkgName) {
            if (!root.updatesItem)
                return false;

            for (var i = 0; i < root.updatesItem.upgradingPackages.length; i++) {
                if (root.updatesItem.upgradingPackages[i] === pkgName)
                    return true;

            }
            return false;
        }

        function isPackageQueued(pkgName) {
            if (!root.updatesItem)
                return false;

            for (var i = 0; i < root.updatesItem.upgradeQueue.length; i++) {
                if (root.updatesItem.upgradeQueue[i].name === pkgName)
                    return true;

            }
            return false;
        }

        function formatVersion(v) {
            return v || "?";
        }

        x: root.popupX
        y: root.popupY
        width: 480
        height: 420
        color: Config.hexWithAlpha(Config.backgroundColored, "CC")
        radius: Config.borderRadius
        focus: true
        clip: true
        Keys.onEscapePressed: root.dismissed()
        Keys.onUpPressed: {
            pkgList.currentIndex = Math.max(0, pkgList.currentIndex - 1);
            pkgList.positionViewAtIndex(pkgList.currentIndex, ListView.Contain);
        }
        Keys.onDownPressed: {
            pkgList.currentIndex = Math.min(card.modelData.length - 1, pkgList.currentIndex + 1);
            pkgList.positionViewAtIndex(pkgList.currentIndex, ListView.Contain);
        }
        Keys.onReturnPressed: {
            var idx = pkgList.currentIndex;
            if (idx >= 0 && idx < card.modelData.length) {
                var item = card.modelData[idx];
                if (root.updatesItem && !root.updatesItem.upgrading)
                    root.updatesItem.enqueueUpgrade(item.name, item.source);

            }
        }
        Keys.onPressed: function(event) {
            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_N) {
                    pkgList.currentIndex = Math.min(card.modelData.length - 1, pkgList.currentIndex + 1);
                    pkgList.positionViewAtIndex(pkgList.currentIndex, ListView.Contain);
                    event.accepted = true;
                } else if (event.key === Qt.Key_P) {
                    pkgList.currentIndex = Math.max(0, pkgList.currentIndex - 1);
                    pkgList.positionViewAtIndex(pkgList.currentIndex, ListView.Contain);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Y) {
                    var idx = pkgList.currentIndex;
                    if (idx >= 0 && idx < card.modelData.length) {
                        var item = card.modelData[idx];
                        if (root.updatesItem && !root.updatesItem.upgrading)
                            root.updatesItem.enqueueUpgrade(item.name, item.source);

                    }
                    event.accepted = true;
                }
            }
        }

        Connections {
            function onUpgradeStarted() {
                card.refreshModel();
            }

            function onUpgradeFinished() {
                card.refreshModel();
            }

            target: root.updatesItem
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            ListView {
                id: pkgList

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                clip: true
                focus: true
                model: card.modelData
                section.property: "section"
                section.criteria: ViewSection.FullString

                section.delegate: Item {
                    width: pkgList.width
                    height: 36

                    Item {
                        width: parent.width
                        height: 12
                    }

                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 4

                        Text {
                            text: section === "Recent" ? "Fresh" : "Older"
                            color: Config.foreground
                            font.family: Config.fontFamily
                            font.pixelSize: Config.fontSize - 2
                            font.bold: true
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: section === "Recent" ? "<7 days" : ">7 days"
                            color: Config.foregroundSecondary
                            font.family: Config.fontFamily
                            font.pixelSize: Config.fontSize - 4
                            opacity: 0.6
                        }

                    }

                }

                delegate: Rectangle {
                    width: pkgList.width
                    height: 28
                    radius: 4
                    color: {
                        if (index === pkgList.currentIndex)
                            return Config.backgroundHovered;

                        if (card.isPackageUpgrading(modelData.name) || (root.updatesItem && root.updatesItem.upgradingAll))
                            return Config.hexWithAlpha(Config.accent, "20");

                        return "transparent";
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 6
                        spacing: 6

                        Text {
                            text: modelData.name
                            color: Config.foreground
                            font.family: Config.fontFamily
                            font.pixelSize: Config.fontSize - 2
                            elide: Text.ElideRight
                            Layout.preferredWidth: 160
                        }

                        Text {
                            text: card.formatVersion(modelData.currentVersion) + " -> " + card.formatVersion(modelData.newVersion)
                            color: Config.foregroundSecondary
                            font.family: Config.fontFamily
                            font.pixelSize: Config.fontSize - 4
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.source === "flatpak" ? "flatpak" : ""
                            color: Config.foregroundSecondary
                            font.family: Config.fontFamily
                            font.pixelSize: Config.fontSize - 6
                            opacity: 0.5
                            visible: modelData.source === "flatpak"
                        }

                        Rectangle {
                            Layout.preferredWidth: 64
                            Layout.preferredHeight: 22
                            radius: 4
                            color: {
                                if (root.updatesItem && root.updatesItem.upgradingAll)
                                    return Config.foregroundSecondary;

                                if (card.isPackageUpgrading(modelData.name))
                                    return Config.accent;

                                if (card.isPackageQueued(modelData.name))
                                    return Config.foregroundSecondary;

                                if (upgradeMouse.containsMouse)
                                    return Config.accent;

                                return "transparent";
                            }
                            border.width: 1
                            border.color: {
                                if (card.isPackageUpgrading(modelData.name))
                                    return Config.accent;

                                if (card.isPackageQueued(modelData.name))
                                    return Config.foregroundSecondary;

                                return Config.foregroundSecondary;
                            }
                            opacity: 0.8

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (root.updatesItem && root.updatesItem.upgradingAll)
                                        return "\uf110";

                                    if (card.isPackageUpgrading(modelData.name))
                                        return "\uf110";

                                    if (card.isPackageQueued(modelData.name))
                                        return "queued";

                                    return "upgrade";
                                }
                                color: {
                                    if (root.updatesItem && root.updatesItem.upgradingAll)
                                        return Config.foregroundSecondary;

                                    if (card.isPackageUpgrading(modelData.name))
                                        return Config.foregroundSelected;

                                    if (card.isPackageQueued(modelData.name))
                                        return Config.foreground;

                                    return Config.foreground;
                                }
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSize - 4
                            }

                            MouseArea {
                                id: upgradeMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: {
                                    if (!root.updatesItem)
                                        return false;

                                    if (root.updatesItem.upgradingAll)
                                        return false;

                                    if (card.isPackageUpgrading(modelData.name))
                                        return false;

                                    return true;
                                }
                                onClicked: {
                                    root.updatesItem.enqueueUpgrade(modelData.name, modelData.source);
                                }
                            }

                        }

                    }

                }

                ScrollBar.vertical: ScrollBar {
                    width: 6
                    policy: ScrollBar.AsNeeded
                }

            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Config.foregroundSecondary
                opacity: 0.3
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: "transparent"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: Config.borderRadius
                            color: upgradeAllMouse.containsMouse ? Config.accent : "transparent"
                            border.width: 1
                            border.color: Config.accent

                            Text {
                                anchors.centerIn: parent
                                text: root.updatesItem && root.updatesItem.upgradingAll ? "\uf110 Upgrading All" : "Upgrade All"
                                color: upgradeAllMouse.containsMouse ? Config.foregroundSelected : Config.accent
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSize
                            }

                            MouseArea {
                                id: upgradeAllMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: root.updatesItem && !root.updatesItem.upgrading && !root.updatesItem.upgradingAll && root.updatesItem.updateCount > 0
                                onClicked: {
                                    root.updatesItem.enqueueUpgradeAll();
                                }
                            }

                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: Config.borderRadius
                            color: syncMouse.containsMouse ? Config.backgroundHovered : "transparent"
                            border.width: 1
                            border.color: Config.foregroundSecondary

                            Text {
                                anchors.centerIn: parent
                                text: "Sync"
                                color: Config.foreground
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSize
                            }

                            MouseArea {
                                id: syncMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.requestBrief(card.modelData);
                                }
                            }

                        }

                    }

                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (!root.updatesItem)
                                return "";

                            return "Last updated: " + card.timeAgo(root.updatesItem.lastUpdated);
                        }
                        color: Config.foregroundSecondary
                        font.family: Config.fontFamily
                        font.pixelSize: Config.fontSize
                    }

                }

            }

        }

    }

}
