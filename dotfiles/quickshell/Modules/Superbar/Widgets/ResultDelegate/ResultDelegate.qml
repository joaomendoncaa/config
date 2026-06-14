import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Core

Rectangle {
    id: delegateRoot

    required property int index
    required property string type
    required property string label
    required property string detail
    required property string emojiChar
    required property string iconName
    required property string fullText
    required property string imagePath
    required property string mime

    property int selectedIndex: 0
    property var iconResolver: function(name) { return '' }

    signal itemClicked(int index)
    signal itemHovered(int index)

    readonly property bool isSelected: index === selectedIndex

    width: ListView.view.width
    height: 44
    radius: 3
    color: isSelected ? Config.accent : 'transparent'

    Row {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 10

        Item {
            width: 32
            height: parent.height

            Text {
                visible: type === 'emoji'
                text: emojiChar
                font.pixelSize: 22
                anchors.centerIn: parent
            }

            IconImage {
                visible: type === 'app'
                anchors.centerIn: parent
                implicitSize: 22
                source: iconResolver(iconName)
                asynchronous: true
            }

            Text {
                visible: type === 'file'
                text: '\uD83D\uDCC4'
                font.pixelSize: 18
                anchors.centerIn: parent
            }

            Text {
                visible: type === 'calc'
                text: '='
                font.pixelSize: 18
                anchors.centerIn: parent
            }

            Item {
                visible: type === 'clipboard'
                width: parent.height - 4
                height: parent.height - 4
                anchors.centerIn: parent
                clip: true

                Image {
                    visible: imagePath.length > 0
                    anchors.fill: parent
                    source: imagePath.length > 0 ? 'file://' + imagePath : ''
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                }

                Rectangle {
                    visible: imagePath.length === 0
                    anchors.centerIn: parent
                    width: 16; height: 20; radius: 2
                    color: 'transparent'
                    border.color: isSelected ? Config.foregroundSelected : Config.foreground
                    border.width: 2
                }
            }
        }

        Column {
            width: parent.width - 32 - 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: type === 'clipboard' ? label : label
                color: isSelected ? Config.foregroundSelected : Config.foreground
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: detail.length > 0
                text: detail
                color: isSelected ? Config.foregroundSelected : Config.foregroundSecondary
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize - 4
                opacity: 0.7
                elide: Text.ElideRight
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: {
            if (containsMouse) itemHovered(index)
        }
        onClicked: itemClicked(index)
    }
}
