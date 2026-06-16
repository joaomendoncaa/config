import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Core

Item {
    id: searchInput

    property string mode: "apps"
    property string filterText: ''
    property int cursorPosition: 0

    property int cursorBlink: 0

    Timer {
        interval: Config.cursorBlinkInterval
        running: true
        repeat: true
        onTriggered: {
            searchInput.cursorBlink = searchInput.cursorBlink === 0 ? 1 : 0
        }
    }

    Row {
        id: searchRow
        spacing: 0

        Rectangle {
            id: modePill
            visible: mode !== "apps"
            height: Config.fontSize + 6
            width: modePillLabel.width + 10
            radius: 3
            color: Config.accent

            Text {
                id: modePillLabel
                anchors.centerIn: parent
                text: mode
                color: Config.foregroundSelected
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize - 2
            }
        }

        Item {
            width: mode !== "apps" ? 8 : 0
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

        Text {
            id: charWidth
            visible: false
            text: ' '
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize
        }

        Item {
            id: cursorItem
            width: charWidth.width
            height: cursorChar.implicitHeight

            Rectangle {
                id: cursorRect
                anchors.fill: parent
                color: Config.foreground
                visible: cursorBlink === 0
            }

            Text {
                id: cursorChar
                visible: cursorPosition < filterText.length
                text: cursorPosition < filterText.length ? filterText[cursorPosition] : ''
                color: cursorBlink === 0 ? Config.backgroundColored : Config.foreground
                font.family: Config.fontFamily
                font.pixelSize: Config.fontSize
            }
        }

        Text {
            id: textAfter
            visible: cursorPosition < filterText.length
            text: filterText.substring(cursorPosition + 1)
            color: Config.foreground
            font.family: Config.fontFamily
            font.pixelSize: Config.fontSize
        }
    }
}
