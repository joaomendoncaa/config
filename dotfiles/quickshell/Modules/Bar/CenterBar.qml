import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Modules.Bar.Widgets

Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: Config.buttonSize

    property bool showAux: true

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Config.gapInner

        Recording { opacity: root.showAux ? 1 : 0; enabled: root.showAux }
        Clock { }
        Updates { opacity: root.showAux ? 1 : 0; enabled: root.showAux }
    }
}
