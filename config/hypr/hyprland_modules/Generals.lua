hl.config({
  general = {
    gaps_in  = 1,
    gaps_out = 0,
    border_size = 0,

    col = {
      active_border = "rgba(cba6f7ee)",
      inactive_border = "rgba(595959aa)",
    },

    resize_on_border = false,
    allow_tearing = true,
    layout = "dwindle",

    snap = {
      enabled = true,
      respect_gaps = true
    }
  },

  xwayland = {
    force_zero_scaling = true
  }
})
