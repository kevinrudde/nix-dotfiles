hl.config({
	decoration = {
		rounding = 8,

		active_opacity = 1.0,
		inactive_opacity = 0.95,

		blur = {
			enabled = true,
			size = 8,
			passes = 2,
		},
	},

	animations = {
		enabled = false,
	},

	render = {
		-- 2 = auto: scan out directly only for windows tagged as games, so
		-- fullscreen video and browsers keep going through the compositor.
		direct_scanout = 2,
	},

	general = {
		col = {
			active_border = "rgba(7aa2f7ff)",
			inactive_border = "rgba(3b4261a0)",
		},
	},
})
