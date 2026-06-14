-- https://wiki.hyprland.org/Configuring/Variables/#general
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
})

hl.layer_rule({ match = { namespace = "superbar" }, blur = true, no_anim = true })
