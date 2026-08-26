-- Hyprland entry point. Settings live in lua/, colours in lua/theme.lua.
-- https://wiki.hypr.land/Configuring/

package.path = os.getenv("HOME") .. "/.config/hypr/?.lua;" .. package.path

require("lua.monitors")
require("lua.env")
require("lua.input")
require("lua.look")
require("lua.animations")
require("lua.rules")
require("lua.keybinds")
require("lua.autostart")
