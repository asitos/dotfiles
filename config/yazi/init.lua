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

-- Generate Catppuccin Mocha theme with lavender/mauve accent
local catppuccin_theme = require("yatline-catppuccin"):setup("mocha")
catppuccin_theme.style_a.bg_mode.normal = "#b4befe" -- lavender
catppuccin_theme.style_a.bg_mode.select = "#cba6f7" -- mauve/purple
catppuccin_theme.style_a.bg_mode.un_set = "#f5c2e7" -- pink
catppuccin_theme.style_b.fg = "#cba6f7"
catppuccin_theme.style_c.fg = "#b4befe"
catppuccin_theme.found = { icon = "", fg = "#b4befe" }

-- Yatline status & header line
require("yatline"):setup({
    theme = catppuccin_theme,

    section_separator = { open = "", close = "" },
    part_separator = { open = "", close = "" },
    inverse_separator = { open = "", close = "" },

    tab_width = 20,
    tab_use_inverse = false,

    selected = { icon = "󰻭", fg = "#f5c2e7" },
    copied = { icon = "", fg = "#b4befe" },
    cut = { icon = "", fg = "#f38ba8" },

    total = { icon = "󰮍", fg = "#cba6f7" },
    succ = { icon = "", fg = "#a6e3a1" },
    fail = { icon = "", fg = "#f38ba8" },
    found = { icon = "󰮕", fg = "#b4befe" },
    processed = { icon = "󰐍", fg = "#f5c2e7" },

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

