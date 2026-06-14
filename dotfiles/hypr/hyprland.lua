-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

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

-- Omarchy defaults (loaded individually to exclude default autostart).
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

-- Change your own setup in these files and override defaults.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.envs")
require("hypr.looknfeel")
require("hypr.autostart")

-- Window rules for specific apps.
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

-- Toggle config flags dynamically.
require("default.hypr.toggles")
