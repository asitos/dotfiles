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
  },

  render = {
    direct_scanout = auto,
    expand_undersized_textures = true,

    xp_mode = false,

    ctm_animation = 2,

    cm_enabled = true,
    cm_auto_hdr = 1,
    cm_sdr_eotf = default,
    non_shader_cm = 3,
    non_shader_cm_interop = 2,

    send_content_type = true,

    new_render_scheduling = false,

    commit_timing_enabled = true,

    use_fp16 = 2,
    fp16_sdr_tf = 0,

    keep_unmodified_copy = 2,

    use_shader_blur_blend = false,

    icc_vcgt_enabled = true,
 
  },
})
