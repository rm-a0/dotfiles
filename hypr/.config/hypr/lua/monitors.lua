-- https://wiki.hypr.land/Configuring/Basics/Monitors/

-- 15.6" 1080p 144Hz panel. scale 1.25 -> 1536x864 logical.
-- Fractional scales must divide the mode into whole logical pixels or
-- Hyprland rounds and leaves a seam: 1920/1.25 = 1536, 1080/1.25 = 864.
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@144",
    position = "0x0",
    scale    = 1.25,
})

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- Sharp XWayland on a fractional scale, at the cost of drawing at 1x.
-- Use the app's own zoom to get the size back, not
-- --force-device-scale-factor (kills Discord's GPU process).
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})
