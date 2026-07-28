----------------
----  MISC  ----
----------------

hl.config({
  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo   = true,
    disable_splash_rendering = true,
    animate_manual_resizes = false,
    vrr = 3,
    animate_mouse_windowdragging = false,
    initial_workspace_tracking = 2,
    enable_swallow = true,
    swallow_regex = "^(kitty)$",
    middle_click_paste = true,
    render_unfocused_fps = 15,
    disable_autoreload = false,
  },

  ecosystem = {
    no_update_news = true,
    no_donation_nag = true,
  },

})

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_THEME", "Catppuccin-Mocha-Dark-Cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__NV_PRIME_RENDER_OFFLOAD", "1")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")
