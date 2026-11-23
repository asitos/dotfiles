return {
	-- yatline
	section_separator_open = "",
	section_separator_close = "",

	inverse_separator_open = "",
	inverse_separator_close = "",

	part_separator_open = "",
	part_separator_close = "",

	style_a = {
		fg = "#51000c",
		bg_mode = {
			normal = "#ffb3b1",
			select = "#f5b9a5",
			un_set = "#ffb4ab",
		},
	},
	style_b = { bg = "#30201f", fg = "#ffe9e8" },
	style_c = { bg = "#1e100f", fg = "#dbc0bf" },

	permissions_t_fg = "#ffb3b1",
	permissions_r_fg = "#fdb787",
	permissions_w_fg = "#ffb4ab",
	permissions_x_fg = "#f5b9a5",
	permissions_s_fg = "#ae9594",

	selected = { icon = "󰻭", fg = "#fdb787" },
	copied = { icon = "", fg = "#f5b9a5" },
	cut = { icon = "", fg = "#ffb4ab" },

	total = { icon = "󰮍", fg = "#f5b9a5" },
	succ = { icon = "", fg = "#ffb3b1" },
	fail = { icon = "", fg = "#ffb4ab" },
	found = { icon = "󰮕", fg = "#fdb787" },
	processed = { icon = "󰐍", fg = "#ffb3b1" },

	-- yatline-githead
	prefix_color = "#ae9594",
	branch_color = "#ffb3b1",
	commit_color = "#fdb787",
	behind_color = "#ffb4ab",
	ahead_color = "#f5b9a5",
	stashes_color = "#fdb787",
	state_color = "#ffb4ab",
	staged_color = "#f5b9a5",
	unstaged_color = "#fdb787",
	untracked_color = "#ae9594",
}
