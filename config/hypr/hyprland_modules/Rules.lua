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
  name = "browsing",
  match = { class = "^(zen)$" },
  fullscreen = true,
  workspace = "1 silent"
})

hl.window_rule({
  name = "vesktop-workspace",
  match = { class = "^(vesktop)$" },
  workspace =  "4 silent",
})

hl.window_rule({
    name = "music",
    match = { class = "^(spotify|spotify-launcher)$" },
    workspace = "special:spotify silent",
})

hl.window_rule({
  name = "beeper-workspace-class",
  match = { title = "^(beeper)$" },
  match = { class = "^(beeper)$" },
  workspace = "3 silent",
})

hl.window_rule({
    name = "dialogs",
    match = {
        title = "^(Open|Save|Choose File|Preferences|Properties)$",
    },
    float = true,
    center = true,
})

hl.window_rule({
    name = "PiP",
    match = {
        title = "Picture in Picture",
    },
    float = true,
    pin = true,
    move = {"100%-500","100%-320"},
    size = {480,270},
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

hl.workspace_rule({
    workspace = "special:spotify",
    gaps_in = 10,
    gaps_out = 30,
})

hl.workspace_rule({
    workspace = "special:scratch",
    gaps_in = 10,
    gaps_out = 30,
})

hl.window_rule({
  name  = "Floating windows",
  match = { class = "sensors|bluetui|thunar|nwg-look|org.kde.kdeconnect.sms|aichat|nmtui|battery|pulsemixer|org.gnome.Nautilus|org.kde.kdeconnect.app|localsend" },
  float = true,
  no_initial_focus = false,
  border_size = 2,
  opacity = "1.0",
  dim_around = true,
  focus_on_activate = true,
  pin = true,
  decorate = false,
  size = {"(monitor_w*0.55)","(monitor_h*0.60)"},
})
