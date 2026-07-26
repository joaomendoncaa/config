import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core

Rectangle {
    id: root

    property QtObject updatesItem: null
    property var modelData: []
    property bool syncing: false
    property var erroredPackages: []
    property string errorMessage: ""

    signal dismissed()

    function refreshModel() {
        if (!root.updatesItem)
            return ;

        var pkgs = root.updatesItem.packages || [];
        var result = [];
        for (var i = 0; i < pkgs.length; i++) {
            var pkg = pkgs[i];
            var isErrored = root.erroredPackages.indexOf(pkg.name) >= 0;
            result.push({
                "name": pkg.name,
                "currentVersion": pkg.currentVersion,
                "newVersion": pkg.newVersion,
                "source": pkg.source,
                "installEpoch": pkg.installEpoch || 0,
                "upgrading": root.isPackageUpgrading(pkg.name),
                "queued": root.isPackageQueued(pkg.name),
                "errored": isErrored,
                "errorText": isErrored ? root.errorMessage : ""
            });
        }
        result.sort(function(a, b) {
            return a.name.localeCompare(b.name);
        });
        root.modelData = result;
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

    function sync() {
        if (!root.updatesItem)
            return;

        root.syncing = true;
        root.updatesItem.refresh();
    }

    implicitWidth: 480
    color: Config.backgroundColored
    radius: Config.borderRadius
    clip: true

    Component.onCompleted: {
        root.refreshModel();
        root.syncing = root.updatesItem ? root.updatesItem.listProcess.running : false;
    }

    Timer {
        id: upgradeTimer

        property string pkgName: ""
        property string pkgSource: ""

        interval: 0
        repeat: false
        onTriggered: {
            if (root.updatesItem)
                root.updatesItem.enqueueUpgrade(pkgName, pkgSource);
        }
    }

    Connections {
        function onUpgradeStarted() {
            root.erroredPackages = [];
            root.errorMessage = "";
            root.refreshModel();
        }

        function onUpgradeFinished() {
            root.refreshModel();
        }

        function onPackagesUpdated() {
            root.syncing = false;
            root.refreshModel();
        }

        function onUpgradeError(message) {
            root.erroredPackages = root.updatesItem ? root.updatesItem.upgradingPackages.slice() : [];
            root.errorMessage = message;
            root.refreshModel();
        }

        target: root.updatesItem
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 0

        ListView {
            id: pkgList

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            model: root.modelData

            delegate: UpdatesItem {
                width: pkgList.width
                pkgName: modelData.name
                currentVersion: modelData.currentVersion
                newVersion: modelData.newVersion
                pkgSource: modelData.source
                installEpoch: modelData.installEpoch
                isUpgrading: modelData.upgrading
                isQueued: modelData.queued
                isUpgradingAll: root.updatesItem ? root.updatesItem.upgradingAll : false
                errored: modelData.errored
                errorText: modelData.errorText

                onUpgradeRequested: function(name, source) {
                    upgradeTimer.pkgName = name;
                    upgradeTimer.pkgSource = source;
                    upgradeTimer.restart();
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: Config.borderRadius
                color: upgradeAllMouse.containsMouse ? Config.foregroundSecondary : Config.foreground

                Text {
                    anchors.centerIn: parent
                    text: root.updatesItem && root.updatesItem.upgradingAll ? "\uf110 Upgrading All" : "Upgrade All"
                    color: upgradeAllMouse.containsMouse ? Config.foreground : Config.backgroundColored
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
                Layout.preferredWidth: 48
                Layout.preferredHeight: 36
                radius: Config.borderRadius
                color: syncMouse.containsMouse ? Config.backgroundHovered : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: root.syncing ? "\uf110" : "\uD83D\uDDD8"
                    color: Config.foreground
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                }

                MouseArea {
                    id: syncMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !root.syncing
                    onClicked: root.sync()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 6
            text: {
                if (!root.updatesItem)
                    return "";

                return "Last updated: " + root.timeAgo(root.updatesItem.lastUpdated);
            }
            color: Config.foregroundSecondary
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize
        }
    }
}