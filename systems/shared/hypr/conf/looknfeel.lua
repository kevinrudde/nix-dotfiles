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

	general = {
		col = {
			active_border = "rgba(89b4faff)",
			inactive_border = "rgba(45475aa0)",
		},
	},
})

hl.curve("standard", { type = "bezier", points = { { 0.2, 0.9 }, { 0.1, 1.0 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "standard", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "standard", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "standard" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "standard" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "standard", style = "slide" })
