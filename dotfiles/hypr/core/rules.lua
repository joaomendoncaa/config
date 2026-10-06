-- Window rules: base defaults and per-app tweaks.
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- All app window rules are merged here to remove the omarchy require_all dependency.
--
-- Order matters:
--   1. Base defaults (suppress_event, tag +default-opacity, xwayland fix)
--   2. App-specific rules (may remove default-opacity tag)
--   3. Apply default opacity to remaining default-opacity tagged windows
local utils = require("core.utils")

utils.window(".*", { suppress_event = "maximize" })

utils.window(".*", { tag = "+default-opacity" })

utils.window(
	{ class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
	{ no_focus = true }
)

-- Browser tags and styling.
utils.window(
	"((google-)?[cC]hrom(e|ium)|[bB]rave-browser|[mM]icrosoft-edge|Vivaldi-stable|helium)",
	{ tag = "+chromium-based-browser" }
)
utils.window("([fF]irefox|zen|librewolf)", { tag = "+firefox-based-browser" })
utils.window({ tag = "chromium-based-browser" }, { tag = "-default-opacity", tile = true, opacity = "1.0 0.97" })
utils.window({ tag = "firefox-based-browser" }, { tag = "-default-opacity", opacity = "1.0 0.97" })

utils.window("(chrome-youtube.com__-Default|chrome-app.zoom.us__wc_home-Default)", { tag = "-chromium-based-browser" })
utils.window("(chrome-youtube.com__-Default|chrome-app.zoom.us__wc_home-Default)", { tag = "-default-opacity" })

utils.window({ title = ".*is sharing.*" }, { workspace = "special silent" })

-- Floating windows.
utils.window({ tag = "floating-window" }, { float = true })
utils.window({ tag = "floating-window" }, { center = true })
utils.window({ tag = "floating-window" }, { size = { 875, 600 } })

utils.window(
	"(org.omarchy.btop|org.omarchy.terminal|org.omarchy.bash|org.codeberg.dnkl.foot|org.gnome.NautilusPreviewer|org.gnome.Evince|com.gabm.satty|Omarchy|About|TUI.float|imv|mpv)",
	{ tag = "+floating-window" }
)
utils.window({
	class = "(xdg-desktop-portal-gtk|sublime_text|DesktopEditors|org.gnome.Nautilus)",
	title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to [open|save].*|[C|c]hoose.*)",
}, { tag = "+floating-window" })
utils.window("org.gnome.Calculator", { float = true })

-- Fullscreen screensaver.
utils.window("org.omarchy.screensaver", { fullscreen = true })
utils.window("org.omarchy.screensaver", { float = true })
utils.window("org.omarchy.screensaver", { animation = "slide" })

-- No transparency on media windows.
utils.window(
	"^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$",
	{ tag = "-default-opacity" }
)
utils.window(
	"^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$",
	{ opacity = "1 1" }
)

-- Popped window rounding.
utils.window({ tag = "pop" }, { rounding = 8 })

-- Prevent idle while open.
utils.window({ tag = "noidle" }, { idle_inhibit = "always" })

utils.window("^(1[p|P]assword)$", { no_screen_share = true, tag = "+floating-window" })

utils.window(
	{ class = "^steam_app_battlenet$", title = "^Battle\\.net$" },
	{ float = true, center = true, size = { 1280, 800 } }
)
utils.window(
	{ class = "^steam_app_battlenet$", title = "^Battle\\.net Setup$" },
	{ decorate = false, no_blur = true, no_shadow = true }
)

utils.window("^(Bitwarden)$", { no_screen_share = true, tag = "+floating-window" })
utils.window("chrome-nngceckbapebfimnlniiiahkandclblb-Default", { no_screen_share = true, tag = "+floating-window" })

utils.window("^(Emulator)$", { float = true })

-- Godot game windows launched from the editor (F5) map as "Godot" and only rename to " (DEBUG)" afterwards.
-- Static rules are evaluated at map time only, so catch them via the title event instead.
local godot_debug_floated = {}
hl.on("window.title", function(w)
	if godot_debug_floated[w.address] or w.class ~= "Godot_Engine" or not w.title:find(" (DEBUG)", 1, true) then
		return
	end

	godot_debug_floated[w.address] = true
	hl.dispatch(hl.dsp.window.float({ window = "address:" .. w.address, action = "on" }))
	hl.dispatch(hl.dsp.window.center({ window = "address:" .. w.address }))
end)

utils.window(".*[Rr]esolve.*", { float = true, stay_focused = true })

utils.window("GeForceNOW", { idle_inhibit = "fullscreen" })

hl.layer_rule({ match = { namespace = "selection" }, no_anim = true, animation = "none" })

utils.window("^(jetbrains-.*)$", { no_follow_mouse = true })

utils.window("(Share|localsend)", { float = true, center = true })
utils.window("localsend", { size = { 1100, 700 } })

utils.window("com.moonlight_stream.Moonlight", { fullscreen = true, idle_inhibit = "fullscreen" })

hl.layer_rule({ match = { namespace = "omarchy-bar" }, no_anim = true, animation = "none" })
hl.layer_rule({
	match = {
		namespace = "^(omarchy-menu|omarchy-launcher|omarchy-image-selector|omarchy-emojis|omarchy-clipboard|omarchy-keyboard-panel)$",
	},
	no_anim = true,
	animation = "none",
})
utils.window({ class = "^org.quickshell$", title = "^Omarchy shell \226\128\147 dev gallery$" }, { maximize = true })

-- Helium --app windows (all launch-webapp/comms/twitter apps) spawn floating
-- natively (dialog-type hint, centered, app-remembered size). Tile them all;
-- the specific float rules below (PiP, Meet, webcam, ChatGPT, Translate)
-- come later and still win for their own windows.
utils.window({ class = "Helium", initial_title = ".*_/" }, { tile = true })

-- Picture-in-picture.
utils.window({ title = "(Picture.?in.?[Pp]icture)" }, { tag = "+pip" })
utils.window({ tag = "pip" }, {
	tag = "-default-opacity",
	float = true,
	pin = true,
	size = { 600, 338 },
	keep_aspect_ratio = true,
	border_size = 0,
	opacity = "1 1",
	move = { "(monitor_w-window_w-40)", "(monitor_h*0.04)" },
})
utils.window({ tag = "chromium-based-browser", title = "^Meet - .+" }, {
	tag = "-default-opacity",
	float = true,
	pin = true,
	size = { 600, 338 },
	keep_aspect_ratio = true,
	border_size = 0,
	opacity = "1 1",
	move = { "(monitor_w-window_w-40)", "(monitor_h-window_h-40)" },
})

utils.window("qemu", { tag = "-default-opacity", opacity = "1 1" })

-- Barebones NixOS VM (bin/vm-nixos): pin to workspace 10.
utils.window({ title = "vm-nixos" }, { workspace = "10" })

utils.window(
	"com.libretro.RetroArch",
	{ fullscreen = true, tag = "-default-opacity", opacity = "1 1", idle_inhibit = "fullscreen" }
)

utils.window("steam", { float = true, idle_inhibit = "fullscreen" })
utils.window({ class = "steam", title = "Steam" }, { center = true, size = { 1100, 700 } })
utils.window("steam.*", { tag = "-default-opacity", opacity = "1 1" })
utils.window({ class = "steam", title = "Friends List" }, { size = { 460, 800 } })

utils.window("org.telegram.desktop", { focus_on_activate = false })

utils.window("(Alacritty|kitty|com.mitchellh.ghostty|foot|wezterm)", { tag = "+terminal" })
utils.window({ tag = "terminal" }, { tag = "-default-opacity", opacity = "0.97 0.9" })

utils.window({ class = "^Typora$", title = "^Print$" }, { float = true, center = true })

utils.window({ title = "WebcamOverlay" }, {
	tag = "-default-opacity",
	float = true,
	pin = true,
	no_initial_focus = true,
	no_dim = true,
	opacity = "1 1",
	move = { "(monitor_w-window_w-40)", "(monitor_h-window_h-40)" },
})

-- Apply default opacity after apps have had a chance to opt out.
utils.window({ tag = "default-opacity" }, { opacity = "0.97 0.9" })

hl.layer_rule({ match = { namespace = "^shell-blur$" }, blur = true })
hl.layer_rule({ match = { namespace = "^(dictation-osd|volume-osd)$" }, blur = true, no_anim = true })
hl.layer_rule({ match = { namespace = "^(shell-bar|superbar|power-menu)$" }, no_anim = true })

hl.window_rule({ match = { class = "(Alacritty|kitty|foot)" }, scroll_touchpad = 1.5 })
hl.window_rule({ match = { class = "com.mitchellh.ghostty" }, scroll_touchpad = 0.2 })
-- ChatGPT / Translate webapps (--app): class is the browser (Helium since
-- omarchy-launch-webapp defaulted to helium.desktop), so match the app URL in
-- initial_title instead of the dead chrome-*-Default classes.
-- Coords are the original absolute values (2560-wide layout).
utils.window({ initial_title = "chatgpt\\.com_/" }, { float = true, size = { 600, 800 }, move = { 1947, 47 } })
utils.window({ initial_title = "translate\\.google\\..*/" }, { float = true, size = { 600, 800 }, move = { 1343, 47 } })
hl.window_rule({ match = { initial_class = "steam_app_230410" }, render_unfocused = true })
hl.window_rule({ match = { initial_class = "Aether" }, float = true })
hl.window_rule({ match = { initial_class = "Aether" }, size = { 1259, 1000 } })
hl.window_rule({ match = { initial_class = "Aether" }, center = true })
