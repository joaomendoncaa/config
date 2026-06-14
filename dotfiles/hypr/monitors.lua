-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and resolutions possible: hyprctl monitors all

hl.env("GDK_SCALE", "1")
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
