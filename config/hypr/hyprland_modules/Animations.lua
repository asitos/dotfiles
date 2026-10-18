hl.config({
    animations = {
        enabled = true,
    }
})

-- Bezier curves
hl.curve("decel", {
    type = "bezier",
    points = { {0.05, 0.9}, {0.1, 1.0} }
})

hl.curve("fluent", {
    type = "bezier",
    points = { {0.48, 0.04}, {0.52, 0.96} }
})

hl.curve("quick", {
    type = "bezier",
    points = { {0.15, 0}, {0.1, 1} }
})

-- Animations
hl.animation({
    leaf = "global",
    enabled = true,
    speed = 10,
    bezier = "default",
})

hl.animation({
    leaf = "border",
    enabled = true,
    speed = 5,
    bezier = "decel",
})

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 4.5,
    bezier = "decel",
    style = "popin 85%",
})

hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 4,
    bezier = "fluent",
})

hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 3.5,
    bezier = "decel",
})

hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 3.5,
    bezier = "decel",
    style = "popin 85%",
})

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 4.5,
    bezier = "decel",
    style = "slidefade 20%",
})

hl.animation({
    leaf = "specialWorkspace",
    enabled = true,
    speed = 4,
    bezier = "decel",
    style = "slidevert",
})

hl.animation({
    leaf = "zoomFactor",
    enabled = true,
    speed = 7,
    bezier = "quick",
})
