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
sudo apt install -y git
git clone https://github.com/<you>/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
```

On a stock Debian 13 that is the whole install. Safe to re-run: every phase is
a no-op once done.

```sh
./install.sh                 everything
./install.sh --stow          symlinks only
./install.sh --stow hypr kitty
./install.sh -D              unstow, restore a bare $HOME
./install.sh --no-session    keep the current login manager
./install.sh --no-sudo       skip every phase needing root
```

Whatever stow would collide with (`/etc/skel`'s `.zshrc`, a GTK-written
`settings.ini`) is moved to `~/.dotfiles-backup-<timestamp>/`, not overwritten.
Hardware firmware is not installed — that is the Debian installer's job.

No wallpapers ship with the repo: put images in `~/Pictures/wallpapers` (or
set `RICE_WALLPAPER_DIR`), or the desktop and lock screen stay blank.

Per-machine config stays out of the repo, loaded only if present:

| File | For |
|---|---|
| `~/.zshrc.local` | private aliases, functions, env |
| `~/.config/hypr/lua/monitors_local.lua` | output modes, scale, layout |

<details>
<summary>What it installs</summary>

**Backports.** The Hyprland stack — `hyprland`, `hyprpaper`, `hypridle`,
`hyprlock`, `uwsm`, `xdg-desktop-portal-hyprland`, `hyprpolkitagent` — is not
in `trixie/main`, so a stock box answers `apt install hyprland` with "Unable
to locate package". The script adds `backports.sources` and installs that
stack with `-t trixie-backports`; backports is pin priority 100, so without
the suite apt will not raise the backported dependencies and stops on
`libxkbcommon0 (>= 1.12.3) but 1.7.0-2 is to be installed`.

**apt**, grouped as in the script:

```sh
# compositor + session          (backports, installed with -t)
hyprland hyprpaper hypridle hyprlock uwsm xdg-desktop-portal-hyprland hyprpolkitagent
# the rest of the session
waybar mako-notifier fuzzel wlogout kitty fastfetch
# the bar dropdowns are GTK layer-shell panels
python3-gi python3-gi-cairo python3-cairo
gir1.2-gtk-3.0 gir1.2-gtklayershell-0.1 gir1.2-gdkpixbuf-2.0 gir1.2-pango-1.0
# called by the rice-* scripts
brightnessctl playerctl wl-clipboard cliphist grim slurp jq imagemagick
chafa libnotify-bin xdg-utils dconf-cli libglib2.0-bin upower
# network, bluetooth, audio, power
network-manager network-manager-gnome bluez blueman
pipewire pipewire-pulse wireplumber gstreamer1.0-pipewire
pavucontrol power-profiles-daemon
# apps the keybinds and mime defaults point at
gnome-control-center nwg-look nautilus loupe btop cava zathura zathura-pdf-poppler
# theme + fonts
papirus-icon-theme bibata-cursor-theme
fonts-noto-color-emoji fonts-symbola fonts-jetbrains-mono
# shell and CLI tooling
stow zsh git curl wget unzip ca-certificates gnupg build-essential
ripgrep fd-find nodejs npm
# login manager
greetd tuigreet
```

Easy to miss: `libglib2.0-bin` (gsettings), `libnotify-bin` (notify-send),
`xdg-utils` (xdg-mime) and `dconf-cli`, without which `rice-gsettings`,
`rice-mime` and every script that notifies fail.

**Not in apt**, fetched into `~/.local` at pinned versions, each checked
against a pinned sha256:

| | | |
|---|---|---|
| Neovim | `v0.12.5` | trixie ships 0.10; nvim-treesitter `main` needs 0.12 |
| tree-sitter CLI | `v0.26.13` | trixie ships 0.22; `main` needs >= 0.26.1 |
| JetBrainsMono Nerd Font | `v3.4.0` | Mono faces only; the rest break cell alignment |

Debian ships `fd` as `fdfind`, so `~/.local/bin/fd` is symlinked. oh-my-zsh and
powerlevel10k are cloned, and the login shell set to zsh. Brave has its own
repo; the script adds the keyring and list. Discord has only a `.deb`, installed
through `rice-discord-update` — re-run that to update it. Vencord is manual;
its install command is in that script.

**Neovim plugins** are installed, then pinned to `lazy-lock.json` with
`Lazy! restore` rather than `sync`. That lock is what holds telescope and
nvim-treesitter on branches that agree — telescope `0.1.x` calls
nvim-treesitter master-only APIs (`parsers.ft_to_lang`) that `main` does not
have, and throws on every preview.

</details>

<details>
<summary>Checking a codepoint renders</summary>

The Nerd Font covers box-drawing and its own private-use range; it does not
cover the emoji block, U+23BF or U+29C9, which a TUI renders as blank cells.
`fc-list ":charset=<hex>" family` names the font backing a codepoint.

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
| `W` | wallpaper gallery | `SHIFT+V` | clipboard history |
| `CTRL+L` | lock | `M` | logout menu |
| `Print` | screenshot region | `SHIFT+Print` | screenshot screen |

`hyprctl binds` lists everything — each bind carries a description.

## Scripts

In `scripts/.local/bin`, symlinked to `~/.local/bin`.

| | |
|---|---|
| `rice-wallpaper` | set / pick / random / restore |
| `rice-wallpaper-gallery` | the `SUPER + W` thumbnail carousel |
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
