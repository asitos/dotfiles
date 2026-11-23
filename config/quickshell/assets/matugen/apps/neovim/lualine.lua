local colors = {
  bg = "{{colors.surface.default.hex}}",
  bg_mid = "{{colors.surface_container.default.hex}}",
  fg = "{{colors.on_surface.default.hex}}",
  primary = "{{colors.primary.default.hex}}",
  on_primary = "{{colors.on_primary.default.hex}}",
  secondary = "{{colors.secondary.default.hex}}",
  on_secondary = "{{colors.on_secondary.default.hex}}",
  tertiary = "{{colors.tertiary.default.hex}}",
  on_tertiary = "{{colors.on_tertiary.default.hex}}",
  error = "{{colors.error.default.hex}}",
  on_error = "{{colors.on_error.default.hex}}",
  outline = "{{colors.outline.default.hex}}",
}

return {
  normal = {
    a = { fg = colors.on_primary, bg = colors.primary, gui = "bold" },
    b = { fg = colors.fg, bg = colors.bg_mid },
    c = { fg = colors.fg, bg = colors.bg },
    z = { fg = colors.on_primary, bg = colors.primary },
  },
  insert = {
    a = { fg = colors.on_secondary, bg = colors.secondary, gui = "bold" },
    b = { fg = colors.fg, bg = colors.bg_mid },
    c = { fg = colors.fg, bg = colors.bg },
    z = { fg = colors.on_secondary, bg = colors.secondary },
  },
  visual = {
    a = { fg = colors.on_tertiary, bg = colors.tertiary, gui = "bold" },
    b = { fg = colors.fg, bg = colors.bg_mid },
    c = { fg = colors.fg, bg = colors.bg },
    z = { fg = colors.on_tertiary, bg = colors.tertiary },
  },
  replace = {
    a = { fg = colors.on_error, bg = colors.error, gui = "bold" },
    b = { fg = colors.fg, bg = colors.bg_mid },
    c = { fg = colors.fg, bg = colors.bg },
    z = { fg = colors.on_error, bg = colors.error },
  },
  command = {
    a = { fg = colors.on_tertiary, bg = colors.tertiary, gui = "bold" },
    b = { fg = colors.fg, bg = colors.bg_mid },
    c = { fg = colors.fg, bg = colors.bg },
    z = { fg = colors.on_tertiary, bg = colors.tertiary },
  },
  inactive = {
    a = { fg = colors.outline, bg = colors.bg, gui = "bold" },
    b = { fg = colors.outline, bg = colors.bg_mid },
    c = { fg = colors.outline, bg = colors.bg },
    z = { fg = colors.outline, bg = colors.bg },
  },
}
