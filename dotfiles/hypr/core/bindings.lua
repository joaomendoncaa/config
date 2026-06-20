local utils = require("core.utils")
local terminal = "uwsm app -- xdg-terminal-exec"
local bind = utils.bind

hl.unbind("SUPER + W")
hl.unbind("SHIFT + F11")
hl.unbind("SUPER + SHIFT + V")
hl.unbind("SUPER + SHIFT + A")
hl.unbind("SUPER + SHIFT + T")
hl.unbind("SUPER + D")

bind("PRINT", "Screenshot", "capture-screenshot")
bind("SUPER + PRINT", "Color picker", "pkill hyprpicker || hyprpicker -a")
bind("SUPER + CTRL + PRINT", "Extract text (OCR) from screenshot", "capture-screenshot-text")

bind("SUPER + CTRL + Z", "Zoom in", function()
	local zoom = hl.get_config("cursor.zoom_factor") or 1
	hl.config({ cursor = { zoom_factor = zoom + 1 } })
end)

bind("SUPER + CTRL + ALT + Z", "Reset zoom", function()
	hl.config({ cursor = { zoom_factor = 1 } })
end)

hl.bind("SUPER + D", hl.dsp.exec_cmd("/home/joao/.local/bin/voxtype record toggle"), { description = "Voxtype toggle" })
bind("SUPER + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind("SUPER + SHIFT + V", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle Float" })
bind("SUPER + ESCAPE", "Power menu", utils.quickshell_ipc("power-menu", "toggle"))
hl.bind(
	"SUPER + ALT + RETURN",
	hl.dsp.exec_cmd('uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" tmux attach'),
	{ description = "Tmux" }
)
hl.bind(
	"ALT + PRINT",
	hl.dsp.exec_cmd("$HOME/.config.jmmm.sh/bin/toggle-record-screen"),
	{ description = "Record Screen" }
)
hl.bind(
	"SUPER + SHIFT + R",
	hl.dsp.exec_cmd("$HOME/.config.jmmm.sh/bin/toggle-obs-record"),
	{ description = "Toggle OBS Record" }
)
hl.bind(
	"SUPER + V",
	hl.dsp.exec_cmd(utils.quickshell_ipc("launcher", "openClipboard")),
	{ description = "Clipboard Manager" }
)
hl.bind("SUPER + S", hl.dsp.layout("togglesplit"), { description = "Toggle Split" })
hl.bind(
	"SUPER + RETURN",
	hl.dsp.exec_cmd(terminal .. " --dir=$(omarchy-cmd-terminal-cwd)"),
	{ description = "Terminal" }
)
hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Close window" })
hl.bind("SUPER + E", hl.dsp.exec_cmd("uwsm app -- nautilus --new-window"), { description = "File manager" })
hl.bind("SUPER + B", hl.dsp.exec_cmd("omarchy-launch-browser"), { description = "Browser" })
hl.bind(
	"SUPER + M",
	hl.dsp.exec_cmd('omarchy-launch-webapp "https://music.youtube.com"'),
	{ description = "Youtube Music" }
)
hl.bind(
	"SUPER + SHIFT + B",
	hl.dsp.exec_cmd("omarchy-launch-webapp 'http://localhost:3000'"),
	{ description = "Development Browser" }
)
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("steam steam://rungameid/230410"), { description = "Launch Warframe" })
hl.bind(
	"SUPER + SHIFT + A",
	hl.dsp.exec_cmd('omarchy-launch-webapp "https://chatgpt.com"'),
	{ description = "Launch ChatGPT" }
)
hl.bind(
	"SUPER + SHIFT + T",
	hl.dsp.exec_cmd('omarchy-launch-webapp "https://translate.google.pt/?sl=auto&tl=en&op=translate"'),
	{ description = "Launch Translator" }
)
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd(utils.quickshell_ipc("launcher", "toggle")), { description = "Open Launcher" })
hl.bind(
	"SUPER + SHIFT + SPACE",
	hl.dsp.exec_cmd([[bash -c 'if pgrep -x quickshell >/dev/null; then pkill -x quickshell; else quickshell & fi']]),
	{ description = "Toggle Quickshell" }
)

hl.bind("SUPER + H", hl.dsp.focus({ direction = "l" }), { description = "Focus Left" })
hl.bind("SUPER + L", hl.dsp.focus({ direction = "r" }), { description = "Focus Right" })
hl.bind("SUPER + K", hl.dsp.focus({ direction = "u" }), { description = "Focus Up" })
hl.bind("SUPER + J", hl.dsp.focus({ direction = "d" }), { description = "Focus Down" })

hl.bind("SUPER + SHIFT + H", hl.dsp.window.swap({ direction = "l" }), { description = "Swap Left" })
hl.bind("SUPER + SHIFT + L", hl.dsp.window.swap({ direction = "r" }), { description = "Swap Right" })
hl.bind("SUPER + SHIFT + K", hl.dsp.window.swap({ direction = "u" }), { description = "Swap Up" })
hl.bind("SUPER + SHIFT + J", hl.dsp.window.swap({ direction = "d" }), { description = "Swap Down" })

hl.bind("SUPER + CTRL + H", hl.dsp.window.resize({ x = -80, y = 0 }), { description = "Resize Left" })
hl.bind("SUPER + CTRL + L", hl.dsp.window.resize({ x = 80, y = 0 }), { description = "Resize Right" })
hl.bind("SUPER + CTRL + K", hl.dsp.window.resize({ x = 0, y = -80 }), { description = "Resize Up" })
hl.bind("SUPER + CTRL + J", hl.dsp.window.resize({ x = 0, y = 80 }), { description = "Resize Down" })

hl.bind("SUPER + TAB", hl.dsp.focus({ workspace = "previous" }), { description = "Switch to last visited workspace" })
hl.bind("SUPER + CTRL + TAB", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })

hl.define_submap("toggles", "reset", function()
	hl.bind("T", function()
		hl.dispatch(
			hl.dsp.exec_cmd(
				[[bash -c 'if [ "$(omarchy-theme-current)" = "Snow" ]; then omarchy-theme-set mars; else omarchy-theme-set snow; fi; ~/.config.jmmm.sh/bin/nvim-theme-sync']]
			)
		)
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Toggle theme" })
	hl.bind("S", function()
		hl.dispatch(hl.dsp.exec_cmd("$HOME/.config.jmmm.sh/bin/toggle-sink"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Toggle sink" })
	hl.bind("A", function()
		hl.dispatch(hl.dsp.exec_cmd("pamixer -t"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Toggle audio mute" })
end)
hl.bind("SUPER + T", hl.dsp.submap("toggles"), { description = "Enter toggles submap" })

-- Twitter submap (SUPER + X): launch, x.com, pro.x.com.
hl.define_submap("twitter", "reset", function()
	hl.bind("X", function()
		hl.dispatch(hl.dsp.exec_cmd("$HOME/.config.jmmm.sh/bin/launch-twitter"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Launch Twitter" })
	hl.bind("T", function()
		hl.dispatch(hl.dsp.exec_cmd('omarchy-launch-webapp "https://x.com"'))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Open X/Twitter" })
	hl.bind("P", function()
		hl.dispatch(hl.dsp.exec_cmd('omarchy-launch-webapp "https://pro.x.com"'))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Open X Pro" })
end)
hl.bind("SUPER + X", hl.dsp.submap("twitter"), { description = "Enter twitter submap" })

-- Comms submap (SUPER + C): chat, messages, discord, mail, whatsapp, telegram.
hl.define_submap("comms", "reset", function()
	hl.bind("C", function()
		hl.dispatch(hl.dsp.exec_cmd("$HOME/.config.jmmm.sh/bin/launch-comms"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Launch comms" })
	hl.bind("G", function()
		hl.dispatch(hl.dsp.exec_cmd('omarchy-launch-webapp "https://messages.google.com/web/conversations"'))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Google Messages" })
	hl.bind("D", function()
		hl.dispatch(hl.dsp.exec_cmd('omarchy-launch-webapp "https://discord.com/channels/"'))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Discord" })
	hl.bind("P", function()
		hl.dispatch(hl.dsp.exec_cmd('omarchy-launch-webapp "https://mail.proton.me/u/0/inbox"'))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Proton Mail" })
	hl.bind("W", function()
		hl.dispatch(hl.dsp.exec_cmd('omarchy-launch-webapp "https://web.whatsapp.com/"'))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "WhatsApp" })
	hl.bind("T", function()
		hl.dispatch(hl.dsp.exec_cmd("Telegram"))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Telegram" })
end)
hl.bind("SUPER + C", hl.dsp.submap("comms"), { description = "Enter comms submap" })

hl.define_submap("ai", "reset", function()
	hl.bind("A", function()
		hl.dispatch(
			hl.dsp.exec_cmd(
				'omarchy-launch-webapp "https://chatgpt.com" & omarchy-launch-webapp "https://grok.com" & omarchy-launch-webapp "https://www.perplexity.ai"'
			)
		)
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Launch all AI apps" })
	hl.bind("C", function()
		hl.dispatch(hl.dsp.exec_cmd('omarchy-launch-webapp "https://chatgpt.com"'))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "ChatGPT" })
	hl.bind("G", function()
		hl.dispatch(hl.dsp.exec_cmd('omarchy-launch-webapp "https://grok.com"'))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Grok" })
	hl.bind("P", function()
		hl.dispatch(hl.dsp.exec_cmd('omarchy-launch-webapp "https://www.perplexity.ai"'))
		hl.dispatch(hl.dsp.submap("reset"))
	end, { description = "Perplexity" })
end)
hl.bind("SUPER + A", hl.dsp.submap("ai"), { description = "Enter AI submap" })

bind("XF86AudioRaiseVolume", "Volume up", "omarchy-audio-output-volume raise", { locked = true, repeating = true })
bind("XF86AudioLowerVolume", "Volume down", "omarchy-audio-output-volume lower", { locked = true, repeating = true })
bind("XF86AudioMute", "Mute", "omarchy-audio-output-volume mute-toggle", { locked = true })
bind("XF86AudioMicMute", "Mute microphone", "omarchy-audio-input-mute", { locked = true })
bind("XF86MonBrightnessUp", "Brightness up", "omarchy-brightness-display +5%", { locked = true, repeating = true })
bind("XF86MonBrightnessDown", "Brightness down", "omarchy-brightness-display 5%-", { locked = true, repeating = true })
bind(
	"SHIFT + XF86MonBrightnessUp",
	"Brightness maximum",
	"omarchy-brightness-display 100%",
	{ locked = true, repeating = true }
)
bind(
	"SHIFT + XF86MonBrightnessDown",
	"Brightness minimum",
	"omarchy-brightness-display 1%",
	{ locked = true, repeating = true }
)
bind(
	"XF86KbdBrightnessUp",
	"Keyboard brightness up",
	"omarchy-brightness-keyboard up",
	{ locked = true, repeating = true }
)
bind(
	"XF86KbdBrightnessDown",
	"Keyboard brightness down",
	"omarchy-brightness-keyboard down",
	{ locked = true, repeating = true }
)
bind("XF86KbdLightOnOff", "Keyboard backlight cycle", "omarchy-brightness-keyboard cycle", { locked = true })
utils.omarchy_bind_toggle("XF86TouchpadToggle", "Toggle touchpad", "touchpad", { locked = true })
bind("XF86TouchpadOn", "Enable touchpad", "omarchy-toggle-touchpad on", { locked = true })
bind("XF86TouchpadOff", "Disable touchpad", "omarchy-toggle-touchpad off", { locked = true })

bind(
	"ALT + XF86AudioRaiseVolume",
	"Volume up precise",
	"omarchy-audio-output-volume +1",
	{ locked = true, repeating = true }
)
bind(
	"ALT + XF86AudioLowerVolume",
	"Volume down precise",
	"omarchy-audio-output-volume -1",
	{ locked = true, repeating = true }
)
bind(
	"ALT + XF86MonBrightnessUp",
	"Brightness up precise",
	"omarchy-brightness-display +1%",
	{ locked = true, repeating = true }
)
bind(
	"ALT + XF86MonBrightnessDown",
	"Brightness down precise",
	"omarchy-brightness-display 1%-",
	{ locked = true, repeating = true }
)

bind("XF86AudioNext", "Next track", "omarchy-shell media next", { locked = true })
bind("XF86AudioPause", "Pause", "omarchy-shell media playPause", { locked = true })
bind("XF86AudioPlay", "Play", "omarchy-shell media playPause", { locked = true })
bind("XF86AudioPrev", "Previous track", "omarchy-shell media previous", { locked = true })

bind("SHIFT + XF86AudioMute", "Switch audio output", "omarchy-audio-output-switch", { locked = true })
bind("SHIFT + XF86AudioPause", "Switch media source", "omarchy-audio-source-switch", { locked = true })
bind("SHIFT + XF86AudioPlay", "Switch media source", "omarchy-audio-source-switch", { locked = true })

bind("SUPER + W", "Close window", hl.dsp.window.close())
bind("CTRL + ALT + DELETE", "Close all windows", "qs-power-window-close-all")

bind("SUPER + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
bind("SUPER + CTRL + F", "Tiled full screen", "omarchy-hyprland-window-tiled-fullscreen-toggle")
bind("SUPER + ALT + F", "Full width", hl.dsp.window.fullscreen({ mode = "maximized" }))
bind("SUPER + O", "Pop window out (float & pin)", "omarchy-hyprland-window-pop")
bind("SUPER + ALT + Home", "Save window width", "omarchy-hyprland-window-width save")
bind("SUPER + Home", "Restore window width", "omarchy-hyprland-window-width restore")
bind("SUPER + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

bind("SUPER + LEFT", "Focus on left window", hl.dsp.focus({ direction = "l" }))
bind("SUPER + RIGHT", "Focus on right window", hl.dsp.focus({ direction = "r" }))
bind("SUPER + UP", "Focus on above window", hl.dsp.focus({ direction = "u" }))
bind("SUPER + DOWN", "Focus on below window", hl.dsp.focus({ direction = "d" }))

for workspace = 1, 10 do
	local key = "code:" .. tostring(workspace + 9)
	bind("SUPER + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
	bind(
		"SUPER + SHIFT + " .. key,
		"Move window to workspace " .. workspace,
		hl.dsp.window.move({ workspace = tostring(workspace) })
	)
	bind(
		"SUPER + SHIFT + ALT + " .. key,
		"Move window silently to workspace " .. workspace,
		hl.dsp.window.move({ workspace = tostring(workspace), follow = false })
	)
end

bind("SUPER + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
bind(
	"SUPER + ALT + S",
	"Move window to scratchpad",
	hl.dsp.window.move({ workspace = "special:scratchpad", follow = false })
)

bind("SUPER + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))

bind("SUPER + SHIFT + ALT + LEFT", "Move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
bind("SUPER + SHIFT + ALT + RIGHT", "Move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))
bind("SUPER + SHIFT + ALT + UP", "Move workspace to up monitor", hl.dsp.workspace.move({ monitor = "u" }))
bind("SUPER + SHIFT + ALT + DOWN", "Move workspace to down monitor", hl.dsp.workspace.move({ monitor = "d" }))

bind("SUPER + SHIFT + LEFT", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
bind("SUPER + SHIFT + RIGHT", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))
bind("SUPER + SHIFT + UP", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
bind("SUPER + SHIFT + DOWN", "Swap window down", hl.dsp.window.swap({ direction = "d" }))

bind("ALT + TAB", "Focus on next window", hl.dsp.window.cycle_next())
bind("ALT + SHIFT + TAB", "Focus on previous window", hl.dsp.window.cycle_next({ next = false }))
bind("ALT + TAB", "Reveal active window on top", hl.dsp.window.bring_to_top())
bind("ALT + SHIFT + TAB", "Reveal active window on top", hl.dsp.window.bring_to_top())

bind("CTRL + ALT + TAB", "Focus on next monitor", hl.dsp.focus({ monitor = "+1" }))
bind("CTRL + ALT + SHIFT + TAB", "Focus on previous monitor", hl.dsp.focus({ monitor = "-1" }))

bind("SUPER + code:20", "Expand window left", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
bind("SUPER + code:21", "Shrink window left", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
bind("SUPER + SHIFT + code:20", "Shrink window up", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
bind("SUPER + SHIFT + code:21", "Expand window down", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

bind("SUPER + ALT + code:20", "Expand window left a little", hl.dsp.window.resize({ x = -25, y = 0, relative = true }))
bind("SUPER + ALT + code:21", "Shrink window left a little", hl.dsp.window.resize({ x = 25, y = 0, relative = true }))
bind(
	"SUPER + SHIFT + ALT + code:20",
	"Shrink window up a little",
	hl.dsp.window.resize({ x = 0, y = -25, relative = true })
)
bind(
	"SUPER + SHIFT + ALT + code:21",
	"Expand window down a little",
	hl.dsp.window.resize({ x = 0, y = 25, relative = true })
)

bind("SUPER + CTRL + code:20", "Expand window left a lot", hl.dsp.window.resize({ x = -300, y = 0, relative = true }))
bind("SUPER + CTRL + code:21", "Shrink window left a lot", hl.dsp.window.resize({ x = 300, y = 0, relative = true }))
bind(
	"SUPER + CTRL + SHIFT + code:20",
	"Shrink window up a lot",
	hl.dsp.window.resize({ x = 0, y = -300, relative = true })
)
bind(
	"SUPER + CTRL + SHIFT + code:21",
	"Expand window down a lot",
	hl.dsp.window.resize({ x = 0, y = 300, relative = true })
)

bind("SUPER + mouse_down", "Scroll active workspace forward", hl.dsp.focus({ workspace = "e+1" }))
bind("SUPER + mouse_up", "Scroll active workspace backward", hl.dsp.focus({ workspace = "e-1" }))

bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })

bind("SUPER + G", "Toggle window grouping", hl.dsp.group.toggle())
bind("SUPER + ALT + G", "Move active window out of group", hl.dsp.window.move({ out_of_group = true }))

bind("SUPER + ALT + LEFT", "Move window to group on left", hl.dsp.window.move({ into_group = "l" }))
bind("SUPER + ALT + RIGHT", "Move window to group on right", hl.dsp.window.move({ into_group = "r" }))
bind("SUPER + ALT + UP", "Move window to group on top", hl.dsp.window.move({ into_group = "u" }))
bind("SUPER + ALT + DOWN", "Move window to group on bottom", hl.dsp.window.move({ into_group = "d" }))

bind("SUPER + ALT + TAB", "Next window in group", hl.dsp.group.next())
bind("SUPER + ALT + SHIFT + TAB", "Previous window in group", hl.dsp.group.prev())

bind("SUPER + CTRL + LEFT", "Move grouped window focus left", hl.dsp.group.prev())
bind("SUPER + CTRL + RIGHT", "Move grouped window focus right", hl.dsp.group.next())

bind("SUPER + ALT + mouse_down", "Next window in group", hl.dsp.group.next())
bind("SUPER + ALT + mouse_up", "Previous window in group", hl.dsp.group.prev())

for index = 1, 5 do
	bind(
		"SUPER + ALT + code:" .. tostring(index + 9),
		"Switch to group window " .. index,
		hl.dsp.group.active({ index = index })
	)
end

bind("SUPER + code:61", "Monitor scaling up", "omarchy-hyprland-monitor-scaling up")
bind("SUPER + ALT + code:61", "Monitor scaling down", "omarchy-hyprland-monitor-scaling down")
