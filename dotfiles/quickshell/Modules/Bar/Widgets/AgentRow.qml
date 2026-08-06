import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import qs.Core
import "../../../Widgets"

Rectangle {
    id: root

    required property var service
    required property var modelData
    required property int rowIndex
    signal activated()

    readonly property bool pinned: root.service.isPinned(root.modelData.id)
    readonly property bool autoPinned: root.service.isAutoPinned(root.modelData.id)
    readonly property bool warningFlash: root.modelData.state === 'blocked' && root.service.blockedWarningFrame

    color: root.warningFlash ? Config.foreground : (rowMouse.containsMouse || pinMouse.containsMouse ? Config.backgroundHovered : (root.rowIndex % 2 === 0 ? Config.backgroundColoredSecondary : 'transparent'))

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.service.focusAgent(root.modelData.id)
            root.activated()
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Config.shellPadding
        anchors.rightMargin: Config.shellPadding
        spacing: Config.gapInner * 2

        AgentStatus {
            Layout.preferredWidth: Config.buttonSize * 0.7
            Layout.preferredHeight: Config.buttonSize
            state: root.modelData.state
            fillColor: root.warningFlash ? Config.backgroundColored : Config.foreground
            fontFamily: Config.fontFamily
            fontSize: Config.fontSize
            runningFrame: root.service.runningFrame
            blockedFrame: root.service.blockedFrame
        }

        RowLayout {
            Layout.fillWidth: false
            Layout.preferredWidth: Config.buttonSize * 8.5
            Layout.minimumWidth: Config.buttonSize * 6
            spacing: Config.gapInner

            Text {
                Layout.preferredWidth: Config.buttonSize * 4
                Layout.maximumWidth: Config.buttonSize * 4
                elide: Text.ElideRight
                text: root.modelData.repo
                textFormat: Text.PlainText
                color: root.warningFlash ? Config.backgroundColored : Config.foreground
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                font.weight: Font.Bold
            }

            Text {
                opacity: root.modelData.branch.length > 0 ? 1 : 0
                text: '↳'
                color: root.warningFlash ? Config.backgroundColored : Config.foregroundSecondary
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
            }

            Text {
                opacity: root.modelData.branch.length > 0 ? 1 : 0
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                elide: Text.ElideRight
                text: root.modelData.branch
                textFormat: Text.PlainText
                color: root.warningFlash ? Config.backgroundColored : Config.foreground
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                font.weight: Font.Bold
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            elide: Text.ElideRight
            text: root.modelData.title
            textFormat: Text.PlainText
            color: root.warningFlash ? Config.backgroundColored : Config.foreground
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize
        }

        Text {
            Layout.preferredWidth: Config.buttonSize * 5
            horizontalAlignment: Text.AlignRight
            text: root.modelData.additions > 0 || root.modelData.deletions > 0 ? `+${root.modelData.additions} -${root.modelData.deletions}` : ''
            color: root.warningFlash ? Config.backgroundColored : Config.foreground
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize
        }

        Rectangle {
            id: pinButton
            Layout.preferredWidth: Config.buttonSize
            Layout.preferredHeight: Config.buttonSize
            radius: Math.max(1, Math.round(Config.buttonBorderRadius / 2))
            color: root.warningFlash ? Config.backgroundColored : (root.pinned ? Config.foreground : (pinMouse.containsMouse ? Config.backgroundHovered : 'transparent'))

            Image {
                id: pinMask
                anchors.centerIn: parent
                width: Config.buttonSize * 0.7
                height: width
                source: '../../../Assets/solana-pin.svg'
                sourceSize.width: width
                sourceSize.height: height
                visible: false
            }

            Rectangle {
                id: pinColor
                anchors.fill: pinMask
                color: root.warningFlash ? Config.foreground : (root.pinned ? Config.backgroundColored : Config.foreground)
                visible: false
            }

            OpacityMask {
                anchors.fill: pinMask
                source: pinColor
                maskSource: pinMask
                opacity: root.pinned ? 1 : 0.55
            }

            MouseArea {
                id: pinMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.autoPinned ? Qt.ArrowCursor : Qt.PointingHandCursor
                onClicked: root.service.togglePin(root.modelData.id)
            }
        }
    }

}
