import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Qt5Compat.GraphicalEffects

// VolumeIcon.qml
//
// A reusable two-layer volume icon using SVG + OpacityMask.
// Demonstrates proper SVG recoloring without ColorOverlay pitfalls.
//
// Usage:
//   VolumeIcon {
//       anchors.centerIn: parent
//       width: 26
//       height: 26
//       volumeRatio: Pipewire.defaultAudioSink?.audio?.volume ?? 0
//       iconSource: "assets/volume.svg"
//       backgroundColor: Config.foregroundSecondary
//       foregroundColor: Config.foreground
//   }

Item {
    id: root

    property real volumeRatio: 0
    property string iconSource: ""
    property color backgroundColor: "#60FFFFFF"
    property color foregroundColor: "white"

    // Shared mask image (alpha only)
    Image {
        id: maskImage

        anchors.fill: parent
        source: root.iconSource
        sourceSize.width: width
        sourceSize.height: height
        smooth: true
        visible: false
    }

    // Background layer: full icon in secondary color
    Rectangle {
        id: bgColor

        anchors.fill: parent
        color: root.backgroundColor
        visible: false
    }

    OpacityMask {
        anchors.fill: parent
        source: bgColor
        maskSource: maskImage
    }

    // Foreground layer: same icon in primary color, clipped to volume height
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: parent.height * Math.max(0, Math.min(1, root.volumeRatio))
        clip: true
        color: "transparent"

        Item {
            anchors.bottom: parent.bottom
            width: parent.width
            height: root.height

            Rectangle {
                id: fgColor

                anchors.fill: parent
                color: root.foregroundColor
                visible: false
            }

            OpacityMask {
                anchors.fill: parent
                source: fgColor
                maskSource: maskImage
            }
        }
    }
}
