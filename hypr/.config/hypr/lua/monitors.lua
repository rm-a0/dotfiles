-- https://wiki.hypr.land/Configuring/Basics/Monitors/

-- Any output. Per-machine rules go in monitors_local.lua next to this
-- file (untracked). Fractional scales must divide the mode into whole
-- logical pixels or Hyprland rounds and leaves a seam.
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

-- Probe first: Hyprland logs a failed require as a config error, even
-- under pcall.
if package.searchpath("lua.monitors_local", package.path) then
    require("lua.monitors_local")
end
