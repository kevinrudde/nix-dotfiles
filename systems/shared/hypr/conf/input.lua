hl.config({
	input = {
		kb_layout = "de",
		follow_mouse = 1,
		touchpad = {
			natural_scroll = false,
			tap_to_click = true,
			disable_while_typing = true,
			clickfinger_behavior = true,
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

		-- Waking a blanked screen is a keyboard-only gesture: the lock screen
		-- comes back when you start typing your password, and a bumped desk or
		-- a mouse dragged past the laptop leaves it dark. The other half of
		-- this lives in home/features/hypr/hypridle.conf, whose lock-gated
		-- dpms-off rules deliberately carry no on-resume.
		key_press_enables_dpms = true,
		mouse_move_enables_dpms = false,
	},
})

hl.gesture({ fingers = 4, direction = "horizontal", scale = 2.5, action = "workspace" })
