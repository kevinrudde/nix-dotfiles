hl.config({
    input = {
        kb_layout = "de",
        follow_mouse = 1,
        accel_profile = "flat",
        sensitivity = 0.35,

        touchpad = {
            natural_scroll = false,
            tap_to_click = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
        },
    },

    general = {
        gaps_in = 10,
        gaps_out = 10,
        border_size = 2,
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",

        col = {
            active_border = "rgba(89b4faff)",
            inactive_border = "rgba(45475aa0)",
        },
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        focus_on_activate = true,
    },
})
