-- https://wiki.hypr.land/Configuring/Basics/Binds/
-- Every bind has a `desc`, so `hyprctl binds` documents the keymap.

local mod = "SUPER"

local apps = {
    terminal    = "kitty",
    fileManager = "nautilus",
    browser     = "rice-brave",
    menu        = "fuzzel",
    clipboard   = 'cliphist list | fuzzel --dmenu --prompt "clip> " | cliphist decode | wl-copy',
}

-- ── Applications ─────────────────────────────────────────────────────────
hl.bind(mod .. " + Return",    hl.dsp.exec_cmd(apps.terminal),    { desc = "Terminal" })
hl.bind(mod .. " + Q",         hl.dsp.exec_cmd(apps.terminal),    { desc = "Terminal" })
hl.bind(mod .. " + E",         hl.dsp.exec_cmd(apps.fileManager), { desc = "File manager" })
hl.bind(mod .. " + B",         hl.dsp.exec_cmd(apps.browser),     { desc = "Browser" })
hl.bind(mod .. " + R",         hl.dsp.exec_cmd(apps.menu),        { desc = "Application launcher" })
hl.bind(mod .. " + SPACE",     hl.dsp.exec_cmd(apps.menu),        { desc = "Application launcher" })
hl.bind(mod .. " + SHIFT + V", hl.dsp.exec_cmd(apps.clipboard),   { desc = "Clipboard history" })

-- ── Session ──────────────────────────────────────────────────────────────
hl.bind(mod .. " + C",         hl.dsp.window.close(),                                  { desc = "Close window" })
hl.bind(mod .. " + CTRL + L",  hl.dsp.exec_cmd("loginctl lock-session"),                { desc = "Lock" })
hl.bind(mod .. " + M",         hl.dsp.exec_cmd("wlogout -p layer-shell -b 5"),          { desc = "Logout menu" })
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload && notify-send -a Hyprland 'Config reloaded'"),
                                                                                        { desc = "Reload config" })

-- ── Window state ─────────────────────────────────────────────────────────
hl.bind(mod .. " + V",         hl.dsp.window.float(),              { desc = "Toggle floating" })
hl.bind(mod .. " + P",         hl.dsp.window.pseudo(),             { desc = "Toggle pseudo-tiling" })
hl.bind(mod .. " + T",         hl.dsp.layout("togglesplit"),       { desc = "Toggle split direction" })
hl.bind(mod .. " + F",         hl.dsp.window.fullscreen(),         { desc = "Fullscreen" })
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = 1 }), { desc = "Maximise (keep gaps)" })
hl.bind(mod .. " + TAB",       hl.dsp.window.cycle_next(),         { desc = "Cycle windows" })

-- ── Focus, move, resize ──────────────────────────────────────────────────
-- One table drives focus, move and resize.
local directions = {
    { key = "left",  dir = "l", dx = -50, dy =   0 },
    { key = "right", dir = "r", dx =  50, dy =   0 },
    { key = "up",    dir = "u", dx =   0, dy = -50 },
    { key = "down",  dir = "d", dx =   0, dy =  50 },
    { key = "H",     dir = "l", dx = -50, dy =   0 },
    { key = "L",     dir = "r", dx =  50, dy =   0 },
    { key = "K",     dir = "u", dx =   0, dy = -50 },
    { key = "J",     dir = "d", dx =   0, dy =  50 },
}

for _, d in ipairs(directions) do
    hl.bind(mod .. " + " .. d.key,
            hl.dsp.focus({ direction = d.dir }),
            { desc = "Focus " .. d.dir })

    hl.bind(mod .. " + SHIFT + " .. d.key,
            hl.dsp.window.move({ direction = d.dir }),
            { desc = "Move window " .. d.dir })

    hl.bind(mod .. " + CTRL + " .. d.key,
            hl.dsp.window.resize({ x = d.dx, y = d.dy, relative = true }),
            { repeating = true, desc = "Resize " .. d.dir })
end

-- ── Workspaces ───────────────────────────────────────────────────────────
for i = 1, 10 do
    local key = i % 10          -- workspace 10 sits on the 0 key
    hl.bind(mod .. " + " .. key,
            hl.dsp.focus({ workspace = i }),
            { desc = "Workspace " .. i })

    hl.bind(mod .. " + SHIFT + " .. key,
            hl.dsp.window.move({ workspace = i, silent = true }),
            { desc = "Send to workspace " .. i })
end

hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { desc = "Next workspace" })
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { desc = "Previous workspace" })

-- Scratchpad
hl.bind(mod .. " + S",         hl.dsp.workspace.toggle_special("magic"),           { desc = "Toggle scratchpad" })
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), { desc = "Send to scratchpad" })

-- ── Mouse ────────────────────────────────────────────────────────────────
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, desc = "Drag window" })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, desc = "Resize window" })

-- ── Screenshots ──────────────────────────────────────────────────────────
hl.bind("Print",               hl.dsp.exec_cmd("rice-screenshot region"), { desc = "Screenshot region" })
hl.bind("SHIFT + Print",       hl.dsp.exec_cmd("rice-screenshot screen"), { desc = "Screenshot screen" })
hl.bind(mod .. " + Print",     hl.dsp.exec_cmd("rice-screenshot window"), { desc = "Screenshot window" })

-- ── Wallpaper ────────────────────────────────────────────────────────────
hl.bind(mod .. " + W",         hl.dsp.exec_cmd("rice-wallpaper gallery"), { desc = "Wallpaper gallery" })
hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd("rice-wallpaper random"), { desc = "Random wallpaper" })

-- ── Hardware keys ────────────────────────────────────────────────────────
-- locked = true: still works on the lock screen.
local media = {
    { key = "XF86AudioRaiseVolume",  cmd = "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+", rep = true,  desc = "Volume up" },
    { key = "XF86AudioLowerVolume",  cmd = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",        rep = true,  desc = "Volume down" },
    { key = "XF86MonBrightnessUp",   cmd = "brightnessctl -e4 -n2 set 5%+",                    rep = true,  desc = "Brightness up" },
    { key = "XF86MonBrightnessDown", cmd = "brightnessctl -e4 -n2 set 5%-",                    rep = true,  desc = "Brightness down" },
    { key = "XF86AudioMute",         cmd = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",       rep = false, desc = "Mute output" },
    { key = "XF86AudioMicMute",      cmd = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",     rep = false, desc = "Mute microphone" },
    { key = "XF86AudioPlay",         cmd = "playerctl play-pause",                             rep = false, desc = "Play/pause" },
    { key = "XF86AudioPause",        cmd = "playerctl play-pause",                             rep = false, desc = "Play/pause" },
    { key = "XF86AudioNext",         cmd = "playerctl next",                                   rep = false, desc = "Next track" },
    { key = "XF86AudioPrev",         cmd = "playerctl previous",                               rep = false, desc = "Previous track" },
}

for _, m in ipairs(media) do
    hl.bind(m.key, hl.dsp.exec_cmd(m.cmd), { locked = true, repeating = m.rep, desc = m.desc })
end
