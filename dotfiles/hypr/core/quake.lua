local M = {}

local QUAKE = "special:quake"
local QUAKE_CLASS = "com.mitchellh.ghostty.quake"

-- Quake always starts at the monitor origin (y=0), behind the top bar,
-- and clears it with ghostty's top window padding instead, so the bar floats
-- over Quake. The padding is baked at spawn from that monitor's reserved
-- top: no reserved space means no extra padding.
local function reserve_top(monitor)
	local r = monitor and monitor.reserved
	return (r and r.top) or 0
end

local function geometry(monitor)
	if not monitor or not monitor.scale or monitor.scale <= 0 then
		return nil
	end
	local w, h = monitor.width, monitor.height
	if (monitor.transform or 0) % 2 == 1 then
		w, h = h, w
	end
	w = w / monitor.scale
	h = h / monitor.scale
	local r = monitor.reserved or {}
	local top, bottom, left, right = reserve_top(monitor), r.bottom or 0, r.left or 0, r.right or 0
	return {
		x = math.floor(monitor.x + left),
		y = math.floor(monitor.y),
		w = math.floor(w - left - right),
		h = math.floor((h - top - bottom) * 0.5 + top),
	}
end

hl.config({
	decoration = {
		dim_special = 0.6,
	},
})

hl.workspace_rule({
	workspace = QUAKE,
	gaps_in = 0,
	gaps_out = 0,
	no_border = true,
})

hl.window_rule({
	name = "quake",
	match = { class = "com\\.mitchellh\\.ghostty\\.quake" },
	float = true,
	move = { "0", "0" },
	size = { "monitor_w", "monitor_h * 0.5" },
	opacity = "1 1",
	no_anim = true,
})

local function place(win, monitor)
	local g = monitor and monitor.name and geometry(monitor)
	if not g then
		return
	end
	hl.dispatch(hl.dsp.window.move({ x = g.x, y = g.y, window = win }))
	hl.dispatch(hl.dsp.window.resize({ x = g.w, y = g.h, window = win }))
end

local function spawned()
	for _, w in ipairs(hl.get_workspace_windows(QUAKE) or {}) do
		if w.class == QUAKE_CLASS then
			return w
		end
	end
	return nil
end

local function show(win, monitor)
	-- Toggle first, then place: window rules only apply at open, so placing
	-- before the toggle sizes for the output it is leaving, not the one it
	-- lands on. The special_active/move_to_monitor hooks re-place after the
	-- move; the immediate place + timer here cover the frames before they fire.
	hl.dispatch(hl.dsp.workspace.toggle_special("quake"))
	place(win, monitor)
	hl.dispatch(hl.dsp.focus({ window = "address:" .. win.address }))
	hl.timer(function()
		local cur = hl.get_workspace(QUAKE)
		if cur and cur.visible then
			place(win, monitor)
			hl.dispatch(hl.dsp.focus({ window = "address:" .. win.address }))
		end
	end, { timeout = 50, type = "oneshot" })
end

local inflight = false

local function focused_monitor()
	local win = hl.get_active_window()
	local ws = win and win.workspace
	if type(ws) == "string" then
		ws = hl.get_workspace(ws)
	end
	if type(ws) == "table" and ws.monitor and ws.monitor.name then
		return ws.monitor
	end
	return hl.get_active_monitor()
end

local PAD = 2

-- Padding is baked into the ghostty process at spawn, so Quake moved to a
-- monitor with different reserved space carries stale padding. Track what it
-- was spawned with; toggle respawns (tmux session survives) on mismatch.
local spawned_top = nil

local function needed_top(monitor)
	return math.floor(PAD + reserve_top(monitor))
end

local function seed(monitor)
	spawned_top = needed_top(monitor)
	return "ghostty --class="
		.. QUAKE_CLASS
		.. " --window-padding-y="
		.. spawned_top
		.. ","
		.. PAD
		.. " -e tmux new -A -s quake -c /home/joao"
end

function M.toggle()
	local monitor = focused_monitor()
	local ws = hl.get_workspace(QUAKE)
	local s = spawned()
	if s and ws and ws.visible then
		if not monitor or (ws.monitor and ws.monitor.name == monitor.name) then
			inflight = false
			hl.dispatch(hl.dsp.workspace.toggle_special("quake"))
			return
		end
	end
	-- Respawn when the baked padding doesn't fit this monitor (nil counts as
	-- stale: reloads reset it). tmux session survives, so nothing is lost.
	if s and (spawned_top == nil or spawned_top ~= needed_top(monitor)) then
		hl.dispatch(hl.dsp.window.close({ window = "address:" .. s.address }))
		s = nil
		inflight = false
	end
	if inflight and s then
		inflight = false
	end
	if s then
		show(s, monitor)
		return
	end
	if inflight then
		return
	end
	inflight = true
	hl.timer(function()
		inflight = false
	end, { timeout = 5000, type = "oneshot" })
	hl.dispatch(hl.dsp.exec_cmd(seed(monitor)))
	hl.timer(function()
		local early = spawned()
		if early then
			place(early, monitor)
		end
		if inflight then
			local late = hl.get_workspace(QUAKE)
			if late and not late.visible then
				hl.dispatch(hl.dsp.workspace.toggle_special("quake"))
			end
			local slow = spawned()
			if slow then
				place(slow, monitor)
				hl.dispatch(hl.dsp.focus({ window = "address:" .. slow.address }))
			end
		end
	end, { timeout = 800, type = "oneshot" })
end

local function on_window_open(w)
	if w and w.class == QUAKE_CLASS then
		if not w.workspace or w.workspace.name ~= QUAKE then
			hl.dispatch(
				hl.dsp.window.move({ workspace = QUAKE, follow = false, window = "address:" .. w.address })
			)
		end
	end
end

local function on_window_move_to_workspace(w, ws)
	if inflight and w and w.class == QUAKE_CLASS and ws and ws.name == QUAKE then
		inflight = false
		local m = focused_monitor()
		place(w, m)
		-- The workspace move still pending overwrites pixel position, so
		-- re-place once it settles. Lookup is deferred: the event object
		-- may not stick, the settled window does.
		hl.timer(function()
			local s = spawned()
			if s then
				place(s, focused_monitor())
			end
		end, { timeout = 100, type = "oneshot" })
		local cur = hl.get_workspace(QUAKE)
		if cur and not cur.visible then
			hl.dispatch(hl.dsp.workspace.toggle_special("quake"))
		end
		hl.dispatch(hl.dsp.focus({ window = "address:" .. w.address }))
	end
end

hl.on("window.open", on_window_open)
hl.on("window.move_to_workspace", on_window_move_to_workspace)

-- The toggle moves the special workspace; the move lands a frame later, so
-- re-place on arrival. This is what sizes Quake for the monitor it
-- opened on rather than the one it came from.
local function on_special_arrived(ws, mon)
	if ws and ws.name == QUAKE and mon and mon.name then
		local s = spawned()
		if s then
			place(s, mon)
		end
	end
end

hl.on("workspace.special_active", on_special_arrived)
hl.on("workspace.move_to_monitor", on_special_arrived)

return M
