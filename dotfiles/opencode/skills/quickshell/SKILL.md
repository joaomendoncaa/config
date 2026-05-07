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

Use `Scope` when you need top-level state management without creating a window (panels, overlays, etc. are child windows). `ShellRoot` when the entry point itself is a window.

```qml
// Scope root — for shells with multiple child windows
import QtQuick
import Quickshell
import "shells" as Shells

Scope {
    id: root
    property bool searchOpen: false

    // Bar always visible
    Shells.Bar {
        searchOpen: root.searchOpen
        onToggleSearch: root.searchOpen = !root.searchOpen
    }

    // Lazy-loaded modal overlay
    LazyLoader {
        id: searchLoader
        active: root.searchOpen
        Shells.Search {
            visible: true
            onDismissed: root.searchOpen = false
        }
    }

    // Focus grab so clicking outside dismisses the overlay
    HyprlandFocusGrab {
        active: root.searchOpen && searchLoader.item !== null
        windows: searchLoader.item ? [searchLoader.item] : []
        onCleared: root.searchOpen = false
    }
}
```

**Key points about `Scope` patterns:**
- State flows down as properties, events flow up as signals
- `props down, events up` — child windows expose signals the scope handles
- `HyprlandFocusGrab` with `onCleared` provides natural dismissal for modals
- `LazyLoader` avoids creating overlay windows until they're needed, then destroys them on hide

### Config Singleton Pattern

Use `pragma Singleton` at the top of a `QtObject` to make it globally accessible. No special base class needed — plain `QtObject` works.

**config.qml:**
```qml
import QtQuick
pragma Singleton

QtObject {
    readonly property int height: 30
    readonly property int fontSize: 16
    property string foreground: "white"
    property string accent: "#509475"
    property string foregroundSecondary: "#60FFFFFF"
    property string background: "transparent"
    property string backgroundColored: "#000000"
    property string backgroundHovered: "#40FFFFFF"
}
```

**Usage** — works automatically in any file that shares the same module/import scope:
```qml
Rectangle {
    implicitHeight: Config.height
    color: Config.background
}
```

In small standalone projects, `qmldir` can register singletons with explicit names (`singleton Config config.qml`). In Quickshell's module-discovery mode (`~/.config/quickshell/<name>/`), `pragma Singleton` alone is sufficient — the file is auto-discovered.

For filesystem-persisted config with `FileView` + `JsonAdapter`, see [Config Persistence](#config-persistence-pattern).

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

### Import As + Component Reuse

Use `import "...path" as Namespace` to instantiate components from subdirectories with different parameters:

```qml
import "../ai" as AI

AI.Session {
    state: "working"
    fillColor: Config.foreground
    initials: "BL"
}

AI.Session {
    state: "idle"
    fillColor: Config.accent
    initials: "BA"
}
```

Ideal for pure visual components instantiated multiple times with different params — keeps stateful logic in the container and presentation in the component.

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

**LazyLoader destroys on deactivate** — unlike `visible: false`, the component tree is fully torn down and recreated. `Component.onCompleted` re-fires each time `active` becomes `true`.

### PopupWindow Anchor Positioning

Position a `PopupWindow` relative to a button on a bar using `anchor.window` + `mapToItem`:

```qml
LazyLoader {
    active: root.popupVisible

    PopupWindow {
        visible: true
        anchor.window: root.barWindow
        implicitWidth: 340; implicitHeight: 250
        color: "transparent"

        onVisibleChanged: {
            if (!visible && root.popupVisible) root.popupVisible = false
        }

        Component.onCompleted: {
            var pos = root.mapToItem(root.barWindow.contentItem, 0, 0)
            anchor.rect.x = pos.x
            anchor.rect.y = pos.y + root.height + Config.gapsOut
        }

        Rectangle {
            anchors.fill: parent
            color: Config.backgroundColored
            border.color: Config.accent
            focus: true
            Keys.onEscapePressed: root.popupVisible = false
        }
    }
}
```

Combine with `HyprlandFocusGrab` for click-outside-to-dismiss (see [Entry Point](#entry-point)).

### Running Commands

**Fire-and-forget** (preferred for launching apps):
```qml
Quickshell.execDetached(["notify-send", "Hello"])
```

**Capture output** with `Process` + `StdioCollector`:
```qml
import Quickshell.Io

Process {
    id: proc
    command: ["bash", "-c", "pacman -Qu 2>/dev/null | wc -l"]
    running: false

    stdout: StdioCollector {
        onStreamFinished: {
            var count = parseInt(text.trim(), 10)
            if (!isNaN(count)) console.log("Updates:", count)
        }
    }
}
// Trigger: proc.running = true
```

`text` on `StdioCollector` is a **property** (not a method). `onStreamFinished` fires when the process completes.

**Multiline commands** use backtick strings:
```qml
command: ["bash", "-c", `
    updates=$(pacman -Qu 2>/dev/null | wc -l)
    echo "$updates"
`]
```

### IpcHandler (Quickshell IPC)

For cross-process communication between Quickshell instances or external scripts:

```qml
import Quickshell.Io

Rectangle {
    property bool isRecording: false

    IpcHandler {
        target: "recording"
        function setRecording(active: bool): void {
            root.isRecording = active
        }
    }
}
```

External scripts send messages with `quickshell ipc`:
```bash
quickshell ipc -c my-shell call recording setRecording true
quickshell ipc -c my-shell call recording setRecording false
```

### FileView — /proc Monitoring

Map filesystem files into QML for system monitoring. Use `blockLoading: true` + `Timer` polling + `Connections`:

```qml
import Quickshell.Io

FileView {
    id: statFile
    blockLoading: true       // non-blocking I/O
    path: "file:///proc/stat"
}

Timer { interval: 250; running: true; repeat: true
    onTriggered: statFile.reload()
}

Connections {
    target: statFile
    function onTextChanged() {
        if (statFile.loaded) {
            var cpu = parseCpuUsage(statFile.text())  // text() is a method
        }
    }
}
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

### Canvas 2D — Realtime Graphs

Use `Canvas` with ring buffer arrays for CPU/RAM monitoring graphs:

```qml
Canvas {
    id: canvas
    anchors.fill: parent

    onPaint: {
        var ctx = getContext('2d')
        ctx.clearRect(0, 0, width, height)

        // Solid line for CPU
        ctx.strokeStyle = Config.foreground
        ctx.setLineDash([])
        ctx.beginPath()
        for (var i = 0; i < historySize; i++) {
            var dataIdx = (writeIndex + i) % historySize
            var x = Math.round(i * (width - 1) / (historySize - 1))
            var y = (1 - cpuHistory[dataIdx]) * height
            if (i === 0) ctx.moveTo(x, y)
            else ctx.lineTo(x, y)
        }
        ctx.stroke()

        // Dashed for RAM:  ctx.setLineDash([4, 2])
        // Dotted for GPU:  ctx.setLineDash([1, 1])
    }
}
```

**Ring buffer:**
```qml
property var cpuHistory: new Array(historySize).fill(0.5)
property int writeIndex: 0

function pushSample(cpu) {
    cpuHistory[writeIndex] = Math.round(cpu * 10) / 10
    writeIndex = (writeIndex + 1) % historySize
}

Timer { interval: 250; running: true; repeat: true
    onTriggered: { pushSample(cpu); canvas.requestPaint() }
}
```

### Animation Patterns

**SequentialAnimation** for pulsing indicators (e.g., recording dot):
```qml
Text {
    text: "\u25CF"
    property real pulseOpacity: 1.0

    SequentialAnimation {
        running: isRecording
        loops: Animation.Infinite

        NumberAnimation {
            target: recordingText; property: "pulseOpacity"
            from: 1.0; to: 0.5; duration: 800
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: recordingText; property: "pulseOpacity"
            from: 0.5; to: 1.0; duration: 800
            easing.type: Easing.InOutSine
        }
    }
    opacity: recordingText.pulseOpacity
}
```

**Behavior transitions** for smooth property changes:
```qml
Behavior on implicitHeight { NumberAnimation { duration: 300 } }
Behavior on foreground { ColorAnimation { duration: 200 } }
```

### MouseArea Patterns

**Multi-button** (left/right/middle click for context actions):
```qml
MouseArea {
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    onClicked: function(mouse) {
        if (mouse.button === Qt.RightButton)
            Quickshell.execDetached(["loginctl", "lock-session"])
        else if (mouse.button === Qt.MiddleButton)
            Quickshell.execDetached(["audio-launcher"])
        else
            Quickshell.execDetached(["toggle-sink"])
    }
}
```

**Scroll wheel** for value adjustment (e.g., volume):
```qml
MouseArea {
    onWheel: function(wheel) {
        var step = 0.025
        var currentVol = Pipewire.defaultAudioSink.audio.volume
        var newVol = wheel.angleDelta.y > 0
            ? Math.min(1, currentVol + step)
            : Math.max(0, currentVol - step)
        Pipewire.defaultAudioSink.audio.volume = newVol
    }
}
```

## Module Architecture

For complex shells with multiple panels, overlays, and services, use a modular architecture with namespace imports and a shared context object.

### Project Layout

```
shell.qml                    # Entry — ShellRoot + Context + modules
Core/
  Config.qml                 # pragma Singleton — filesystem-persisted config
  Colors.qml                 # Theme colors, watches external colors.json
  Icons.qml                  # pragma Singleton — NerdFont codepoints
  Animations.qml             # pragma Singleton — duration/easing constants
  Ipc.qml                    # pragma Singleton — centralized Process orchestration
  GlobalState.qml            # Centralized state with toggle + closeAll
  Context.qml                # DI container — aggregates services + config
  Logger.qml                 # Debug logging utility
Modules/
  Bar/                       # Panel bar with widgets
    BarWindow.qml            # Variants multi-monitor wrapper
    Bar.qml                  # Main bar layout
    Widgets/                 # Bar-specific components
      Clock.qml, Media.qml, BatteryPill.qml, ...
  Lock/                      # Lockscreen module
    Lock.qml, LockScreen.qml, Cards/, Components/
  Overlays/                  # Modal overlays (launcher, clipboard, etc.)
  Settings/                  # Settings window
    SettingsWindow.qml, Pages/
  Panels/                    # Side panels, info panels
    SidePanel.qml, InfoPanel.qml, Views/
Services/                    # Service objects (non-visual)
  CpuService.qml, MemService.qml, VolumeService.qml,
  NetworkService.qml, WeatherService.qml, ...
Widgets/                     # Shared visual components
  Icon.qml, ToggleButton.qml, SliderControl.qml, ...
```

### Namespace Import Pattern

Two approaches for structuring imports:

**Simple / standalone** — `qmldir` at project root registers singletons and components. Modules import via relative paths:

```qml
// shell.qml
import "shells" as Shells

Scope {
    Shells.Bar { ... }
    Shells.Search { ... }
}
```

```qml
// In any component — Config is auto-available from qmldir registration
Rectangle { height: Config.height }
```

**Module architecture** (xenon-shell style) — Quickshell auto-discovers modules placed under `~/.config/quickshell/<name>/`. The directory name becomes the import prefix. No `qmldir` needed:

```
~/.config/quickshell/qs/     ← "qs" is the import prefix
  Core/
    Config.qml, Colors.qml, Context.qml, ...
  Modules/
    Bar/, Lock/, Overlays/, ...
  Services/
    CpuService.qml, VolumeService.qml, ...
```

```qml
// shell.qml
import Quickshell
import qs.Core
import qs.Modules.Bar

ShellRoot {
    Context { id: ctx }
    BarWindow { context: ctx }
}
```

Under the hood: Quickshell scans `~/.config/quickshell/` and adds each subdirectory as a QML import path. The directory name (`qs`) becomes the module qualifier. Subdirectories (`Core`, `Modules/Bar`) become sub-modules (`qs.Core`, `qs.Modules.Bar`). Types within each subdirectory are available by their filename (capitalized).

### Context — Dependency Injection Container

A shared context object aggregates all services and is passed to every module via `required property`:

```qml
// Core/Context.qml
import QtQuick
import qs.Core
import qs.Services

Item {
    property var config: Config
    property alias colors: colorsService
    property alias cpu: cpuService
    property alias mem: memService
    property alias time: timeService
    property alias volume: volumeService
    property alias appState: appStateService
    property var network: NetworkService

    Colors { id: colorsService }
    CpuService { id: cpuService }
    MemService { id: memService }
    TimeService { id: timeService }
    VolumeService { id: volumeService }
    GlobalState { id: appStateService }
}
```

**Consumer side:**
```qml
Variants {
    required property Context context
    model: Quickshell.screens

    PanelWindow {
        color: context.colors.bg
        visible: context.colors.isLoaded

        Bar {
            colors: context.colors
            fontFamily: context.config.fontFamily
            volumeLevel: context.volume.level
            globalState: context.appState
        }
    }
}
```

### GlobalState — Centralized Panel Coordination

For shells with multiple modal panels, use exclusive-open logic: only one panel open at a time.

```qml
QtObject {
    property bool launcherOpen: false
    property bool settingsOpen: false

    function toggleLauncher() {
        if (launcherOpen) { launcherOpen = false }
        else { closeAll(); launcherOpen = true }
    }

    function closeAll() {
        launcherOpen = false; settingsOpen = false
    }
}
```

### Service Layer

Extract data sources (`FileView`, `Process`, polling) into non-visual services. Components consume only the exposed properties:

```qml
// Services/CpuService.qml
Item {
    property real usage: 0

    FileView { id: statFile; blockLoading: true; path: "file:///proc/stat" }
    Timer { interval: 1000; running: true; repeat: true
        onTriggered: statFile.reload() }

    Connections { target: statFile
        function onTextChanged() { usage = parseCpuUsage(statFile.text()) } }
}
```

### Config Persistence Pattern

For user-facing settings, combine `FileView` + `JsonAdapter` with a debounced save timer and a `_loading` guard to prevent write-back loops:

```qml
FileView {
    id: configFile
    path: `${Quickshell.env("HOME")}/.config/myapp/config.json`
    watchChanges: true
    onLoaded: {
        _loading = true
        if (adapter.fontSize) root.fontSize = adapter.fontSize
        _loading = false
    }
    adapter: JsonAdapter { id: adapter; property int fontSize }
}

Timer { id: saveTimer; interval: 1000; onTriggered: root.save() }
onFontSizeChanged: { if (!_loading) saveTimer.restart() }
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

### Double-Layer OpacityMask (Two-Tone Icons)

For icons that show both a background layer (secondary color) and a foreground fill layer (primary color, proportional height):

```qml
Item {
    id: iconContainer
    visible: Pipewire.defaultAudioSink !== null

    // Shared mask (alpha only)
    Image {
        id: maskImage
        anchors.fill: parent
        source: "icon.svg"
        sourceSize.width: width; sourceSize.height: height
        smooth: true
        visible: false
    }

    // Layer 1: Background — full icon in secondary color
    Rectangle { id: bgColor; anchors.fill: parent
        color: Config.foregroundSecondary; visible: false }
    OpacityMask { anchors.fill: parent
        source: bgColor; maskSource: maskImage }

    // Layer 2: Foreground — same icon in primary color, clipped to volume height
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: parent.height * scaleForBar(volumeRatio)
        clip: true; color: "transparent"

        Item {
            anchors.bottom: parent.bottom
            width: parent.width; height: iconContainer.height  // FULL height!
            Rectangle { id: fgColor; anchors.fill: parent
                color: Config.foreground; visible: false }
            OpacityMask { anchors.fill: parent
                source: fgColor; maskSource: maskImage }
        }
    }
}
```

Key insight: the inner `Item` is **full height** (`iconContainer.height`), but the outer `Rectangle` clips it. This means the icon image is always at proper scale — only its visibility is cropped.

## Anti-Patterns

| Don't | Do Instead |
|-------|-----------|
| Use `PanelWindow.visible` to hide/show | Use `LazyLoader` with `active` to destroy/recreate |
| Hardcode screen names | Use `Quickshell.screens` and `Variants` |
| Use `Process.exec()` directly | Use `Process.running = true` for stateful or `Quickshell.execDetached()` for fire-and-forget |
| Forget `exclusiveZone: 0` for overlays | Set it explicitly so the compositor doesn't reserve space |
| Store per-window state in delegates | Use a shared `Scope` or `QtObject` context for multi-monitor sync |
| Call `text()` on `StdioCollector` before stream finishes | Use `onStreamFinished` signal |
| Recreate the same SVG mask per widget instance | Share one `Image { visible: false }` as the mask source across `OpacityMask` instances |
| Keep empty UI elements visible | Use `opacity: hasData ? 1 : 0` to hide components with no meaningful data |
| Sprinkle `Process`/`FileView` in every component | Extract into service objects; components consume properties only |
| Use `ColorOverlay` for SVG recoloring on transparent backgrounds | Use `OpacityMask` — it treats the SVG as pure alpha, ignoring fill color |
| Set `visible: false` on items needed as OpacityMask sources | Keep `visible: false` — OpacityMask still reads the texture even when hidden |
| Write config on every property change | Use a debounce `Timer` (1s) and a `_loading` guard to prevent write-back loops |
| Import singletons by filename | Use `pragma Singleton` in the file; Quickshell auto-discovers it |
| Use `pq:xx` qualified imports everywhere | Use `import ".."` relative paths for internal components for portability |

## Resources

- [Quickshell Examples](https://git.outfoxxed.me/quickshell/quickshell-examples)
- [Quickshell Source / Docs](https://git.outfoxxed.me/outfoxxed/quickshell)
- [Hyprland IPC](https://wiki.hyprland.org/IPC/) - for socket-based integration
