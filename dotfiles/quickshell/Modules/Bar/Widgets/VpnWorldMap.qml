import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs.Core

// Interactive world map rendered from Assets/world-map.json (preprocessed
// from flekschas/simple-world-map, CC BY-SA 3.0).
//
//  - Every country is drawn as filled Shape paths.
//  - Available VPN countries are highlighted with Config.backgroundColoredTertiary.
//  - The connected country is highlighted with Config.accent, the country
//    pending a connect gets the same treatment while the CLI is busy.
//  - Hovering an interactive country reports it via hoveredCode so the panel
//    header can show the country name.
//  - Clicking an interactive country emits countryClicked(code).
//  - Scroll wheel zooms in/out (anchored at the cursor), capped between the
//    full-fit view and a close-up where individual countries are readable.
//    Middle-button drag pans around while zoomed in.
//
// Hit-testing is done in JS with ray casting against polygons parsed from the
// SVG path data (the source SVG only uses M/L/H/V/z commands, so every path is
// a pure polygon).
Item {
    id: root

    required property var service

    // Two-letter codes (lowercase) of countries offered by the VPN provider.
    readonly property var availableCodes: {
        var out = []
        var cs = root.service.countries || []
        for (var i = 0; i < cs.length; i++) {
            var code = (cs[i].code || "").toLowerCase()
            if (code.length === 2)
                out.push(code)
        }
        return out
    }

    readonly property string connectedCode: root.service.countryCode.toLowerCase()
    // Country the user clicked while a connect is in flight.
    property string pendingCode: ""

    // Code of the interactive country currently under the mouse ("" if none).
    property string hoveredCode: ""
    readonly property bool hoveringAvailable: root.isAvailable(root.hoveredCode) || root.hoveredCode === root.connectedCode

    // Map aspect ratio comes from the SVG viewBox (x=30.767 y=241.591 w=784.077 h=458.627).
    // Path coordinates are NOT relative to (0, 0) - the viewBox min must be
    // translated away or the map renders offset and overflows the panel.
    readonly property real viewBoxX: 30.767
    readonly property real viewBoxY: 241.591
    readonly property real mapWidth: mapData.width
    readonly property real mapHeight: mapData.height
    readonly property real mapScale: width / root.mapWidth
    readonly property real mapDisplayHeight: root.mapHeight * root.mapScale

    // Zoom/pan state. zoom 1.0 fits the whole map (identical to the old view);
    // scrolling zooms toward the cursor so the pointed country stays put, and
    // middle-button drag pans while zoomed in. pan* are clamped so the map
    // never leaves a gap inside the viewport.
    readonly property real minZoom: 1.0
    readonly property real maxZoom: 10.0
    property real zoom: 1.0
    property real panX: 0
    property real panY: 0
    readonly property real contentScale: root.mapScale * root.zoom

    function clampPan() {
        var minX = root.width - root.mapWidth * root.contentScale
        var minY = root.height - root.mapHeight * root.contentScale
        // At zoom 1 both bounds collapse to 0, forcing the full-fit view.
        root.panX = Math.min(0, Math.max(minX, root.panX))
        root.panY = Math.min(0, Math.max(minY, root.panY))
    }

    onZoomChanged: root.clampPan()
    onWidthChanged: root.clampPan()

    // Screen px -> SVG path coords (undo pan+scale, then the viewBox offset).
    function screenToMap(px, py) {
        return Qt.point((px - root.panX) / root.contentScale + root.viewBoxX, (py - root.panY) / root.contentScale + root.viewBoxY)
    }

    property var mapData: ({
        width: 784.077,
        height: 458.627,
        countries: []
    })

    // Flat render model: one entry per SVG path ({code, d}). ShapePath is not
    // an Item, so a per-country Repeater with a ShapePath delegate is not
    // possible; instead every path becomes its own Shape colored by country.
    property var pathModel: []

    onMapDataChanged: {
        var paths = []
        var cs = root.mapData.countries
        for (var i = 0; i < cs.length; i++)
            for (var j = 0; j < cs[i].paths.length; j++)
                paths.push({
                    code: cs[i].id,
                    d: cs[i].paths[j]
                })
        root.pathModel = paths
    }

    // code -> array of polygons (each an array of [x, y] in map units).
    // Only interactive countries are parsed; hit-testing iterates these.
    property var polygons: ({})

    signal countryClicked(string code)

    function isAvailable(code) {
        return root.availableCodes.indexOf(code) !== -1
    }

    function isInteractive(code) {
        return code.length === 2 && (root.isAvailable(code) || code === root.connectedCode)
    }

    // SVG path parser. The source map only contains M/m, L/l, H/h, V/v and
    // z/Z, so each subpath is a closed polygon of straight segments.
    function parsePolygons(d) {
        var polys = []
        var cur = []
        var tokens = String(d).match(/[MmLlHhVvZz]|[+-]?(?:\d*\.\d+|\d+)(?:[eE][+-]?\d+)?/g)
        if (!tokens)
            return polys
        var x = 0
        var y = 0
        var cmd = ""
        var i = 0
        while (i < tokens.length) {
            var t = tokens[i]
            if (/[A-Za-z]/.test(t)) {
                cmd = t
                i++
                continue
            }
            if (cmd === "M") {
                x = parseFloat(tokens[i++])
                y = parseFloat(tokens[i++])
                cur = [[x, y]]
                cmd = "L"
            } else if (cmd === "m") {
                x += parseFloat(tokens[i++])
                y += parseFloat(tokens[i++])
                cur = [[x, y]]
                cmd = "l"
            } else if (cmd === "L") {
                x = parseFloat(tokens[i++])
                y = parseFloat(tokens[i++])
                cur.push([x, y])
            } else if (cmd === "l") {
                x += parseFloat(tokens[i++])
                y += parseFloat(tokens[i++])
                cur.push([x, y])
            } else if (cmd === "H") {
                x = parseFloat(tokens[i++])
                cur.push([x, y])
            } else if (cmd === "h") {
                x += parseFloat(tokens[i++])
                cur.push([x, y])
            } else if (cmd === "V") {
                y = parseFloat(tokens[i++])
                cur.push([x, y])
            } else if (cmd === "v") {
                y += parseFloat(tokens[i++])
                cur.push([x, y])
            } else if (cmd === "z" || cmd === "Z") {
                if (cur.length > 2)
                    polys.push(cur)
                cur = []
                cmd = ""
            } else {
                i++
            }
        }
        if (cur.length > 2)
            polys.push(cur)
        return polys
    }

    function ensurePolygons(code) {
        if (root.polygons[code])
            return
        var cs = root.mapData.countries
        for (var i = 0; i < cs.length; i++) {
            if (cs[i].id !== code)
                continue
            var polys = []
            for (var j = 0; j < cs[i].paths.length; j++) {
                var p = root.parsePolygons(cs[i].paths[j])
                for (var k = 0; k < p.length; k++)
                    polys.push(p[k])
            }
            var next = root.polygons
            next[code] = polys
            root.polygons = next
            return
        }
    }

    // Ray-casting point-in-polygon test. pt is in map units.
    function polygonContains(poly, px, py) {
        var inside = false
        for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
            var xi = poly[i][0]
            var yi = poly[i][1]
            var xj = poly[j][0]
            var yj = poly[j][1]
            if (((yi > py) !== (yj > py)) && (px < (xj - xi) * (py - yi) / (yj - yi) + xi))
                inside = !inside
        }
        return inside
    }

    // Returns the interactive country code at the given point (map units),
    // or "" when the point is over ocean / a non-interactive country.
    function countryAt(px, py) {
        var codes = []
        if (root.isAvailable(root.pendingCode))
            codes.push(root.pendingCode)
        if (root.connectedCode.length === 2)
            codes.push(root.connectedCode)
        for (var i = 0; i < root.availableCodes.length; i++)
            if (codes.indexOf(root.availableCodes[i]) === -1)
                codes.push(root.availableCodes[i])
        for (var c = 0; c < codes.length; c++) {
            root.ensurePolygons(codes[c])
            var polys = root.polygons[codes[c]] || []
            for (var p = 0; p < polys.length; p++)
                if (root.polygonContains(polys[p], px, py))
                    return codes[c]
        }
        return ""
    }

    function countryName(code) {
        var cs = root.mapData.countries
        for (var i = 0; i < cs.length; i++)
            if (cs[i].id === code)
                return cs[i].name
        return code.toUpperCase()
    }

    FileView {
        id: mapFile

        path: Quickshell.env("HOME") + "/.config.jmmm.sh/dotfiles/quickshell/Assets/world-map.json"
        blockLoading: true
        onLoaded: {
            try {
                root.mapData = JSON.parse(mapFile.text())
            } catch (e) {
                console.warn("[VpnWorldMap] Failed to parse world-map.json:", e)
            }
        }
    }

    clip: true

    // The whole map is laid out at native SVG size and scaled down as one
    // item so stroke widths stay proportional. Pan and zoom live on two
    // SEPARATE nested items: combining translate+scale on a single item
    // (via x/y/scale properties or a transform list) made the rendered map
    // drift out of sync with the pan/zoom state, which broke the first zoom
    // step and cursor hit-testing while zoomed in. Split across items, each
    // transform is trivial and the two can never disagree.
    Item {
        id: mapPanner

        x: root.panX
        y: root.panY

        Item {
            id: mapContent

            width: root.mapWidth
            height: root.mapHeight
            scale: root.contentScale
            transformOrigin: Item.TopLeft

        // Shift path coordinates (which start at the viewBox min) to item space.
        Item {
            x: -root.viewBoxX
            y: -root.viewBoxY

            Repeater {
                model: root.pathModel

                Shape {
                    id: countryShape

                    required property var modelData
                    readonly property string code: modelData.code
                    readonly property bool isConnected: code === root.connectedCode
                    readonly property bool isPending: code === root.pendingCode && root.service.busy
                    readonly property bool isAvailable: root.isAvailable(code)
                    readonly property bool isHovered: code === root.hoveredCode
                    // Interactive countries above the rest so their strokes are
                    // never covered by neighbors painted later.
                    readonly property real zOrder: root.isInteractive(code) ? 2 : 1
                    // Writable (not readonly) so the Behavior below is allowed;
                    // the value is still binding-driven.
                    property color fillColor: {
                        if (isConnected || isPending)
                            return isHovered ? Config.lighten(Config.accent, 0.15) : Config.accent
                        if (isAvailable)
                            return isHovered ? Config.lighten(Config.backgroundColoredTertiary, 0.18) : Config.backgroundColoredTertiary
                        return Config.backgroundColoredSecondary
                    }

                    z: zOrder
                    width: root.mapWidth
                    height: root.mapHeight

                    Behavior on fillColor {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    ShapePath {
                        strokeWidth: 1.2
                        strokeColor: Config.backgroundColored
                        fillColor: countryShape.fillColor
                        PathSvg {
                            path: countryShape.modelData.d
                        }
                    }
                }
            }
        }
        }
    }

    // Single hit-testing mouse area: bounding-box MouseAreas per country would
    // misfire constantly (e.g. Canada's box swallows the US).
    MouseArea {
        id: mapMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.hoveringAvailable ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        // Middle-button drag state for panning.
        property bool panning: false
        property point pressPos
        property point pressPan

        // Last known pointer position inside the map, plus whether it can be
        // trusted. When the panel opens under the cursor, Qt/Wayland delivers
        // a synthetic hover event with bogus coordinates (observed as 0,0)
        // before any real motion - anchoring the first zoom step to that made
        // it zoom toward the top-left corner. Only positions arriving as real
        // motion inside the viewport are trusted; anything else falls back to
        // the last trusted spot, the wheel event coords, then the center.
        property point mousePos: Qt.point(root.width / 2, root.height / 2)
        property bool positionValid: false

        // Best available guess of where the cursor is. Preference order:
        // trusted hover tracking -> wheel event coords (skipped when they are
        // the bogus 0,0 synthetic-enter values) -> viewport center.
        function wheelAnchor(wx, wy) {
            if (mapMouse.positionValid)
                return mapMouse.mousePos
            var sane = wx > 0 && wx < root.width && wy > 0 && wy < root.height
            return sane ? Qt.point(wx, wy) : Qt.point(root.width / 2, root.height / 2)
        }

        onWheel: function(wheel) {
            var newZoom = wheel.angleDelta.y > 0 ? Math.min(root.maxZoom, root.zoom * 1.25) : Math.max(root.minZoom, root.zoom / 1.25)
            if (newZoom === root.zoom)
                return
            // Keep the map point currently under the cursor fixed while
            // zooming, so scrolling steers toward where you are pointing.
            var anchor = mapMouse.wheelAnchor(wheel.x, wheel.y)
            // TEMP DEBUG: remove once first-zoom anchoring is confirmed fixed.
            console.log("[map] WHEEL ev=" + wheel.x + "," + wheel.y + " valid=" + mapMouse.positionValid + " tracked=" + mapMouse.mousePos.x + "," + mapMouse.mousePos.y + " anchor=" + anchor.x + "," + anchor.y + " viewport=" + root.width + "x" + root.height + " zoom:" + root.zoom + "->" + newZoom)
            var ratio = newZoom / root.zoom
            root.panX = anchor.x - (anchor.x - root.panX) * ratio
            root.panY = anchor.y - (anchor.y - root.panY) * ratio
            root.zoom = newZoom
            root.clampPan()
            // TEMP DEBUG: ask Qt where the pivot point actually rendered.
            var lp = Qt.point((anchor.x - root.panX) / root.contentScale, (anchor.y - root.panY) / root.contentScale)
            var sp = mapContent.mapToItem(root, lp.x, lp.y)
            console.log("[map] RENDER anchor=" + anchor.x + "," + anchor.y + " qtReports=" + sp.x.toFixed(2) + "," + sp.y.toFixed(2) + " pan=" + root.panX.toFixed(2) + "," + root.panY.toFixed(2))
            var pt = root.screenToMap(anchor.x, anchor.y)
            root.hoveredCode = root.countryAt(pt.x, pt.y)
        }

        onPressed: function(mouse) {
            if (mouse.button !== Qt.MiddleButton || root.zoom <= root.minZoom)
                return
            mapMouse.panning = true
            mapMouse.pressPos = Qt.point(mouse.x, mouse.y)
            mapMouse.pressPan = Qt.point(root.panX, root.panY)
            mapMouse.cursorShape = Qt.ClosedHandCursor
        }

        onReleased: function(mouse) {
            if (mouse.button !== Qt.MiddleButton)
                return
            mapMouse.panning = false
            mapMouse.cursorShape = root.hoveringAvailable ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        onPositionChanged: function(mouse) {
            // Reject synthetic/out-of-view events so they can't poison the
            // zoom anchor; see the note on mousePos above.
            var inside = mouse.x > 0 && mouse.y > 0 && mouse.x < root.width && mouse.y < root.height
            // TEMP DEBUG: remove once first-zoom anchoring is confirmed fixed.
            console.log("[map] POS ev=" + mouse.x + "," + mouse.y + " inside=" + inside + " valid=" + mapMouse.positionValid)
            if (inside) {
                mapMouse.mousePos = Qt.point(mouse.x, mouse.y)
                mapMouse.positionValid = true
            }
            if (mapMouse.panning) {
                root.panX = mapMouse.pressPan.x + (mouse.x - mapMouse.pressPos.x)
                root.panY = mapMouse.pressPan.y + (mouse.y - mapMouse.pressPos.y)
                root.clampPan()
                return
            }
            var pt = root.screenToMap(mouse.x, mouse.y)
            var code = root.countryAt(pt.x, pt.y)
            // TEMP DEBUG: remove once zoom/hover alignment is confirmed fixed.
            console.log("[map] HOVER mouse=" + mouse.x.toFixed(1) + "," + mouse.y.toFixed(1) + " zoom=" + root.zoom.toFixed(2) + " pan=" + root.panX.toFixed(1) + "," + root.panY.toFixed(1) + " -> path=" + pt.x.toFixed(1) + "," + pt.y.toFixed(1) + " code=" + (code || "none"))
            if (code !== root.hoveredCode)
                root.hoveredCode = code
        }

        onExited: {
            mapMouse.panning = false
            mapMouse.positionValid = false
            root.hoveredCode = ""
        }

        onClicked: function(mouse) {
            if (mouse.button !== Qt.LeftButton)
                return
            var pt = root.screenToMap(mouse.x, mouse.y)
            var code = root.countryAt(pt.x, pt.y)
            if (code.length === 2 && root.isAvailable(code) && !root.service.busy)
                root.countryClicked(code)
        }
    }
}
