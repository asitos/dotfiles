hl.config({
  decoration = {
    rounding       = 0,
    rounding_power = 2,

    active_opacity   = 0.90,
    inactive_opacity = 0.85,
    fullscreen_opacity = 1,

    shadow = {
      enabled      = false,
      range        = 15,
      render_power = 3,
      color        = 0xee1a1a1a,
    },

    blur = {
      enabled   = true,
      passes    = 3,
      size      = 1,
      new_optimizations = true,
      xray = true,
      popups = false,
      ignore_opacity = true,
      popups_ignorealpha = 0,
      noise = 0.02,
      contrast = 1.6,
      brightness = 0.9,
      vibrancy  = 0.4,
      vibrancy_darkness = 0.4,
      special = false
    },
  },
})
