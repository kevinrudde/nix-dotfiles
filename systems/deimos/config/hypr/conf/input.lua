hl.config({
	input = {
		kb_layout = "de",
		follow_mouse = 1,
		touchpad = {
			natural_scroll = true,
			tap_to_click = true,
			disable_while_typing = true,
		},
	},

	general = {
		gaps_in = 4,
		gaps_out = 8,
		border_size = 2,
		resize_on_border = true,
		allow_tearing = false,
		layout = "dwindle",
	},

	dwindle = {
		force_split = 2,
		preserve_split = true,
	},

	binds = {
		drag_threshold = 10,
	},

	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		focus_on_activate = true,
	},
})

hl.gesture({ fingers = 4, direction = "horizontal", scale = 2.5, action = "workspace" })
