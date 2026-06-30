import QtQuick

Item {
    id: root

    property string text: ""
    property color textColor: "white"
    property string fontFamily: ""
    property int fontSize: 14
    property int pauseMs: 1500
    property int pxPerSec: 40

    clip: true

    property bool hovered: false

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: {
            root.hovered = false
            content.x = 0
        }
        cursorShape: Qt.IBeamCursor
    }

    Text {
        id: content

        text: root.text
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        verticalAlignment: Text.AlignVCenter
        anchors.verticalCenter: parent.verticalCenter

        readonly property bool needsScroll: content.implicitWidth > root.width
        readonly property real scrollDistance: Math.max(0, content.implicitWidth - root.width)
        readonly property int scrollDuration: Math.max(300, scrollDistance / root.pxPerSec * 1000)

        SequentialAnimation {
            id: scrollAnim

            loops: Animation.Infinite
            running: content.needsScroll && root.hovered

            PauseAnimation {
                duration: root.pauseMs
            }

            NumberAnimation {
                target: content
                property: "x"
                to: -content.scrollDistance
                duration: content.scrollDuration
                easing.type: Easing.Linear
            }

            PauseAnimation {
                duration: root.pauseMs
            }

            NumberAnimation {
                target: content
                property: "x"
                to: 0
                duration: content.scrollDuration
                easing.type: Easing.Linear
            }
        }

        onNeedsScrollChanged: {
            if (!needsScroll || !root.hovered)
                x = 0;
        }
    }
}
