-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Load user modules from ~/.config and Omarchy defaults from $OMARCHY_PATH.
package.path = os.getenv("HOME")
    .. "/.config/?.lua;"
    .. (os.getenv("OMARCHY_PATH") or (os.getenv("HOME") .. "/.local/share/omarchy"))
    .. "/?.lua;"
    .. package.path

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
hl.window_rule({ match = { initial_class = "zen" }, size = { w = 500, h = 800 } })
hl.window_rule({ match = { initial_class = "zen" }, center = true })

hl.window_rule({ match = { class = "chrome-chatgpt.com__-Default" }, float = true })
hl.window_rule({ match = { class = "chrome-chatgpt.com__-Default" }, size = { w = 600, h = 800 } })
hl.window_rule({ match = { class = "chrome-chatgpt.com__-Default" }, move = { x = 1947, y = 47 } })

hl.window_rule({ match = { class = "chrome-translate.google.pt__-Default" }, float = true })
hl.window_rule({ match = { class = "chrome-translate.google.pt__-Default" }, size = { w = 600, h = 800 } })
hl.window_rule({ match = { class = "chrome-translate.google.pt__-Default" }, move = { x = 1343, y = 47 } })

hl.window_rule({ match = { initial_class = "steam_app_230410" }, render_unfocused = true })

hl.window_rule({ match = { initial_class = "Aether" }, float = true })
hl.window_rule({ match = { initial_class = "Aether" }, size = { w = 1259, h = 1000 } })
hl.window_rule({ match = { initial_class = "Aether" }, center = true })

-- Toggle config flags dynamically.
require("default.hypr.toggles")
