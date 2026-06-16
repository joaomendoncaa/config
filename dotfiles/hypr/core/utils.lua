M = {}

local terminal_classes = {
	alacritty = true,
	["com.mitchellh.ghostty"] = true,
	foot = true,
	kitty = true,
	wezterm = true,
}

local function escape_single_quotes(value)
	return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function command_from(value, description)
	if type(value) ~= "table" then
		return value
	end

	if value.omarchy then
		return "omarchy-launch-" .. value.omarchy
	elseif value.focus and value.launch then
		return M.omarchy_launch_or_focus(value.focus, value.launch)
	elseif value.launch then
		return M.launch(value.launch)
	elseif value.webapp then
		if value.focus then
			return M.omarchy_webapp_launch_or_focus(description, value.webapp)
		else
			return M.omarchy_webapp_launch(value.webapp)
		end
	elseif value.tui then
		if value.focus then
			return "omarchy-launch-or-focus-tui " .. escape_single_quotes(value.tui)
		else
			return "omarchy-launch-tui " .. escape_single_quotes(value.tui)
		end
	end

	return value
end

function M.bind(keys, description, dispatcher, options)
	local opts = options or {}

	if description then
		opts.description = description
	end

	dispatcher = command_from(dispatcher, description)

	if type(dispatcher) == "string" then
		dispatcher = hl.dsp.exec_cmd(dispatcher)
	end

	hl.bind(keys, dispatcher, opts)
end

function M.launch(command)
	return "uwsm-app -- " .. command
end

function M.exec_on_start(command)
	hl.on("hyprland.start", function()
		hl.exec_cmd(command)
	end)
end

function M.launch_on_start(command)
	M.exec_on_start(M.launch(command))
end

function M.omarchy_webapp_launch(url)
	return "omarchy-launch-webapp " .. escape_single_quotes(url)
end

function M.omarchy_webapp_launch_or_focus(name, url)
	return "omarchy-launch-or-focus-webapp " .. escape_single_quotes(name) .. " " .. escape_single_quotes(url)
end

function M.omarchy_launch_or_focus(match, command)
	return "omarchy-launch-or-focus " .. escape_single_quotes(match) .. " " .. escape_single_quotes(M.launch(command))
end

function M.omarchy_bind_toggle(keys, description, toggle, options)
	M.bind(keys, description, "omarchy-toggle-" .. toggle, options)
end

function M.notify(message)
	return "notify-send -u low " .. escape_single_quotes(message)
end

function M.window(match, rules)
	rules.match = rules.match or {}

	if type(match) == "string" then
		rules.match.class = match
	else
		for key, value in pairs(match) do
			rules.match[key] = value
		end
	end

	hl.window_rule(rules)
end

function M.send_shortcut_once(mods, key)
	return function()
		hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down", window = "activewindow" }))

		hl.timer(function()
			hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up", window = "activewindow" }))
		end, { timeout = 50, type = "oneshot" })
	end
end

function M.active_window_is_terminal()
	local window = hl.get_active_window()
	if not window or not window.class then
		return false
	end

	return terminal_classes[window.class:lower()] == true
end

function M.universal_clipboard_shortcut(default_mods, default_key, terminal_mods, terminal_key)
	return function()
		if active_window_is_terminal() then
			M.send_shortcut_once(terminal_mods, terminal_key)()
		else
			M.send_shortcut_once(default_mods, default_key)()
		end
	end
end

return M
