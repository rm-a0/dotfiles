-- Catppuccin Mocha — https://github.com/catppuccin/catppuccin
-- Every colour Hyprland draws. Retheme via the semantic block at the bottom.

local M = {}

M.palette = {
    rosewater = "f5e0dc",
    flamingo  = "f2cdcd",
    pink      = "f5c2e7",
    mauve     = "cba6f7",
    red       = "f38ba8",
    maroon    = "eba0ac",
    peach     = "fab387",
    yellow    = "f9e2af",
    green     = "a6e3a1",
    teal      = "94e2d5",
    sky       = "89dceb",
    sapphire  = "74c7ec",
    blue      = "89b4fa",
    lavender  = "b4befe",

    text      = "cdd6f4",
    subtext1  = "bac2de",
    subtext0  = "a6adc8",
    overlay2  = "9399b2",
    overlay1  = "7f849c",
    overlay0  = "6c7086",
    surface2  = "585b70",
    surface1  = "45475a",
    surface0  = "313244",
    base      = "1e1e2e",
    mantle    = "181825",
    crust     = "11111b",
}

--- Build an `rgba(rrggbbaa)` string Hyprland understands.
--- @param name string  key in M.palette
--- @param alpha number|nil  0..1, defaults to fully opaque
function M.rgba(name, alpha)
    local hex = M.palette[name]
    assert(hex, "theme: unknown colour '" .. tostring(name) .. "'")
    local a = math.floor((alpha or 1.0) * 255 + 0.5)
    return string.format("rgba(%s%02x)", hex, a)
end

--- Build a 0xAARRGGBB integer, which is what shadow colours take.
function M.argb(name, alpha)
    local hex = M.palette[name]
    assert(hex, "theme: unknown colour '" .. tostring(name) .. "'")
    local a = math.floor((alpha or 1.0) * 255 + 0.5)
    return tonumber(string.format("%02x%s", a, hex), 16)
end

-- ── Optional wallpaper accent ────────────────────────────────────────────
-- rice-accent writes two hex triples here. Opt-in: `rice-accent auto on`.
local function read_accent_override()
    local state = os.getenv("XDG_STATE_HOME")
                  or (os.getenv("HOME") .. "/.local/state")
    local f = io.open(state .. "/rice/accent", "r")
    if not f then return nil end
    local a, b = f:read("l"), f:read("l")
    f:close()

    local function valid(v) return v and v:match("^%x%x%x%x%x%x$") end
    if not valid(a) then return nil end
    return a, valid(b) and b or a
end

local override, overrideAlt = read_accent_override()

M.palette.accentActive = override    or M.palette.mauve
M.palette.accentAltActive = overrideAlt or M.palette.lavender

-- Semantic roles. Everything else references these.
M.accent    = "accentActive"
M.accentAlt = "accentAltActive"

return M
