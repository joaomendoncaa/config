import QtQuick

Item {
    id: root

    property string state: 'unknown'
    property color fillColor: 'white'
    property string fontFamily: 'monospace'
    property real fontSize: 16
    property int runningFrame: 0
    readonly property var runningFrames: ['⣶', '⣧', '⣏', '⡟', '⠿', '⢻', '⣹', '⣼']
    readonly property string glyph: {
        if (root.state === 'running')
            return root.runningFrames[root.runningFrame % root.runningFrames.length]
        if (root.state === 'idle')
            return '✓'
        return '?'
    }

    implicitWidth: stateText.implicitWidth
    implicitHeight: stateText.implicitHeight

    Text {
        id: stateText
        anchors.centerIn: parent
        text: root.glyph
        color: root.fillColor
        opacity: root.state === 'unknown' ? 0.6 : 1
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
