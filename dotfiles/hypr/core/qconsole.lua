-- Ported from Omarchy quattro default/hypr/qconsole.lua:1
-- Special workspaces: https://wiki.hypr.land/Configuring/Basics/Dispatchers
-- Bindings live in core/bindings.lua (SUPER + grave / SUPER + SHIFT + grave).

-- Percent of the usable screen height the console covers from the top (1-100).
local height = 50

-- It seeds the workspace with the terminal.
local seed = "[workspace special:scratchpad silent] ghostty --class=com.mitchellh.ghostty.scratchpad --window-padding-y=40,2 -e tmux new -A -s scratchpad -c /home/joao"

-- Dimming only applies while a special workspace is open, so the console gets
-- its separation from the workspace underneath without costing anything the
-- rest of the time.
hl.config({
    decoration = {
        dim_special = 0.6,
    },
})

-- Refitting replaces the rule in place rather than stacking a new one, but it
-- still schedules a monitor and window state refresh, and monitor.focused fires
-- on every hop between screens. Most of those hops do not change the number, so
-- only write the rule when it actually moves.
local covering = nil

local function cover(bottom)
    if covering == bottom then
        return
    end
    covering = bottom

    hl.workspace_rule({
        workspace = "special:scratchpad",
        gaps_in = 0,
        gaps_out = { top = 0, right = 0, bottom = bottom, left = 0 },
        -- Nothing to highlight in a console that is only ever focused when it is
        -- open, and the active border reads as a stray frame around a panel that
        -- is already set apart by the dimming behind it.
        no_border = true,
        on_created_empty = seed,
    })
end

-- Sizing the console with a window rule would freeze it at whatever the screen
-- measured when it first opened, because Hyprland resolves those expressions
-- once, as the window maps. Rescaling the monitor afterwards would leave a
-- console that is no longer half of anything. Gaps are re-applied by the layout
-- instead, so the console is sized by the gap left underneath it and that gap
-- is recomputed whenever the monitor layout changes.
local function fit()
    local monitor = hl.get_active_monitor()

    -- A monitor handle whose output has gone away answers nil to every field, and
    -- layout changes are exactly when that happens, so this also covers reading
    -- height and reserved below.
    if not monitor or not monitor.scale or monitor.scale <= 0 then
        return
    end

    -- Monitor dimensions are in physical pixels; gaps are logical, so the scale
    -- has to come out before the reserved area (already logical) comes off.
    local reserved = monitor.reserved
    local usable = monitor.height / monitor.scale - reserved.top - reserved.bottom
    local frac = math.min(100, math.max(1, height)) / 100

    cover(math.max(0, math.floor(usable * (1 - frac))))
end

-- Until a monitor can be read, cover the whole work area rather than leaving
-- the console unruled, so it is never seeded without its placement.
cover(0)
fit()

hl.on("monitor.layout_changed", fit)
hl.on("monitor.focused", fit)

-- The direction names the edge the offset is measured from, not where the
-- workspace goes: "slide top" drops it down into view, and "slide bottom"
-- retracts it back up the way a Quake console does.
-- Omarchy uses In/Out leaves; some Hyprland versions use the base leaf, so set both.
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide top" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide top" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2, bezier = "easeInOutCubic", style = "slide bottom" })

-- Scratchpad window: float behind the bar (y=0) so transparent bar shows its
-- background, while --window-padding-y=40 keeps text below the bar.
-- Normal ghostty stays tiled with 0.97 opacity via core/rules.lua:159; scratchpad
-- is opaque to match the bar's seam when behind it.
hl.window_rule({ match = { class = "com\\.mitchellh\\.ghostty\\.scratchpad" }, float = true, move = { "0", "0" }, size = { "monitor_w", "(monitor_h * " .. (math.min(100, math.max(1, height)) / 100) .. ") + 40" }, opacity = "1 1", animation = "slide top" })

-- Children spawned from the console land on special:scratchpad and open hidden
-- behind it. Bounce every window to the regular workspace the console is over:
-- active_workspace stays underlying while special shows. Only the initial
-- console stays.
local SCRATCH_CLASS = "com.mitchellh.ghostty.scratchpad"
hl.on("window.open", function(w)
    if not w or not w.workspace or w.workspace.name ~= "special:scratchpad" then
        return
    end
    if w.class == SCRATCH_CLASS then
        local alone = true
        for _, o in ipairs(hl.get_workspace_windows("special:scratchpad") or {}) do
            if o.address ~= w.address then
                alone = false
                break
            end
        end
        if alone then
            return
        end
    end
    local mon = w.monitor or hl.get_active_monitor()
    local under = mon and mon.active_workspace
    if not under or under.name == "special:scratchpad" then
        under = hl.get_active_workspace()
    end
    if not under or under.name == "special:scratchpad" then
        return
    end
    hl.dispatch(hl.dsp.window.move({ workspace = under.name, follow = false, window = "address:" .. w.address }))
end)
