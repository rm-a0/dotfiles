-- https://wiki.hypr.land/Configuring/Basics/Variables/
--
-- One owner per surface, or opacity multiplies: windows here, terminal in
-- kitty.conf, layer surfaces in their own stylesheets.

local theme = require("lua.theme")

hl.config({
    general = {
        -- Logical pixels: at scale 1.5 these cost double.
        gaps_in  = 4,
        gaps_out = 8,

        border_size = 2,

        col = {
            active_border = {
                colors = { theme.rgba(theme.accent), theme.rgba(theme.accentAlt) },
                angle  = 45,
            },
            inactive_border = theme.rgba("surface0", 0.6),
        },

        resize_on_border     = true,
        hover_icon_on_border = true,
        allow_tearing        = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.00,
        inactive_opacity = 0.92,

        dim_inactive = true,
        dim_strength = 0.08,

        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 3,
            color        = theme.argb("crust", 0.67),
            offset       = "0 2",
        },

        blur = {
            enabled            = true,
            size               = 6,
            passes             = 2,
            vibrancy           = 0.17,
            noise              = 0.012,
            contrast           = 0.9,
            brightness         = 0.85,
            new_optimizations  = true,
            ignore_opacity     = true,
            popups             = true,
            popups_ignorealpha = 0.4,
        },
    },

    dwindle = {
        -- pseudotile is a dispatcher, not a setting (SUPER+P).
        preserve_split = true,
        smart_split    = false,
    },

    master = {
        new_status = "master",
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
        focus_on_activate        = true,
        mouse_move_enables_dpms  = true,
        key_press_enables_dpms   = true,

        -- Escape hatch from "lockdead". Never plain-kill hyprlock --
        -- use `pkill -USR1 hyprlock`.
        allow_session_lock_restore = true,

        -- VFR is `debug:vfr`, on by default. Leave it alone.
    },

    cursor = {
        inactive_timeout  = 5,
        hide_on_key_press = true,
    },
})
