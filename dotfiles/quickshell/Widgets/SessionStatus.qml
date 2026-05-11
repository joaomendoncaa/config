import QtQuick

Item {
    id: root

    property string state: "working"
    property color fillColor: "white"
    property string initials: ""
    property real labelFontSize: 10
    property string labelFontFamily: "sans"

    readonly property bool validInitials: root.initials.length === 2

    readonly property var sqPositions: [
        Qt.point(5, 0), Qt.point(11, 0), Qt.point(17, 0),
        Qt.point(22, 5), Qt.point(22, 11), Qt.point(22, 17),
        Qt.point(17, 22), Qt.point(11, 22), Qt.point(5, 22),
        Qt.point(0, 17), Qt.point(0, 11), Qt.point(0, 5)
    ]

    property real headPhase: 0
    property real promptPhase: 0
    property real errorPhase: 12

    NumberAnimation on headPhase {
        from: 0
        to: 12
        duration: 2000
        running: root.state === "working"
        loops: Animation.Infinite
    }

    NumberAnimation on promptPhase {
        from: 0
        to: 12
        duration: 960
        running: root.state === "prompt"
        loops: Animation.Infinite
    }

    NumberAnimation on errorPhase {
        from: 12
        to: 0
        duration: 3000
        running: root.state === "error"
        loops: Animation.Infinite
    }

    Repeater {
        model: 12

        Rectangle {
            width: parent.width * 4 / 26
            height: width
            radius: width * 0.1
            color: root.fillColor
            x: parent.width * root.sqPositions[index].x / 26
            y: parent.height * root.sqPositions[index].y / 26

            opacity: {
                if (root.state === "working") {
                    var d1 = (Math.floor(root.headPhase) - index + 12) % 12
                    var d2 = (Math.floor(root.headPhase + 6) - index + 12) % 12
                    var o1 = d1 === 0 ? 1 : d1 === 1 ? 0.75 : d1 === 2 ? 0.5 : d1 === 3 ? 0.25 : 0
                    var o2 = d2 === 0 ? 1 : d2 === 1 ? 0.75 : d2 === 2 ? 0.5 : d2 === 3 ? 0.25 : 0
                    return Math.max(o1, o2, 0.1)
                }
                if (root.state === "prompt") {
                    var bp = Math.floor(root.promptPhase) % 12
                    if (index % 2 === 0 && (bp === 0 || bp === 2)) return 1
                    if (index % 2 !== 0 && (bp === 6 || bp === 8)) return 1
                    return 0.1
                }
                if (root.state === "error") {
                    var ed1 = (Math.floor(root.errorPhase) - index + 12) % 12
                    var ed2 = (Math.floor(root.errorPhase + 6) - index + 12) % 12
                    var eo1 = ed1 < 4 ? 1 : 0
                    var eo2 = ed2 < 4 ? 1 : 0
                    return Math.max(eo1, eo2, 0.1)
                }
                return 0.25
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.validInitials
        text: root.initials
        color: root.fillColor
        font.family: root.labelFontFamily
        font.pixelSize: root.state === "idle" ? root.labelFontSize * 1.5 : root.labelFontSize
        font.weight: Font.Bold
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    onInitialsChanged: {
        if (root.initials.length !== 2)
            console.error("[SessionStatus] initials must be exactly 2 characters, got:", JSON.stringify(root.initials))
    }
}
