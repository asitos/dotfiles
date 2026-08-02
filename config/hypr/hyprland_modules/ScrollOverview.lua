-- .config/hypr/hyprland.lua
hl.config({
	plugin = {
		scrolloverview = {
			gesture_distance = 100, -- how far is the "max" for the gesture
			scale = 0.85, -- preferred overview scale
			workspace_gap = 20,
			layout = "vertical", -- vertical or horizontal
			wallpaper = 0, -- 0: global only, 1: per-workspace only, 2: both
			blur = false, -- blur only the main overview wallpaper
		},
	},
})
