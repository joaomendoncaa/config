import QtQuick
import Quickshell
import Quickshell.Hyprland
import "shells" as Shells

Scope {
    id: root

    property bool searchOpen: false

    Shells.Bar {
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

        Shells.Search {
            visible: true
            onDismissed: root.searchOpen = false
        }

    }

}
