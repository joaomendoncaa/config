import QtQuick
import QtQuick.Layouts
import qs.Core
import "Widgets"

Item {
    id: root

    required property var notificationService

    property bool isRecording: false
    property bool showAux: true

    implicitWidth: row.implicitWidth
    implicitHeight: Config.buttonSize

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Config.gapInner

        Recording {
            isRecording: root.isRecording
            opacity: root.showAux ? 1 : 0
            enabled: root.showAux
        }

        Clock {
            notificationService: root.notificationService
        }

    }

}
