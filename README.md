# dotfiles

Hyprland on Debian 13. Catppuccin Mocha, with an optional accent pulled from
the wallpaper.

![](https://img.shields.io/badge/WM-Hyprland-cba6f7?style=flat-square)
![](https://img.shields.io/badge/distro-Debian%2013-cba6f7?style=flat-square)
![](https://img.shields.io/badge/shell-zsh-cba6f7?style=flat-square)

| | |
|---|---|
| WM | Hyprland (uwsm session) |
| Bar | waybar |
| Launcher | fuzzel |
| Notifications | mako |
| Terminal | kitty |
| Editor | Neovim |
| Shell | zsh + powerlevel10k |
| Login | greetd + tuigreet |
| Lock | hyprlock + hypridle |
| Wallpaper | hyprpaper |

## Install

```sh
git clone https://github.com/<you>/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
```

`install.sh` wraps `stow --no-folding`. Pass package names to stow only some,
`-D` to remove. Safe to re-run.

<details>
<summary>Dependencies</summary>

```sh
sudo apt install \
  hyprland hyprpaper hypridle hyprlock uwsm \
  waybar mako-notifier fuzzel wlogout kitty fastfetch \
  python3-gi gir1.2-gtk-3.0 gir1.2-gtklayershell-0.1 \
  brightnessctl playerctl wl-clipboard cliphist grim slurp jq imagemagick chafa \
  network-manager network-manager-gnome bluez blueman \
  wireplumber pavucontrol power-profiles-daemon \
  gnome-control-center nwg-look nautilus loupe \
  btop cava zathura zathura-pdf-poppler \
  papirus-icon-theme bibata-cursor-theme stow zsh build-essential \
  fonts-noto-color-emoji fonts-symbola \
  greetd tuigreet
```

The Nerd Font covers box-drawing and its own private-use range; it does not
cover the emoji block, U+23BF or U+29C9, which a TUI renders as blank cells.
`fc-list ":charset=<hex>" family` names the font backing a codepoint.

Brave is `SUPER + B` and has its own repo:

```sh
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
  https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main' \
  | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt update && sudo apt install brave-browser
```

Not in apt at a usable version: Neovim ≥ 0.12 (trixie ships 0.10; nvim-treesitter
`main` requires 0.12, and `master` is locked at 0.11) and tree-sitter CLI ≥ 0.26.1
(trixie ships 0.22) — both from their upstream release tarballs into `~/.local`.
Also not in apt: JetBrainsMono Nerd Font, oh-my-zsh + powerlevel10k.
</details>

## Keys

`SUPER` throughout.

| | | | |
|---|---|---|---|
| `Return` | terminal | `1`–`0` | workspace |
| `R` | launcher | `SHIFT`+`1`–`0` | move to workspace |
| `E` | files | `TAB` | next workspace |
| `B` | browser | `S` | scratchpad |
| `C` | close | `H J K L` | focus |
| `V` | float | `SHIFT`+`HJKL` | move window |
| `F` | fullscreen | `CTRL`+arrows | resize |
| `W` | wallpaper picker | `SHIFT+V` | clipboard history |
| `CTRL+L` | lock | `M` | logout menu |
| `Print` | screenshot region | `SHIFT+Print` | screenshot screen |

`hyprctl binds` lists everything — each bind carries a description.

## Scripts

In `scripts/.local/bin`, symlinked to `~/.local/bin`.

| | |
|---|---|
| `rice-wallpaper` | set / pick / random / restore |
| `rice-accent` | derive an accent from the wallpaper |
| `rice-screenshot` | region, screen or window |
| `rice-wifi` `rice-bluetooth` `rice-audio` `rice-brightness` `rice-battery` | bar dropdowns |
| `rice-fetch` | fastfetch wrapper |
| `rice-brave` | Brave with the generated theme loaded |
| `rice-chromium-theme` | build the theme extension from the accent |
| `rice-setup-user` | install into another account |

The bar dropdowns are GTK layer-shell panels sharing one base class in
`scripts/.local/lib/rice/panel.py`. Each falls back to a fuzzel menu if
`gir1.2-gtklayershell-0.1` is missing.

## Accent

Off by default; the palette stays Catppuccin Mocha.

```sh
rice-accent auto on          # follow the wallpaper on every switch
rice-accent from image.png   # one-off
rice-accent reset            # back to mauve
```

Each target reads a small generated fragment that its config pulls in, so
nothing tracked here is ever rewritten:

| Target | Fragment | Pulled in by |
|---|---|---|
| waybar, wlogout, GTK 3/4 | `<app>/accent.css` | `@import` |
| hyprlock | `hypr/accent.conf` | `source =` |
| mako, zathura | `<app>/accent` | `include` |
| fuzzel | `fuzzel/accent.ini` | `include` |
| Hyprland, panels | `~/.local/state/rice/accent` | read at start |
| Discord | `Vencord/themes/` | `rice-discord-theme` |
| Brave | `rice/chromium-theme/` | `rice-brave --load-extension` |

## Checking changes

```sh
Hyprland --verify-config
WAYLAND_DISPLAY=nope hyprlock --display nope   # parses before it connects
fuzzel --check-config
makoctl reload
waybar -s ~/.config/waybar/style.css
zsh -n zsh/.zshrc
```

Two things fail quietly: GTK does not treat an undefined `@color` as an
error, and a glyph missing from the font renders as nothing rather than a
box. Check them with `Gtk.StyleContext.lookup_color` and
`fc-list ":charset=f0925" file`.

## Notes

- Never plain-kill hyprlock — `pkill -USR1 hyprlock` is the graceful unlock.
  A lockscreen that dies holding the session lock leaves the compositor on
  "lockdead", which needs a hard reboot.
- Under the Lua config, `hyprctl dispatch <string>` and `hyprctl keyword` are
  rejected. Read-only queries are fine.
- Discord runs through XWayland; its Wayland backend mis-sizes on a
  fractional scale. See `applications/` and `hypr/lua/monitors.lua`.
- Opacity has one owner per surface: windows in `lua/look.lua`, the terminal
  in `kitty.conf`, layer surfaces in their own stylesheets.
- greetd goes on vt 7. Debian's `greetd.service` conflicts only with
  `getty@tty7`, so on vt 1 the enabled `getty@tty1` keeps the console and you
  get a `login:` prompt instead of the greeter. `/etc/greetd/config.toml`:

  ```toml
  [terminal]
  vt = 7

  [default_session]
  command = "tuigreet --time --remember --remember-session --asterisks --sessions /usr/share/wayland-sessions"
  user = "_greetd"
  ```

  `--remember-session` pins the choice after the first login.
  `display-manager.service` is an alias that follows whichever DM is enabled.
