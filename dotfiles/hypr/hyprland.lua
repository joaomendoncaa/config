hl.env("GDK_SCALE", "1")
hl.env("NVD_BACKEND", "direct")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-- Load user modules from ~/.config and Omarchy-4 defaults.
package.path = os.getenv("HOME")
	.. "/.config/?.lua;"
	.. "/home/joao/.local/share/opencode/repos/github.com/basecamp/omarchy"
	.. "/?.lua;"
	.. (os.getenv("OMARCHY_PATH") or (os.getenv("HOME") .. "/.local/share/omarchy"))
	.. "/?.lua;"
	.. package.path

-- Point omarchy paths to the Lua version for app/window rule resolution.
require("default.hypr.paths")
local paths = require("default.hypr.paths")
paths.omarchy_path = "/home/joao/.local/share/opencode/repos/github.com/basecamp/omarchy"

require("default.hypr.helpers")
require("default.hypr.bindings.media")
require("default.hypr.bindings.clipboard")
require("default.hypr.bindings.tiling-v2")
require("default.hypr.bindings.utilities")
require("default.hypr.envs")
require("default.hypr.looknfeel")
require("default.hypr.input")
require("default.hypr.windows")
require("default.hypr.require_optional").module("omarchy.current.theme.hyprland")

hl.on("hyprland.start", function()
	hl.exec_cmd("uwsm-app -- mako")
	hl.exec_cmd("uwsm-app -- fcitx5 --disable notificationitem")
	hl.exec_cmd("uwsm-app -- swaybg -i ~/.config/omarchy/current/background -m fill")
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
	hl.exec_cmd("omarchy-cmd-first-run")
	hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	hl.exec_cmd("uwsm app -- walker --gapplication-service")
	hl.exec_cmd("numlockx on")
	hl.exec_cmd("quickshell")
end)

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.config({
	general = {
		gaps_in = 7,
		gaps_out = 10,
	},
	decoration = {
		rounding = 4,
		blur = {
			enabled = true,
			size = 5,
			passes = 2,
		},
	},
	input = {
		kb_layout = "pt",
		kb_options = "caps:escape",
		repeat_rate = 40,
		repeat_delay = 250,
		sensitivity = 0.22,
		accel_profile = "flat",
		touchpad = {
			scroll_factor = 0.4,
		},
	},
})

hl.layer_rule({ match = { namespace = "superbar" }, blur = true, no_anim = true })

hl.window_rule({ match = { class = "(Alacritty|kitty|foot)" }, scroll_touchpad = 1.5 })
hl.window_rule({ match = { class = "com.mitchellh.ghostty" }, scroll_touchpad = 0.2 })

hl.window_rule({ match = { initial_class = "zen" }, tag = "-firefox-based-browser" })
hl.window_rule({ match = { initial_class = "zen" }, float = true })
hl.window_rule({ match = { initial_class = "zen" }, size = { 500, 800 } })
hl.window_rule({ match = { initial_class = "zen" }, center = true })

hl.window_rule({ match = { class = "chrome-chatgpt.com__-Default" }, float = true })
hl.window_rule({ match = { class = "chrome-chatgpt.com__-Default" }, size = { 600, 800 } })
hl.window_rule({ match = { class = "chrome-chatgpt.com__-Default" }, move = { 1947, 47 } })

hl.window_rule({ match = { class = "chrome-translate.google.pt__-Default" }, float = true })
hl.window_rule({ match = { class = "chrome-translate.google.pt__-Default" }, size = { 600, 800 } })
hl.window_rule({ match = { class = "chrome-translate.google.pt__-Default" }, move = { 1343, 47 } })

hl.window_rule({ match = { initial_class = "steam_app_230410" }, render_unfocused = true })

hl.window_rule({ match = { initial_class = "Aether" }, float = true })
hl.window_rule({ match = { initial_class = "Aether" }, size = { 1259, 1000 } })
hl.window_rule({ match = { initial_class = "Aether" }, center = true })

-- Application bindings.
local terminal = "uwsm app -- xdg-terminal-exec"

-- Unbind default bindings that conflict with my setup.
hl.unbind("SUPER + W")
hl.unbind("SUPER + K")
hl.unbind("SUPER + J")
hl.unbind("SUPER + P")
hl.unbind("ALT + PRINT")
hl.unbind("SHIFT + F11")
hl.unbind("SUPER + SHIFT + V")
hl.unbind("SUPER + CTRL + V")
hl.unbind("SUPER + CTRL + L")
hl.unbind("SUPER + SHIFT + A")
hl.unbind("SUPER + SHIFT + T")
hl.unbind("SUPER + TAB")
hl.unbind("SUPER + CTRL + TAB")
hl.unbind("SUPER + SPACE")
hl.unbind("SUPER + SHIFT + SPACE")
hl.unbind("SUPER + D")

hl.bind("SUPER + D", hl.dsp.exec_cmd("/home/joao/.local/bin/voxtype record toggle"), { description = "Voxtype toggle" })
hl.bind("SUPER + F", hl.dsp.window.fullscreen(), { description = "Toggle Fullscreen" })
hl.bind("SUPER + SHIFT + V", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle Float" })
hl.bind(
	"SUPER + SHIFT + L",
	hl.dsp.exec_cmd("loginctl lock-session & omarchy-lock-screen"),
	{ description = "Lock Screen" }
)
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
hl.bind("SUPER + V", hl.dsp.exec_cmd("omarchy-launch-walker -m clipboard"), { description = "Clipboard" })
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
hl.bind(
	"SUPER + SPACE",
	hl.dsp.exec_cmd(
		[[bash -c 'pgrep -x quickshell >/dev/null && quickshell ipc -p ~/.config/quickshell call launcher toggle || (quickshell & sleep 1 && quickshell ipc -p ~/.config/quickshell call launcher toggle)']]
	),
	{ description = "Open Launcher" }
)
hl.bind(
	"SUPER + SHIFT + SPACE",
	hl.dsp.exec_cmd([[bash -c 'if pgrep -x quickshell >/dev/null; then pkill -x quickshell; else quickshell & fi']]),
	{ description = "Toggle Quickshell" }
)

-- Focus, swap, and resize bindings.
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

-- Workspace navigation.
hl.bind("SUPER + TAB", hl.dsp.focus({ workspace = "previous" }), { description = "Switch to last visited workspace" })
hl.bind("SUPER + CTRL + TAB", hl.dsp.focus({ workspace = "e+1" }), { description = "Next workspace" })

-- Toggles submap (SUPER + T): theme, sink, audio mute.
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

-- AI submap (SUPER + A): chatgpt, grok, perplexity.
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
