import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core

Rectangle {
    id: root

    required property var service
    signal dismissed()

    readonly property int panelWidth: Math.round(Config.buttonSize * 34)
    readonly property int rowHeight: Math.round(Config.buttonSize * 1.65)
    readonly property int headerHeight: Math.round(Config.buttonSize * 2.2)
    readonly property int footerHeight: root.service.usageSupported ? Math.round(Config.buttonSize * 3.15) : 0
    readonly property int minimumPanelHeight: 440
    readonly property int visibleRows: Math.min(8, root.service.agentCount)
    readonly property int bodyRows: root.service.agentLoading || !root.service.agentAvailable || root.service.agentCount === 0 ? 3 : Math.max(1, root.visibleRows)
    readonly property int desiredHeight: Math.max(root.minimumPanelHeight, root.headerHeight + root.footerHeight + root.bodyRows * root.rowHeight)

    color: Config.backgroundColored
    radius: Config.borderRadius
    clip: true
    focus: true
    Keys.onEscapePressed: root.dismissed()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.headerHeight

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Config.shellPadding
                anchors.rightMargin: Config.shellPadding
                spacing: Config.gapInner * 2

                Text {
                    text: `${root.service.blockedCount} blocked`
                    color: Config.foreground
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                    font.weight: Font.Medium
                }

                Text {
                    text: `${root.service.pendingCount} pending`
                    color: Config.foreground
                    font.family: Config.fontFamily
                    font.pixelSize: Config.fontSize
                    font.weight: Font.Medium
                }

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.preferredWidth: Config.buttonSize
                    Layout.preferredHeight: Config.buttonSize
                    radius: Math.max(1, Math.round(Config.buttonBorderRadius / 2))
                    color: root.service.pinsHidden ? Config.foreground : (hidePinsMouse.containsMouse ? Config.backgroundHovered : 'transparent')

                    Image {
                        id: hidePinsMask
                        anchors.centerIn: parent
                        width: Config.buttonSize * 0.7
                        height: width
                        source: '../../../Assets/agent-pin-hidden.svg'
                        sourceSize.width: width
                        sourceSize.height: height
                        visible: false
                    }

                    Rectangle {
                        id: hidePinsColor
                        anchors.fill: hidePinsMask
                        color: root.service.pinsHidden ? Config.backgroundColored : Config.foreground
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: hidePinsMask
                        source: hidePinsColor
                        maskSource: hidePinsMask
                    }

                    MouseArea {
                        id: hidePinsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.service.togglePinsHidden()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: Config.buttonSize
                    Layout.preferredHeight: Config.buttonSize
                    visible: root.service.dashboardAvailable
                    radius: Math.max(1, Math.round(Config.buttonBorderRadius / 2))
                    color: dashboardMouse.containsMouse ? Config.backgroundHovered : 'transparent'

                    Image {
                        id: dashboardMask
                        anchors.centerIn: parent
                        width: Config.buttonSize * 0.7
                        height: width
                        source: '../../../Assets/agent-dashboard-open.svg'
                        sourceSize.width: width
                        sourceSize.height: height
                        visible: false
                    }

                    Rectangle {
                        id: dashboardColor
                        anchors.fill: dashboardMask
                        color: Config.foreground
                        visible: false
                    }

                    OpacityMask {
                        anchors.fill: dashboardMask
                        source: dashboardColor
                        maskSource: dashboardMask
                    }

                    MouseArea {
                        id: dashboardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.service.openDashboard()
                            root.dismissed()
                        }
                    }
                }
            }
        }

        Item {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: root.rowHeight
            clip: true

            ListView {
                anchors.fill: parent
                visible: root.service.agentAvailable && root.service.agentCount > 0
                clip: true
                model: root.service.agents
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                delegate: AgentRow {
                    required property int index
                    width: ListView.view.width
                    height: root.rowHeight
                    service: root.service
                    rowIndex: index
                    onActivated: root.dismissed()
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.service.agentLoading
                text: 'LOADING AGENTS...'
                color: Config.foregroundSecondary
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                font.weight: Font.Medium
            }

            Text {
                anchors.centerIn: parent
                visible: !root.service.agentLoading && !root.service.agentAvailable
                text: 'AGENT DATA UNAVAILABLE'
                color: Config.foreground
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                font.weight: Font.Medium
            }

            Text {
                anchors.centerIn: parent
                visible: root.service.agentAvailable && root.service.agentCount === 0
                text: 'NO LIVE AGENTS'
                color: Config.foregroundSecondary
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                font.weight: Font.Medium
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.footerHeight
            visible: root.service.usageSupported
            color: Config.backgroundColored

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Config.shellPadding
                anchors.rightMargin: Config.shellPadding
                anchors.topMargin: Config.gapInner * 2
                anchors.bottomMargin: Config.gapInner * 2
                spacing: Config.shellPadding
                visible: root.service.usageAvailable

                Repeater {
                    model: root.service.usageWindows

                    delegate: AgentUsageMeter {
                        required property var modelData
                        Layout.fillWidth: true
                        label: modelData.label
                        resetText: root.service.formatReset(modelData.resetAt)
                        actual: Number(modelData.actual) || 0
                        warning: Number(modelData.warning) || 0
                        hatchPhase: root.service.hatchPhase
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.service.usageLoading && !root.service.usageAvailable
                text: 'LOADING USAGE...'
                color: Config.foregroundSecondary
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                font.weight: Font.Medium
            }

            Text {
                anchors.centerIn: parent
                visible: !root.service.usageLoading && !root.service.usageAvailable
                text: 'USAGE UNAVAILABLE'
                color: Config.foreground
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                font.weight: Font.Medium
            }
        }
    }
}
