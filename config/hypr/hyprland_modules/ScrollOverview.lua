-- .config/hypr/hyprland_modules/ScrollOverview.lua

local plugin_path = os.getenv("HOME") .. "/.local/share/hyprland-plugins/hyprland-scroll-overview/scrolloverview.so"
hl.plugin.load(plugin_path)

if hl.plugin.scrolloverview then
	hl.config({
		plugin = {
			scrolloverview = {
				gesture_distance = 100, -- how far is the "max" for the gesture
				scale = 0.9, -- preferred overview scale
				workspace_gap = 10,
				layout = "vertical", -- vertical or horizontal
				wallpaper = 0, -- 0: global only, 1: per-workspace only, 2: both
				blur = false, -- blur only the main overview wallpaper
			},
		},
	})
end
