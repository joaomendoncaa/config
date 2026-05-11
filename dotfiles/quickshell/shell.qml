import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Modules.Bar
import qs.Modules.Search

Scope {
    id: root

    property bool searchOpen: false

    Bar {
        searchOpen: root.searchOpen
        onToggleSearch: root.searchOpen = !root.searchOpen
    }

    HyprlandFocusGrab {
        active: root.searchOpen && searchLoader.item !== null
        windows: searchLoader.item ? [searchLoader.item] : []
        onCleared: root.searchOpen = false
    }

    LazyLoader {
        id: searchLoader

        active: root.searchOpen

        Search {
            visible: true
            onDismissed: root.searchOpen = false
        }

    }

}
