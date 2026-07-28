------------------
---- GESTURES ----
------------------

hl.config({
  gestures = {
    workspace_swipe_create_new = false,
    workspace_swipe_forever = true,
    workspace_swipe_direction_lock = false,
    close_max_timeout = 100
  }
})

hl.gesture({
  fingers = 3,
  direction = "horizontal",
  action = "workspace"
})

hl.gesture({
  fingers = 2,
  direction = "pinchin",
  action = "fullscreen",
  mode = "maximize",
})

hl.gesture({
  fingers = 2,
  direction = "pinchout",
  action = "close",
})

hl.gesture({
  fingers = 3,
  mods = "SUPER",
  direction = "pinch",
  action = "float",
})

