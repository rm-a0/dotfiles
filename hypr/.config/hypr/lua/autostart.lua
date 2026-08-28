-- https://wiki.hypr.land/Configuring/Basics/Autostart/
--
-- waybar, mako, hyprpaper and hypridle are systemd user services under uwsm.
-- Only things without a unit belong here.

hl.on("hyprland.start", function()
    -- No polkit agent here: hyprpolkitagent ships with hyprland as an
    -- enabled user unit. Anything launched from this hook raced it to
    -- polkitd, and the loser exits with "an authentication agent already
    -- exists" and lingers as a dead process.

    -- cliphist only holds what these watchers record.
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    hl.exec_cmd("rice-wallpaper restore")
end)

-- hyprpaper misses outputs that appear after it started, so replug = black
-- screen without this.
for _, event in ipairs({ "monitor.added", "monitor.removed" }) do
    hl.on(event, function()
        hl.exec_cmd("rice-wallpaper restore")
    end)
end
