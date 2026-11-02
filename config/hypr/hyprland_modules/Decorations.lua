hl.config({
	decoration = {
		rounding = 0,
		rounding_power = 2,

		active_opacity = 0.90,
		inactive_opacity = 0.85,
		fullscreen_opacity = 1,

		shadow = {
			enabled = false,
			range = 15,
			render_power = 3,
			color = 0xee1a1a1a,
		},

		blur = {
			enabled = true,
			passes = 3,
			size = 1,
			new_optimizations = true,
			xray = true,
			popups = false,
			ignore_opacity = true,
			popups_ignorealpha = 0,
			noise = 0.02,
			contrast = 1.6,
			brightness = 0.9,
			vibrancy = 0.4,
			vibrancy_darkness = 0.4,
			special = false,
		},
	},

	group = {
		col = {
			border_active = 0xffb4befe,
			border_inactive = 0x66313244,
		},
		groupbar = {
			enabled = true,
			-- font_family = "Terminess Nerd Font",
			-- font_size = 10,
			height = 1,
			render_titles = false,
			gradients = false,
			col = {
				active = 0xffb4befe,
				inactive = 0xcc313244,
			},
			text_color = 0xff11111b,
		},
	},
})
