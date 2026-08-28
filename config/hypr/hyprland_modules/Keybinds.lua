---------------------
---- KEYBINDINGS ----
---------------------

hl.config({
	input = {
		kb_options = "caps:swapescape",
	},
})

local mainMod = "SUPER"
local terminal = "kitty"
local menu = "tofi-drun --drun-launch=true"

hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("zen-browser"))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("obsidian"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("beeper"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("vesktop"))
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close(), { repeating = true })
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("remotegamepad &"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("~/.config/Scripts/toggle-speaker.sh"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("killall tofi tofi-drun hints hintsd"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("kitty -e yazi"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("pkill waybar || waybar"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("kitty --class clipse --title 'clipse-floating' -e clipse"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprshot -s -m region --clipboard-only --freeze"))
hl.bind(
	mainMod .. " + SHIFT + c",
	hl.dsp.exec_cmd("hyprshot -s -m region --freeze -o /home/asitos/Projects/cybersec/screenshots")
)
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("/home/asitos/.config/Scripts/ocr.sh"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("~/.config/Scripts/power_toggle.sh"))
-- hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("hyprshutdown"), { description = "reload hyprland" })
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("systemctl poweroff"))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("systemctl reboot"))
hl.bind(
	mainMod .. " + B",
	hl.dsp.exec_cmd(
		"bluetoothctl connect 10:E4:C2:5F:84:6E && killall galaxybudsclient; sleep 2; galaxybudsclient /StartMinimized &"
	)
)
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("hyprlock"))

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

hl.bind("ALT + mouse:274", hl.dsp.exec_cmd([[hyprctl eval 'hl.config({ cursor = { zoom_factor = 1.0 } })']]))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd(
		"wpctl set-volume -l 1.2 @DEFAULT_AUDIO_SINK@ 10%+ && paplay /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga"
	),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd(
		"wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%- && paplay /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga"
	),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = false }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = false }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%-"), { locked = true, repeating = true })

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

hl.bind(
	"ALT + BracketRight",
	hl.dsp.exec_cmd(
		"wpctl set-volume -l 1.2 @DEFAULT_AUDIO_SINK@ 10%+ && paplay /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga"
	),
	{ locked = true, repeating = true }
)
hl.bind(
	"ALT + BracketLeft",
	hl.dsp.exec_cmd(
		"wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%- && paplay /usr/share/sounds/freedesktop/stereo/audio-volume-change.oga"
	),
	{ locked = true, repeating = true }
)
hl.bind(
	"ALT + slash",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = false }
)
hl.bind(
	"ALT + backslash",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = false }
)
hl.bind("ALT + apostrophe", hl.dsp.exec_cmd("brightnessctl set 10%+"), { locked = true, repeating = true })
hl.bind("ALT + semicolon", hl.dsp.exec_cmd("brightnessctl set 10%-"), { locked = true, repeating = true })

hl.bind("ALT + C", hl.dsp.exec_cmd("hyprpicker -a"))

hl.bind("ALT + S", hl.dsp.exec_cmd(" bash ~/.config/Scripts/full_screenshot.sh"), { locked = true, repeating = false })
hl.bind("ALT + R", hl.dsp.exec_cmd("bash ~/.config/Scripts/screen_recorder.sh"), { locked = true, repeating = false })
for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + SHIFT + K", hl.dsp.exec_cmd("pkill kdeconnect-app || kdeconnect-app"), { repeating = false })

hl.bind("SUPER + S", hl.dsp.layout("swapsplit"))
hl.bind("SUPER + X", hl.dsp.layout("splitratio +0.1"))
hl.bind("SUPER + Z", hl.dsp.layout("splitratio -0.1"))
hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }))

hl.bind("SUPER + SPACE", hl.dsp.workspace.toggle_special("spotify"))
hl.bind("ALT + SPACE", hl.dsp.workspace.toggle_special("scratch"))
hl.bind(mainMod .. " + SHIFT + Space", hl.dsp.window.move({ workspace = "special:spotify" }))

-- ScrollOverview.lua
hl.bind("SUPER + G", function()
	hl.plugin.scrolloverview.overview("toggle all")
end)

-- hl.define_submap("scrolloverview", function()
-- 	hl.bind("H", hl.plugin.scrolloverview.navigate("left"))
-- 	hl.bind("L", hl.plugin.scrolloverview.navigate("right"))
-- 	hl.bind("K", hl.plugin.scrolloverview.navigate("up"))
-- 	hl.bind("J", hl.plugin.scrolloverview.navigate("down"))
-- 	hl.bind("return", hl.plugin.scrolloverview.overview("select"))
-- 	hl.bind("escape", hl.plugin.scrolloverview.overview("off"))
-- 	hl.bind("mouse:272", function()
-- 		-- Select the clicked window, or just the workspace if no window was clicked, then close the overview. This is the default behaviour if submap is not defined.
-- 		hl.plugin.scrolloverview.overview("select")
-- 		hl.plugin.scrolloverview.window("select")
-- 		hl.plugin.scrolloverview.overview("off")
-- 	end, { mouse = true })
-- 	hl.bind("mouse:274", hl.plugin.scrolloverview.window("close"), { mouse = true })
-- end)
