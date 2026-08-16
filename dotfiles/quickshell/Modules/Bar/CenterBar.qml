import QtQuick
import QtQuick.Layouts
import qs.Core
import "Widgets"

Item {
    id: root

    property var notificationService: null

    implicitWidth: row.implicitWidth
    implicitHeight: Config.buttonSize

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Config.gapInner

        Clock {
            notificationService: root.notificationService
        }

    }

}
