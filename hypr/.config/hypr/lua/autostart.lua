-- https://wiki.hypr.land/Configuring/Basics/Autostart/
--
-- waybar, mako, hyprpaper and hypridle are systemd user services under uwsm.
-- Only things without a unit belong here.

hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/libexec/polkit-mate-authentication-agent-1")

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
