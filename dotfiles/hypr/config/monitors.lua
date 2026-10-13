hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@75", position = "auto-left", scale = 1, transform = 1 })
-- ponytail: workspace 11 reserved for portrait, outside SUPER+1..10 range
hl.workspace_rule({ workspace = "11", monitor = "HDMI-A-1", default = true, persistent = true })
