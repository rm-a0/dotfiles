-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- ── Layer surfaces ───────────────────────────────────────────────────────
-- ignore_alpha keeps blur out of transparent regions, so waybar reads as
-- separate pills rather than one smeared bar.
for _, ns in ipairs({ "waybar", "notifications", "launcher", "logout_dialog", "rice-panel",
                      "rice-gallery" }) do
    hl.layer_rule({
        name         = "blur-" .. ns,
        match        = { namespace = "^" .. ns .. "$" },
        blur         = true,
        ignore_alpha = 0.3,
    })
end

-- ── Terminal opacity ─────────────────────────────────────────────────────
-- kitty sets its own alpha; don't stack a second one.
hl.window_rule({
    name    = "kitty-owns-its-opacity",
    match   = { class = "^kitty$" },
    opacity = "1.0 1.0",
})

-- ── Floating utility windows ─────────────────────────────────────────────
local floating = {
    "^pavucontrol$",
    "^blueman%-manager$",
    "^nm%-connection%-editor$",
    "^nwg%-look$",
    "^org%.gnome%.Calculator$",
    "^xdg%-desktop%-portal%-gtk$",
}

for _, class in ipairs(floating) do
    hl.window_rule({
        name  = "float-" .. class:gsub("[^%w]", ""),
        match = { class = class },
        float = true,
    })
end

hl.window_rule({
    name  = "size-pavucontrol",
    match = { class = "^pavucontrol$" },
    size  = "900 600",
})

hl.window_rule({
    name  = "size-blueman",
    match = { class = "^blueman%-manager$" },
    size  = "800 550",
})

hl.window_rule({
    name  = "float-pip",
    match = { title = "^Picture%-in%-Picture$" },
    float = true,
    pin   = true,
    size  = "480 270",
})

-- File chooser dialogs
for _, title in ipairs({ "^Open File$", "^Save File$", "^Choose Files$" }) do
    hl.window_rule({
        name  = "float-dialog-" .. title:gsub("[^%w]", ""),
        match = { title = title },
        float = true,
    })
end

-- ── Fixes ────────────────────────────────────────────────────────────────
-- Some GTK/Qt apps maximize on map, which fights tiling.
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- XWayland drag surfaces have no class/title and steal focus.
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
