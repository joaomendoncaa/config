import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Modules.Bar.Widgets

Item {
    id: root

    property bool showAux: true
    property alias updatesItem: updates
    property alias zenmodeItem: zenmode

    implicitWidth: row.implicitWidth
    implicitHeight: Config.buttonSize

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Config.gapInner

        Recording {
            opacity: root.showAux ? 1 : 0
            enabled: root.showAux
        }

        Clock {
        }

        Updates {
            id: updates

            opacity: root.showAux ? 1 : 0
            enabled: root.showAux
        }

        Zen {
            id: zenmode

            opacity: root.showAux ? 1 : 0
            enabled: root.showAux
        }

    }

}
