--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- hl.workspace_rule({ workspace = "2", layout = "scrolling" })
-- hl.workspace_rule({ workspace = "3", layout = "dwindle" })

hl.window_rule({
  name   = "nmgui-floater",
  match  = { title = "^(.*Network Manager.*)$" },
  float  = true,
})

hl.window_rule({
  name  = "clipse-floater",
  match = { class = "^(clipse)$" },
  match = { title = "^(clipse-floating)$" },
  float = true,
  move = {10,10},
  size = {600,400},
})

hl.window_rule({
  name = "zen-fs",
  match = { class = "^(zen)$" },
  fullscreen = true,
})

hl.window_rule({
  name = "vesktop-workspace",
  match = { class = "^(vesktop)$" },
  workspace =  "4 silent",
})

hl.window_rule({
  name = "spotify-workspace-class",
  match = { title = "^(spotify)$" },
  match = { class = "^(spotify)$" },
  workspace = "5 silent",
})

hl.window_rule({
  name = "spotify-workspace-class",
  match = { title = "^(beeper)$" },
  match = { class = "^(beeper)$" },
  workspace = "6 silent",
})

hl.layer_rule({
  name  = "tofi",
  match = { namespace = "tofi" },
  ignore_alpha = 0.8,
  animation = "popin 80%",
})

hl.layer_rule({
  name  = "mako",
  match = { namespace = "notifications" },
  blur = true,
  ignore_alpha = 0,
  animation = "slide right",
})

hl.window_rule({
  name  = "fix-xwayland-drags",
  match = {
    class      = "^$",
    title      = "^$",
    xwayland   = true,
    float      = true,
    fullscreen = false,
    pin        = false,
  },
  no_focus = true,
})

local suppressMaximizeRule = hl.window_rule({
  name  = "suppress-maximize-events",
  match = { class = ".*" },
  suppress_event = "maximize",
})

hl.window_rule({
  name  = "Floating windows",
  match = { class = "sensors|bluetui|thunar|nwg-look|org.kde.kdeconnect.sms|aichat|nmtui|battery|pulsemixer|org.gnome.Nautilus|org.kde.kdeconnect.app|localsend" },
  float = true,
  no_initial_focus = false,
  border_size = 2,
  opacity = "1.0",
  pin = true,
  decorate = false,
  size = {"(monitor_w*0.48)","(monitor_h*0.50)"},
})
