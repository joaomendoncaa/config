import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Core

Item {
    id: searchInput

    property int modeIndex: 0
    property var modeNames: []
    property string filterText: ''
    property int cursorPosition: 0

    property int cursorBlink: 0

    Timer {
        interval: 530
        running: true
        repeat: true
        onTriggered: {
            searchInput.cursorBlink = searchInput.cursorBlink === 0 ? 1 : 0
        }
    }

    Row {
        id: searchRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Rectangle {
            id: modePill
            visible: modeIndex !== 0
            height: Config.fontSize + 6
            width: modePillLabel.width + 10
            radius: 3
            color: Config.accent

            Text {
                id: modePillLabel
                anchors.centerIn: parent
                text: modeNames[modeIndex]
                color: Config.foregroundSelected
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize - 2
            }
        }

        Item {
            width: modeIndex !== 0 ? 8 : 0
            height: 1
        }

        Text {
            id: textBefore
            text: filterText.length > 0
                ? filterText.substring(0, cursorPosition)
                : ''
            color: Config.foreground
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize
        }

        Rectangle {
            id: cursorRect
            width: 10
            height: Config.fontSize + 4
            color: Config.foreground
            visible: cursorBlink === 0
        }

        Text {
            id: textAfter
            visible: filterText.length > 0
            text: filterText.substring(cursorPosition)
            color: Config.foreground
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize
        }
    }
}
