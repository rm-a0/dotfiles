-- https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        -- swap_lalt_lwin: the key next to the spacebar sends SUPER (the mod
        -- key every bind uses), and real Alt moves to the Win position, where
        -- Alt+F4 and menu mnemonics still reach the application. Binding mod
        -- to ALT directly would have the compositor swallow Alt+B/Alt+F before
        -- zsh's line editor ever sees them.
        kb_options = "caps:escape,altwin:swap_lalt_lwin",
        kb_rules   = "",

        follow_mouse       = 1,
        mouse_refocus      = false,
        sensitivity        = 0,
        numlock_by_default = true,

        touchpad = {
            natural_scroll       = true,
            tap_to_click         = true,
            disable_while_typing = true,
            scroll_factor        = 0.6,
        },
    },
})

-- 3-finger swipe = switch workspace
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

hl.device({
    name        = "elan-touchpad",
    sensitivity = 0.2,
})
