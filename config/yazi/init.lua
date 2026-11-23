-- ~/.config/yazi/init.lua

-- Linemode: Size and Modified Time
function Linemode:size_and_mtime()
	local time = math.floor(self._file.cha.mtime or 0)
	local time_str = ""
	if time > 0 then
		if os.date("%Y", time) == os.date("%Y") then
			time_str = os.date("%b %d %H:%M", time)
		else
			time_str = os.date("%b %d  %Y", time)
		end
	end

	local size = self._file:size()
	local size_str = size and ya.readable_size(size) or "-"
	return string.format("%s  %s", size_str, time_str)
end

require("full-border"):setup {
	type = ui.Border.ROUNDED,
}

require("smart-enter"):setup {
	open_multi = true,
}

-- Theme setup: prefer dynamic Matugen theme, fallback to Catppuccin Mocha
local config_dir = (os.getenv("YAZI_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/yazi"
package.path = package.path .. ";" .. config_dir .. "/?.lua"

local ok, yatline_theme = pcall(require, "yatline-theme")
if not ok or not yatline_theme then
	yatline_theme = require("yatline-catppuccin"):setup("mocha")
	yatline_theme.style_a.bg_mode.normal = "#b4befe" -- lavender
	yatline_theme.style_a.bg_mode.select = "#cba6f7" -- mauve/purple
	yatline_theme.style_a.bg_mode.un_set = "#f5c2e7" -- pink
	yatline_theme.style_b.fg = "#cba6f7"
	yatline_theme.style_c.fg = "#b4befe"
	yatline_theme.found = { icon = "", fg = "#b4befe" }
end

-- Yatline status & header line
require("yatline"):setup({
    theme = yatline_theme,

    section_separator = { open = "", close = "" },
    part_separator = { open = "", close = "" },
    inverse_separator = { open = "", close = "" },

    tab_width = 20,
    tab_use_inverse = false,

    show_background = true,

    display_header_line = true,
    display_status_line = true,

    component_positions = { "header", "tab", "status" },

    header_line = {
        left = {
            section_a = {
                {type = "line", custom = false, name = "tabs", params = {"left"}},
            },
            section_b = {},
            section_c = {}
        },
        right = {
            section_a = {
                {type = "string", custom = false, name = "date", params = {"%b %d  %H:%M"}},
            },
            section_b = {},
            section_c = {}
        }
    },

    status_line = {
        left = {
            section_a = {
                {type = "string", custom = false, name = "tab_mode"},
            },
            section_b = {
                {type = "string", custom = false, name = "hovered_size"},
            },
            section_c = {
                {type = "string", custom = false, name = "hovered_path"},
                {type = "coloreds", custom = false, name = "count"},
            }
        },
        right = {
            section_a = {
                {type = "string", custom = false, name = "cursor_position"},
            },
            section_b = {
                {type = "string", custom = false, name = "cursor_percentage"},
            },
            section_c = {
                {type = "string", custom = false, name = "hovered_file_extension", params = {true}},
                {type = "coloreds", custom = false, name = "permissions"},
            }
        }
    },
})
