-- See https://wiki.hypr.land/Configuring/Variables/#input
hl.config({
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

-- Scroll faster in the terminal.
hl.window_rule({ match = { class = "(Alacritty|kitty|foot)" }, scroll_touchpad = 1.5 })
hl.window_rule({ match = { class = "com.mitchellh.ghostty" }, scroll_touchpad = 0.2 })
