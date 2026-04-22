---
name: quickshell
description: >
  Use when writing, debugging, or configuring Quickshell desktop shell widgets.
  Covers QML-based panels, bars, OSDs, lockscreens, and launchers on Wayland.
  Triggers: quickshell, qs, PanelWindow, ShellRoot, WlrLayershell, Hyprland IPC,
  Pipewire integration, multi-monitor widgets.
---

# Quickshell

Quickshell is a Qt/QML framework for building desktop shell components (bars, panels, OSDs, lockscreens, launchers) on Wayland compositors. It replaces tools like Waybar, wlogout, and swaylock with QML-based widgets.

## Quick Start

Install Quickshell, then create a `shell.qml` entry point and run it:

```bash
# Run the shell
quickshell -p shell.qml
# or shorthand
qs -p shell.qml
```

Minimal bar:

```qml
import QtQuick
import Quickshell

ShellRoot {
    PanelWindow {
        anchors {
            left: true
            top: true
            right: true
        }
        height: 30

        Rectangle {
            anchors.fill: parent
            color: "#1e1e1e"

            Text {
                anchors.centerIn: parent
                text: "Hello Quickshell"
                color: "white"
            }
        }
    }
}
```

## Key Concepts

### Entry Point
Every Quickshell project starts with a `shell.qml` file. The root element is usually `ShellRoot` for windows or `Scope` for non-window logic.

### Window Types

| Type | Use Case | Example |
|------|----------|---------|
| `PanelWindow` | Dock, bar, panel (docks to screen edges) | Top bar, bottom dock |
| `FloatingWindow` | Free-floating popup/widget | Mixer, settings window |

### Wayland Layer Shell
Quickshell uses `wlr-layer-shell` for window positioning. Key properties on `PanelWindow`:

```qml
PanelWindow {
    // Dock to edges
    anchors { top: true; left: true; right: true }

    // Reserve screen space (set to 0 for overlays)
    exclusiveZone: 30

    // Layer: Background, Bottom, Top, Overlay
    WlrLayershell.layer: WlrLayer.Top

    // Keyboard focus: None or Exclusive
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Ignore exclusion of other panels (for fullscreen overlays)
    exclusionMode: ExclusionMode.Ignore
}
```

### Multi-Monitor
Use `Variants` to create one window per screen:

```qml
import Quickshell

Variants {
    model: Quickshell.screens
    PanelWindow {
        screen: modelData
        // ...
    }
}
```

### Lazy Loading
Use `LazyLoader` to create windows only when needed, reducing memory usage:

```qml
property bool showPopup: false

LazyLoader {
    active: showPopup
    PanelWindow {
        // popup content
    }
}
```

### Running Commands
Use `Process` from `Quickshell.Io`:

```qml
import Quickshell.Io

Process {
    id: proc
    command: ["sh", "-c", "notify-send hello"]
}

// In a MouseArea:
onClicked: proc.startDetached()
```

### Socket IPC
Read from sockets (e.g., Hyprland IPC):

```qml
import Quickshell.Io

Socket {
    path: `/tmp/hypr/${Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")}/.socket2.sock`
    connected: true
    parser: SplitParser {
        onRead: msg => {
            // parse msg
        }
    }
}
```

### Icons
Use `Quickshell.iconPath()` or `image://icon/` URIs:

```qml
IconImage {
    source: Quickshell.iconPath("audio-volume-high-symbolic")
}

// Or in an Image:
Image {
    source: "image://icon/audio-volume-high-symbolic"
}
```

## Examples from Official Repo

The [quickshell-examples](https://git.outfoxxed.me/quickshell/quickshell-examples) repo contains reference implementations:

| Example | What it demonstrates |
|---------|---------------------|
| `volume-osd` | `LazyLoader`, `Pipewire` audio tracking, `PanelWindow` overlay, `Region {}` click mask |
| `wlogout` | `Variants` multi-monitor, `Process` commands, keyboard handling, grid layout |
| `lockscreen` | `WlSessionLock`, `Pam` authentication, shared `Scope` context, multi-surface sync |
| `mixer` | `FloatingWindow`, `Pipewire` node/link tracking, `Repeater` for dynamic lists |
| `reload-popup` | `Connections` to `Quickshell` reload signals, `LazyLoader`, timed dismissal |
| `focus_following_panel` | `Socket` Hyprland IPC, regex parsing, dynamic `screen` reassignment |
| `activate_linux` | Simple animation, implicit sizing |

### Local Examples

| Example | What it demonstrates |
|---------|---------------------|
| `examples/volume-icon.qml` | `OpacityMask` SVG recoloring, two-layer fill from bottom, Pipewire integration |

## Common Patterns

### OSD Overlay (click-through)
```qml
PanelWindow {
    exclusiveZone: 0
    color: "transparent"
    mask: Region {} // empty mask = click-through
}
```

### Screen Edge Margins
```qml
PanelWindow {
    anchors.bottom: true
    margins.bottom: screen.height / 5
}
```

### Keyboard Shortcuts in a Window
```qml
contentItem {
    focus: true
    Keys.onPressed: event => {
        if (event.key == Qt.Key_Escape) Qt.quit();
    }
}
```

### Reload Popup Handling
If you create a custom reload popup, call `Quickshell.inhibitReloadPopup()` to suppress the default one:

```qml
Connections {
    target: Quickshell
    function onReloadCompleted() {
        Quickshell.inhibitReloadPopup();
        // show custom success popup
    }
    function onReloadFailed(error: string) {
        Quickshell.inhibitReloadPopup();
        // show custom error popup
    }
}
```

## SVG Recoloring

### `ColorOverlay` vs `OpacityMask`

`ColorOverlay` multiplies tint color × source pixel color. If your SVG has `fill="white"` and your tint has alpha (e.g. `#60C1C497`), the result is semi-transparent white — invisible on a transparent background.

**Use `OpacityMask` instead.** It treats the SVG as a pure alpha mask and composites a colored `Rectangle` through it, ignoring the SVG's fill color entirely.

```qml
Image { id: mask; source: "icon.svg"; visible: false }
Rectangle { id: color; anchors.fill: parent; color: "red"; visible: false }

OpacityMask {
    anchors.fill: parent
    source: color
    maskSource: mask
}
```

### `visible: false` Trap

`ColorOverlay` needs the source rendered to a texture. `visible: false` prevents this **unless** the item is inside a `Rectangle { clip: true }`, which forces offscreen rendering. This is why a foreground inside a clipped container may work while a background outside it does not.

### Fill-from-Bottom Clip Pattern

For volume/battery indicators, use a short `Rectangle` with `clip: true` containing a **full-height** inner item anchored to the bottom:

```qml
Rectangle {
    anchors.bottom: parent.bottom
    height: parent.height * fillRatio
    clip: true
    color: "transparent"

    Item {
        anchors.bottom: parent.bottom
        height: iconContainer.height  // full height, not clipped height
        // ... icon content ...
    }
}
```

This clips the top off, creating a "fill from bottom" effect without squashing the icon.

## Anti-Patterns

| Don't | Do Instead |
|-------|-----------|
| Use `PanelWindow.visible` to hide/show | Use `LazyLoader` with `active` to destroy/recreate |
| Hardcode screen names | Use `Quickshell.screens` and `Variants` |
| Run `exec()` in a Process directly | Use `startDetached()` for fire-and-forget commands |
| Forget `exclusiveZone: 0` for overlays | Set it explicitly so the compositor doesn't reserve space |
| Store per-window state in delegates | Use a shared `Scope` or `QtObject` context for multi-monitor sync |

## Resources

- [Quickshell Examples](https://git.outfoxxed.me/quickshell/quickshell-examples)
- [Quickshell Source / Docs](https://git.outfoxxed.me/outfoxxed/quickshell)
- [Hyprland IPC](https://wiki.hyprland.org/IPC/) - for socket-based integration
