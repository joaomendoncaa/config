import "."
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Rectangle {
    id: root

    property QtObject barWindow: null
    property bool popupVisible: false
    property string workspaceId: Quickshell.env("OPENCODE_WORKSPACE_ID") || "wrk_01KEYSE6SWHFGJ2DB8C2690QJ2"
    property var usageData: null
    property real pct5h: 0
    property real pctWeekly: 0
    property real pctMonthly: 0
    property string reset5h: ""
    property string resetWeekly: ""
    property string resetMonthly: ""
    property string balance: ""

    function fetchUsage() {
        usageProc.running = true;
    }

    function scaleForBar(value) {
        if (value <= 0)
            return 0;

        return Math.pow(value, 0.66);
    }

    function parseUsage(output) {
        try {
            var data = JSON.parse(output);
            usageData = data;
            balance = data.billing && data.billing.balance ? data.billing.balance : "";
            if (data.usage) {
                if (data.usage["5h"]) {
                    pct5h = Number(data.usage["5h"].current) || 0;
                    reset5h = data.usage["5h"].reset || "";
                }
                if (data.usage.weekly) {
                    pctWeekly = Number(data.usage.weekly.current) || 0;
                    resetWeekly = data.usage.weekly.reset || "";
                }
                if (data.usage.monthly) {
                    pctMonthly = Number(data.usage.monthly.current) || 0;
                    resetMonthly = data.usage.monthly.reset || "";
                }
            }
        } catch (e) {
            console.warn("[Opencode] Failed to parse usage:", e);
        }
    }

    Layout.preferredWidth: Config.buttonSize * 3.7
    Layout.preferredHeight: Config.buttonSize
    Layout.leftMargin: Config.gapOuter
    color: "transparent"

    Item {
        id: iconContainer

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Config.buttonSize * 0.7
        height: Config.buttonSize * 0.7

        Image {
            id: maskImage

            anchors.fill: parent
            source: "assets/opencode-logo.svg"
            sourceSize.width: width
            sourceSize.height: height
            smooth: true
            visible: false
        }

        Rectangle {
            id: fgColor

            anchors.fill: parent
            color: Config.foreground
            visible: false
        }

        OpacityMask {
            anchors.fill: parent
            source: fgColor
            maskSource: maskImage
        }

    }

    Item {
        id: battery5h

        anchors.left: iconContainer.right
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        width: 8
        height: Config.buttonSize * 0.55

        Rectangle {
            anchors.fill: parent
            radius: 2
            color: Config.foregroundSecondary

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 2
                width: parent.width - 4
                height: (parent.height - 4) * scaleForBar(Math.max(0, 1 - Math.min(Math.max(root.pct5h, 0), 100) / 100))
                radius: 1
                color: Config.foreground
            }

        }

    }

    Item {
        id: spinner

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Config.buttonSize * 0.7
        height: Config.buttonSize * 0.7

        readonly property var sqPositions: [
            Qt.point(5, 0),
            Qt.point(11, 0),
            Qt.point(17, 0),
            Qt.point(22, 5),
            Qt.point(22, 11),
            Qt.point(22, 17),
            Qt.point(17, 22),
            Qt.point(11, 22),
            Qt.point(5, 22),
            Qt.point(0, 17),
            Qt.point(0, 11),
            Qt.point(0, 5)
        ]

        property real headPhase: 0

        NumberAnimation on headPhase {
            from: 0
            to: 12
            duration: 2000
            running: true
            loops: Animation.Infinite
        }

        Repeater {
            model: 12

            Rectangle {
                readonly property int dist1: (Math.floor(spinner.headPhase) - index + 12) % 12
                readonly property int dist2: (Math.floor(spinner.headPhase + 6) - index + 12) % 12

                width: parent.width * 4 / 26
                height: width
                radius: width * 0.1
                color: Config.foreground
                x: parent.width * parent.sqPositions[index].x / 26
                y: parent.height * parent.sqPositions[index].y / 26

                readonly property real op1: dist1 === 0 ? 1.0 : dist1 === 1 ? 0.75 : dist1 === 2 ? 0.5 : dist1 === 3 ? 0.25 : 0
                readonly property real op2: dist2 === 0 ? 1.0 : dist2 === 1 ? 0.75 : dist2 === 2 ? 0.5 : dist2 === 3 ? 0.25 : 0
                opacity: Math.max(op1, op2, 0.1)
            }
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            var item = popupLoader.item;
            if (item && item.visible)
                item.visible = false;
            else if (!root.popupVisible)
                root.popupVisible = true;
        }
    }

    LazyLoader {
        id: popupLoader

        active: root.popupVisible

        PopupWindow {
            id: popup

            visible: true
            anchor.window: root.barWindow
            implicitWidth: 340
            implicitHeight: 250
            color: "transparent"
            onVisibleChanged: {
                if (!visible && root.popupVisible)
                    root.popupVisible = false;

            }
            Component.onCompleted: {
                if (root.barWindow) {
                    var pos = root.mapToItem(root.barWindow.contentItem, 0, 0);
                    anchor.rect.x = pos.x;
                    anchor.rect.y = pos.y + root.height + Config.gapsOut + Config.borderSize;
                }
                root.fetchUsage();
            }

            Rectangle {
                id: popupBg

                anchors.fill: parent
                color: Config.backgroundColored
                radius: 5
                border.color: Config.accent
                border.width: Config.borderSize
                focus: true
                Keys.onEscapePressed: root.popupVisible = false

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 0

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: "5H"
                                color: Config.foreground
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSize - 2
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "🗲 " + root.reset5h
                                color: Config.foreground
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSize - 2
                            }

                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            radius: 2
                            color: Config.foregroundSecondary

                            Rectangle {
                                x: 3
                                y: 3
                                height: parent.height - 6
                                radius: 1
                                width: (parent.width - 6) * Math.max(0, 1 - Math.min(Math.max(root.pct5h, 0), 100) / 100)
                                color: Config.foreground
                            }

                        }

                    }

                    Item {
                        Layout.preferredHeight: 10
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: "1W"
                                color: Config.foreground
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSize - 2
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "🗲 " + root.resetWeekly
                                color: Config.foreground
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSize - 2
                            }

                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            radius: 2
                            color: Config.foregroundSecondary

                            Rectangle {
                                x: 3
                                y: 3
                                height: parent.height - 6
                                radius: 1
                                width: (parent.width - 6) * Math.max(0, 1 - Math.min(Math.max(root.pctWeekly, 0), 100) / 100)
                                color: Config.foreground
                            }

                        }

                    }

                    Item {
                        Layout.preferredHeight: 10
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: "1M"
                                color: Config.foreground
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSize - 2
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "🗲 " + root.resetMonthly
                                color: Config.foreground
                                font.family: Config.fontFamily
                                font.pixelSize: Config.fontSize - 2
                            }

                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            radius: 2
                            color: Config.foregroundSecondary

                            Rectangle {
                                x: 3
                                y: 3
                                height: parent.height - 6
                                radius: 1
                                width: (parent.width - 6) * Math.max(0, 1 - Math.min(Math.max(root.pctMonthly, 0), 100) / 100)
                                color: Config.foreground
                            }

                        }

                    }

                    Item {
                        Layout.preferredHeight: 16
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Rectangle {
                            Layout.preferredHeight: balanceLabel.height + 8
                            Layout.preferredWidth: balanceLabel.width + 16
                            radius: 2
                            color: Config.foreground

                            Text {
                                id: balanceLabel

                                anchors.centerIn: parent
                                text: "BALANCE " + (root.balance || "...")
                                color: Config.backgroundColored
                                font.family: Config.fontFamily
                                font.weight: Font.Medium
                                font.pixelSize: Config.fontSize - 2
                            }

                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            color: dashboardLinkMouse.containsMouse ? Config.foreground : "transparent"
                            Layout.preferredHeight: Config.buttonSize
                            implicitWidth: dashboardLink.implicitWidth + 16
                            radius: 1

                            Text {
                                id: dashboardLink

                                text: "OPEN DASHBOARD ↗"
                                anchors.centerIn: parent
                                color: dashboardLinkMouse.containsMouse ? Config.backgroundColored : Config.foreground
                                font.family: Config.fontFamily
                                font.weight: Font.Medium
                                font.pixelSize: Config.fontSize - 2
                            }

                            MouseArea {
                                id: dashboardLinkMouse

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: Quickshell.execDetached(["xdg-open", "https://opencode.ai/workspace/" + root.workspaceId + "/go"])
                            }

                        }

                    }

                }

            }

        }

    }

    HyprlandFocusGrab {
        id: focusGrab

        active: root.popupVisible && popupLoader.item !== null
        windows: popupLoader.item ? [popupLoader.item] : []
        onCleared: {
            if (root.popupVisible)
                root.popupVisible = false;

        }
    }

    Process {
        id: usageProc

        command: ["bash", "-c", "source ~/.profile 2>/dev/null; opencode-usage"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.parseUsage(text)
        }

    }

}
