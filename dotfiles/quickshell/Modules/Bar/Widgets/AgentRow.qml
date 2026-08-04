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

    color: rowMouse.containsMouse || pinMouse.containsMouse ? Config.backgroundHovered : (root.rowIndex % 2 === 0 ? Config.backgroundColoredSecondary : 'transparent')

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
            fillColor: Config.foreground
            fontFamily: Config.fontFamily
            fontSize: Config.fontSize
            runningFrame: root.service.runningFrame
            blockedFrame: root.service.blockedFrame
        }

        RowLayout {
            Layout.preferredWidth: Config.buttonSize * 8.5
            Layout.minimumWidth: Config.buttonSize * 6
            spacing: Config.gapInner

            Text {
                Layout.maximumWidth: Config.buttonSize * 4
                elide: Text.ElideRight
                text: root.modelData.repo
                textFormat: Text.PlainText
                color: Config.foreground
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                font.weight: Font.Bold
            }

            Text {
                visible: root.modelData.branch.length > 0
                text: '↳'
                color: Config.foregroundSecondary
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
            }

            Text {
                visible: root.modelData.branch.length > 0
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                elide: Text.ElideRight
                text: root.modelData.branch
                textFormat: Text.PlainText
                color: Config.foreground
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
            color: Config.foreground
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize
        }

        Text {
            Layout.preferredWidth: Config.buttonSize * 5
            horizontalAlignment: Text.AlignRight
            text: root.modelData.additions > 0 || root.modelData.deletions > 0 ? `+${root.modelData.additions} -${root.modelData.deletions}` : ''
            color: Config.foreground
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize
        }

        Rectangle {
            id: pinButton
            Layout.preferredWidth: Config.buttonSize
            Layout.preferredHeight: Config.buttonSize
            radius: Math.max(1, Math.round(Config.buttonBorderRadius / 2))
            color: root.pinned ? Config.foreground : (pinMouse.containsMouse ? Config.backgroundHovered : 'transparent')

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
                color: root.pinned ? Config.backgroundColored : Config.foreground
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
                cursorShape: Qt.PointingHandCursor
                onClicked: root.service.togglePin(root.modelData.id)
            }
        }
    }

}
