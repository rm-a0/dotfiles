-- https://wiki.hypr.land/Configuring/Basics/Monitors/

-- 14" 1080p panel. scale 1.5 -> 1280x720 logical.
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = 1.5,
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
