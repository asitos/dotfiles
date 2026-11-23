return {
	-- yatline
	section_separator_open = "",
	section_separator_close = "",

	inverse_separator_open = "",
	inverse_separator_close = "",

	part_separator_open = "",
	part_separator_close = "",

	style_a = {
		fg = "#400058",
		bg_mode = {
			normal = "#ecb1ff",
			select = "#e2bbdb",
			un_set = "#ffb4ab",
		},
	},
	style_b = { bg = "#29212b", fg = "#f8e9f7" },
	style_c = { bg = "#18111a", fg = "#d0c2d0" },

	permissions_t_fg = "#ecb1ff",
	permissions_r_fg = "#f4b4d7",
	permissions_w_fg = "#ffb4ab",
	permissions_x_fg = "#e2bbdb",
	permissions_s_fg = "#a397a4",

	selected = { icon = "󰻭", fg = "#f4b4d7" },
	copied = { icon = "", fg = "#e2bbdb" },
	cut = { icon = "", fg = "#ffb4ab" },

	total = { icon = "󰮍", fg = "#e2bbdb" },
	succ = { icon = "", fg = "#ecb1ff" },
	fail = { icon = "", fg = "#ffb4ab" },
	found = { icon = "󰮕", fg = "#f4b4d7" },
	processed = { icon = "󰐍", fg = "#ecb1ff" },

	-- yatline-githead
	prefix_color = "#a397a4",
	branch_color = "#ecb1ff",
	commit_color = "#f4b4d7",
	behind_color = "#ffb4ab",
	ahead_color = "#e2bbdb",
	stashes_color = "#f4b4d7",
	state_color = "#ffb4ab",
	staged_color = "#e2bbdb",
	unstaged_color = "#f4b4d7",
	untracked_color = "#a397a4",
}
