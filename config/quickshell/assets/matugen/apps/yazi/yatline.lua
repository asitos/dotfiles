return {
	-- yatline
	section_separator_open = "",
	section_separator_close = "",

	inverse_separator_open = "",
	inverse_separator_close = "",

	part_separator_open = "",
	part_separator_close = "",

	style_a = {
		fg = "{{colors.on_primary.default.hex}}",
		bg_mode = {
			normal = "{{colors.primary.default.hex}}",
			select = "{{colors.secondary.default.hex}}",
			un_set = "{{colors.error.default.hex}}",
		},
	},
	style_b = { bg = "{{colors.surface_container.default.hex}}", fg = "{{colors.on_surface.default.hex}}" },
	style_c = { bg = "{{colors.surface.default.hex}}", fg = "{{colors.on_surface_variant.default.hex}}" },

	permissions_t_fg = "{{colors.primary.default.hex}}",
	permissions_r_fg = "{{colors.tertiary.default.hex}}",
	permissions_w_fg = "{{colors.error.default.hex}}",
	permissions_x_fg = "{{colors.secondary.default.hex}}",
	permissions_s_fg = "{{colors.outline.default.hex}}",

	selected = { icon = "󰻭", fg = "{{colors.tertiary.default.hex}}" },
	copied = { icon = "", fg = "{{colors.secondary.default.hex}}" },
	cut = { icon = "", fg = "{{colors.error.default.hex}}" },

	total = { icon = "󰮍", fg = "{{colors.secondary.default.hex}}" },
	succ = { icon = "", fg = "{{colors.primary.default.hex}}" },
	fail = { icon = "", fg = "{{colors.error.default.hex}}" },
	found = { icon = "󰮕", fg = "{{colors.tertiary.default.hex}}" },
	processed = { icon = "󰐍", fg = "{{colors.primary.default.hex}}" },

	-- yatline-githead
	prefix_color = "{{colors.outline.default.hex}}",
	branch_color = "{{colors.primary.default.hex}}",
	commit_color = "{{colors.tertiary.default.hex}}",
	behind_color = "{{colors.error.default.hex}}",
	ahead_color = "{{colors.secondary.default.hex}}",
	stashes_color = "{{colors.tertiary.default.hex}}",
	state_color = "{{colors.error.default.hex}}",
	staged_color = "{{colors.secondary.default.hex}}",
	unstaged_color = "{{colors.tertiary.default.hex}}",
	untracked_color = "{{colors.outline.default.hex}}",
}
