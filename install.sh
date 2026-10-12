#!/usr/bin/env bash
# install.sh — take a stock Debian 13 (trixie) box to this rice.
#
#   ./install.sh                 everything: packages, tools, symlinks, session
#   ./install.sh --stow          symlinks only
#   ./install.sh --stow hypr kitty
#   ./install.sh -D              unstow — restore a bare $HOME
#   ./install.sh --no-session    keep the current login manager
#   ./install.sh --no-sudo       skip every phase needing root
#
# Every phase is a no-op once done, so this is safe to re-run.

set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

# $USER is not exported by every shell; id -un is.
ME=$(id -un)

# Not in apt at a usable version: trixie ships Neovim 0.10 (nvim-treesitter
# `main` needs 0.12) and tree-sitter 0.22 (needs >= 0.26.1). Bump by hand,
# hashes with them: the release page lists each asset's sha256.
NVIM_VERSION=v0.12.5
TREE_SITTER_VERSION=v0.26.13
NERD_FONT_VERSION=v3.4.0
NERD_FONT_SHA256=76f05ff3ace48a464a6ca57977998784ff7bdbb65a6d915d7e401cd3927c493c

# ── output ───────────────────────────────────────────────────────────────
if [ -t 1 ]; then B=$'\e[1m'; D=$'\e[2m'; G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; N=$'\e[0m'
else B=""; D=""; G=""; Y=""; R=""; N=""; fi
phase() { printf '\n%s==>%s %s%s%s\n' "$B" "$N" "$B" "$*" "$N"; }
ok()    { printf '  %s✓%s %s\n' "$G" "$N" "$*"; }
skip()  { printf '  %s·%s %s\n' "$D" "$N" "$*"; }
warn()  { printf '  %s!%s %s\n' "$Y" "$N" "$*" >&2; }
die()   { printf '%serror:%s %s\n' "$R" "$N" "$*" >&2; exit 1; }

# fetch <url> <file> <sha256>. HTTPS through every redirect.
fetch() {
    curl -fsSL --proto '=https' --tlsv1.2 -o "$2" "$1"
    printf '%s  %s\n' "$3" "$2" | sha256sum -c --status - || die "checksum mismatch: $1"
}

# ── arguments ────────────────────────────────────────────────────────────
ACTION="-R"                        # restow: safe to re-run
STOW_ONLY=0
DO_SUDO=1
DO_SESSION=1
PACKAGES=()

while [ $# -gt 0 ]; do
    case "$1" in
        -D)           ACTION="-D"; STOW_ONLY=1 ;;
        --stow)       STOW_ONLY=1 ;;
        --no-sudo)    DO_SUDO=0 ;;
        --no-session) DO_SESSION=0 ;;
        -h|--help)    sed -n '2,12p' "$0" | sed 's/^# \?//'; exit 0 ;;
        -*)           die "unknown flag: $1" ;;
        *)            PACKAGES+=("$1"); STOW_ONLY=1 ;;
    esac
    shift
done

# ── preflight ────────────────────────────────────────────────────────────
[ "$(id -u)" -ne 0 ] || die "run as your own user, not root — the symlinks go in \$HOME"

if [ $STOW_ONLY -eq 0 ]; then
    . /etc/os-release 2>/dev/null || die "no /etc/os-release — not a Linux this script knows"
    [ "${ID:-}" = "debian" ] || warn "this targets Debian; found ${ID:-unknown}. Package names may differ."
    [ "${VERSION_CODENAME:-}" = "trixie" ] || warn "this targets trixie; found ${VERSION_CODENAME:-unknown}."
    CODENAME=${VERSION_CODENAME:-trixie}

    if [ $DO_SUDO -eq 1 ]; then
        command -v sudo >/dev/null || die "sudo is required, or pass --no-sudo"
        sudo -v || die "sudo failed"
        # Keep sudo warm; the apt and download phases outlast the timestamp.
        while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
        SUDO_KEEPALIVE=$!
        trap 'kill $SUDO_KEEPALIVE 2>/dev/null || true' EXIT
    fi
fi

case "$(uname -m)" in
    x86_64)  NVIM_ARCH=linux-x86_64; TS_ARCH=linux-x64
             NVIM_SHA256=bce0f56eda1f1b1db6eee8f4133d7a38813ea07933837dd1777411ca384c6875
             TS_SHA256=c9c8bef027658d60249ca4fc0663578ceb2e2029346bb8702e091e20d7716475 ;;
    aarch64) NVIM_ARCH=linux-arm64;  TS_ARCH=linux-arm64
             NVIM_SHA256=1aa5ca085249580ae0f91eb14f27ec0919773ff2d99a163d03f3d6c21ac29725
             TS_SHA256=088c5ebf4b4b558c8abfd167c9c4f9669c2f9070da3edd9c0157dc051d77ac5d ;;
    *)       NVIM_ARCH=""; TS_ARCH="" ;;
esac

# ── apt ──────────────────────────────────────────────────────────────────
# Backports-only; installed by suite in apt_phase.
BACKPORTS_PACKAGES=(
    hyprland hyprpaper hypridle hyprlock uwsm xdg-desktop-portal-hyprland
    hyprpolkitagent   # autostart.lua expects this to start itself
)

APT_PACKAGES=(
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
    gnome-control-center nwg-look nautilus loupe
    btop cava zathura zathura-pdf-poppler

    # theme + fonts. The Nerd Font is not in apt; see font_phase.
    papirus-icon-theme bibata-cursor-theme
    fonts-noto-color-emoji fonts-symbola fonts-jetbrains-mono

    # ripgrep and fd back telescope's pickers, nodejs runs pyright,
    # build-essential builds telescope-fzf-native.
    stow zsh git curl wget unzip ca-certificates gnupg build-essential
    ripgrep fd-find nodejs npm

    # nvim jupyter: venv for molten's host (see jupyter_phase), and the
    # libraries notebook kernels see through --system-site-packages.
    python3-venv python3-numpy python3-scipy python3-matplotlib

    # login manager
    greetd tuigreet
)

# The Hyprland stack is backports-only, and a stock install has no backports
# line: `apt install hyprland` answers "Unable to locate package".
backports_phase() {
    phase "$CODENAME-backports"
    if grep -rqs -- "$CODENAME-backports" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
        skip "already enabled"
        return
    fi
    # Mirror the box's own URI. Real source lines only: the stock
    # debian.sources carries a commented snapshot.debian.org one.
    local uri
    uri=$( {
        grep -rhE '^[[:space:]]*URIs:' /etc/apt/sources.list.d/ 2>/dev/null \
            | awk '{for (i = 2; i <= NF; i++) print $i}'
        grep -rhE '^[[:space:]]*deb[[:space:]]' \
            /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null \
            | awk '{for (i = 2; i <= NF; i++) if ($i ~ /^https?:\/\//) { print $i; break }}'
    } | grep -m1 -E '/debian/?$' ) || true
    [ -n "$uri" ] || uri=http://deb.debian.org/debian

    # Trixie ships the archive key as .pgp; older images carry .gpg.
    local key
    for key in /usr/share/keyrings/debian-archive-keyring.pgp \
               /usr/share/keyrings/debian-archive-keyring.gpg; do
        [ -f "$key" ] && break
    done

    sudo tee /etc/apt/sources.list.d/backports.sources >/dev/null <<EOF
# Added by dotfiles/install.sh — the Hyprland stack lives here.
Types: deb
URIs: $uri
Suites: $CODENAME-backports
Components: main contrib non-free non-free-firmware
Signed-By: $key
EOF
    sudo apt-get update -qq
    ok "enabled $CODENAME-backports ($uri)"
}

missing_packages() {
    local p
    for p in "$@"; do
        dpkg-query -W -f='${Status}' "$p" 2>/dev/null \
            | grep -q '^install ok installed$' || printf '%s\n' "$p"
    done
}

apt_phase() {
    phase "apt packages"
    local missing=() missing_bpo=()
    mapfile -t missing     < <(missing_packages "${APT_PACKAGES[@]}")
    mapfile -t missing_bpo < <(missing_packages "${BACKPORTS_PACKAGES[@]}")

    local total=$(( ${#APT_PACKAGES[@]} + ${#BACKPORTS_PACKAGES[@]} ))
    if [ ${#missing[@]} -eq 0 ] && [ ${#missing_bpo[@]} -eq 0 ]; then
        skip "all $total packages already installed"
        return
    fi
    printf '  installing %d of %d\n' "$(( ${#missing[@]} + ${#missing_bpo[@]} ))" "$total"
    sudo apt-get update -qq

    # Recommends left on: this is the set the working machine was built with.
    if [ ${#missing[@]} -gt 0 ]; then
        printf '    %s\n' "${missing[@]}"
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing[@]}"
    fi

    # Backports is priority 100, so apt will not raise a backported
    # dependency on its own; naming the suite promotes the whole tree.
    if [ ${#missing_bpo[@]} -gt 0 ]; then
        printf '    %s (-t %s)\n' "${missing_bpo[@]}" "$CODENAME-backports"
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
            -t "$CODENAME-backports" "${missing_bpo[@]}"
    fi
    ok "apt done"
}

brave_phase() {
    phase "brave (own apt repo)"
    if command -v brave-browser >/dev/null; then skip "brave-browser present"; return; fi
    local key=/usr/share/keyrings/brave-browser-archive-keyring.gpg
    sudo curl -fsSL --proto '=https' --tlsv1.2 -o "$key" https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=$key] https://brave-browser-apt-release.s3.brave.com/ stable main" \
        | sudo tee /etc/apt/sources.list.d/brave-browser-release.list >/dev/null
    sudo apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y brave-browser
    ok "brave-browser installed"
}

# No apt repo, only a .deb; rice-discord-update also handles later updates.
# applications/discord.desktop points at /usr/bin/discord.
discord_phase() {
    phase "discord (upstream .deb)"
    if command -v discord >/dev/null; then skip "discord present"; return; fi
    if [ "$(uname -m)" != x86_64 ]; then warn "discord ships amd64 only; skipping"; return; fi
    ./scripts/.local/bin/rice-discord-update
    ok "discord installed"
}

# ── upstream tarballs into ~/.local ───────────────────────────────────────
neovim_phase() {
    phase "neovim $NVIM_VERSION"
    if [ -z "$NVIM_ARCH" ]; then warn "no neovim build for $(uname -m); skipping"; return; fi
    if [ -x "$HOME/.local/bin/nvim" ] && "$HOME/.local/bin/nvim" --version 2>/dev/null | grep -qF "${NVIM_VERSION#v}"; then
        skip "nvim ${NVIM_VERSION} already installed"; return
    fi
    local tmp; tmp=$(mktemp -d); trap 'rm -rf "$tmp"' RETURN
    fetch "https://github.com/neovim/neovim/releases/download/$NVIM_VERSION/nvim-$NVIM_ARCH.tar.gz" \
        "$tmp/nvim.tar.gz" "$NVIM_SHA256"
    mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
    rm -rf "$HOME/.local/opt/nvim-$NVIM_ARCH"
    tar -xzf "$tmp/nvim.tar.gz" -C "$HOME/.local/opt"
    ln -sfn "../opt/nvim-$NVIM_ARCH/bin/nvim" "$HOME/.local/bin/nvim"
    ok "$("$HOME/.local/bin/nvim" --version | head -1)"
}

tree_sitter_phase() {
    phase "tree-sitter CLI $TREE_SITTER_VERSION"
    if [ -z "$TS_ARCH" ]; then warn "no tree-sitter build for $(uname -m); skipping"; return; fi
    if [ -x "$HOME/.local/bin/tree-sitter" ] &&
       [ "$("$HOME/.local/bin/tree-sitter" --version 2>/dev/null | awk '{print $2}')" = "${TREE_SITTER_VERSION#v}" ]; then
        skip "tree-sitter ${TREE_SITTER_VERSION} already installed"; return
    fi
    local tmp; tmp=$(mktemp -d); trap 'rm -rf "$tmp"' RETURN
    fetch "https://github.com/tree-sitter/tree-sitter/releases/download/$TREE_SITTER_VERSION/tree-sitter-$TS_ARCH.gz" \
        "$tmp/ts.gz" "$TS_SHA256"
    mkdir -p "$HOME/.local/bin"
    gunzip -c "$tmp/ts.gz" > "$HOME/.local/bin/tree-sitter"
    chmod +x "$HOME/.local/bin/tree-sitter"
    ok "$("$HOME/.local/bin/tree-sitter" --version)"
}

font_phase() {
    phase "JetBrainsMono Nerd Font $NERD_FONT_VERSION"
    if fc-list : family 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
        skip "Nerd Font already registered"; return
    fi
    local tmp; tmp=$(mktemp -d); trap 'rm -rf "$tmp"' RETURN
    fetch "https://github.com/ryanoasis/nerd-fonts/releases/download/$NERD_FONT_VERSION/JetBrainsMono.zip" \
        "$tmp/font.zip" "$NERD_FONT_SHA256"
    mkdir -p "$HOME/.local/share/fonts"
    # Mono variants only: the proportional ones break terminal cell alignment.
    unzip -qo "$tmp/font.zip" 'JetBrainsMonoNerdFontMono-*.ttf' -d "$HOME/.local/share/fonts"
    fc-cache -f "$HOME/.local/share/fonts" >/dev/null
    ok "installed $(ls "$HOME"/.local/share/fonts/JetBrainsMonoNerdFontMono-*.ttf | wc -l) faces"
}

fd_phase() {
    phase "fd shim"
    # Debian ships the binary as fdfind; everything else looks for fd.
    if [ -e "$HOME/.local/bin/fd" ]; then skip "~/.local/bin/fd exists"; return; fi
    if ! command -v fdfind >/dev/null; then warn "fdfind not installed; skipping"; return; fi
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
    ok "fd -> $(command -v fdfind)"
}

zsh_phase() {
    phase "zsh, oh-my-zsh, powerlevel10k"
    if [ -d "$HOME/.oh-my-zsh" ]; then
        skip "oh-my-zsh present"
    else
        # Clone, not upstream's install.sh: that runs unpinned remote code
        # while sudo is cached, and its chsh and .zshrc steps are done here.
        git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
        ok "oh-my-zsh cloned"
    fi

    local p10k="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    if [ -d "$p10k" ]; then
        skip "powerlevel10k present"
    else
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k"
        ok "powerlevel10k cloned"
    fi

    if [ "$(getent passwd "$ME" | cut -d: -f7)" = "$(command -v zsh)" ]; then
        skip "login shell is already zsh"
    elif [ $DO_SUDO -eq 1 ] && sudo chsh -s "$(command -v zsh)" "$ME"; then
        ok "login shell -> zsh"
    else
        warn "login shell not zsh; run: chsh -s $(command -v zsh)"
    fi
}

# ── stow ─────────────────────────────────────────────────────────────────
stow_phase() {
    phase "stow $ACTION -> $HOME"
    command -v stow >/dev/null || die "GNU stow is required — sudo apt install stow"

    local pkgs=()
    if [ ${#PACKAGES[@]} -gt 0 ]; then
        pkgs=("${PACKAGES[@]}")
    else
        mapfile -t pkgs < <(
            find . -maxdepth 1 -mindepth 1 -type d -not -name '.git' -printf '%f\n' | sort
        )
    fi
    printf '  %s\n' "${pkgs[@]}"

    # stow knows nothing about .gitignore, and __pycache__ regenerates itself.
    local stow_args=(--no-folding --ignore='__pycache__' --ignore='\.pyc$' --target="$HOME")

    [ "$ACTION" = "-D" ] || backup_conflicts "${stow_args[@]}" -- "${pkgs[@]}"

    stow --verbose=1 "${stow_args[@]}" "$ACTION" "${pkgs[@]}"
    ok "stow done"
}

# A stock $HOME owns some of these paths. Move them aside rather than
# --adopt, which would pull the stock file into the repo.
backup_conflicts() {
    local args=() pkgs=() seen=0 a
    for a in "$@"; do
        if [ "$a" = "--" ]; then seen=1; continue; fi
        if [ $seen -eq 1 ]; then pkgs+=("$a"); else args+=("$a"); fi
    done

    # stow exits non-zero precisely when it reports conflicts. 2.4.x phrases
    # them as "cannot stow X over existing target Y"; the rest is older wording.
    local conflicts
    conflicts=$(stow --simulate --verbose=1 "${args[@]}" -R "${pkgs[@]}" 2>&1 \
        | sed -n 's/.*over existing target \(.*\) since .*/\1/p;
                  s/.*existing target is neither a link nor a directory: //p;
                  s/.*existing target is not owned by stow: //p' | sort -u) || true
    [ -n "$conflicts" ] || return 0

    local dest="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)" rel
    while IFS= read -r rel; do
        [ -e "$HOME/$rel" ] || continue
        mkdir -p "$dest/$(dirname "$rel")"
        mv "$HOME/$rel" "$dest/$rel"
        warn "moved existing ~/$rel -> ${dest/#$HOME/~}/$rel"
    done <<< "$conflicts"
}

# ── post-stow ────────────────────────────────────────────────────────────
seed_phase() {
    phase "generated fragments"
    export PATH="$HOME/.local/bin:$PATH"
    # A missing accent fragment fails the config parse, not just the colour.
    # `seed` writes only what is absent.
    rice-accent seed    || warn "rice-accent seed failed"
    # dconf is binary and mimeapps.list is app-written; neither can be stowed.
    rice-gsettings      || warn "rice-gsettings failed"
    rice-mime           || warn "rice-mime failed"
    ok "fragments seeded"
}

# molten (lua/plugins/jupyter.lua) is a Python remote plugin: its host needs
# pynvim + jupyter_client, and jupytext.nvim shells out to jupytext. Own venv,
# because trixie's Python is externally managed (pip --user refuses). Runs
# before nvim_phase: molten's build, :UpdateRemotePlugins, needs this host.
jupyter_phase() {
    phase "nvim jupyter (molten host venv, jupytext)"
    local venv="$HOME/.local/share/nvim/jupyter-venv"
    if "$venv/bin/python" -c 'import pynvim, jupyter_client, ipykernel, nbformat' 2>/dev/null; then
        skip "venv ready"
    elif python3 -m venv --system-site-packages "$venv" >/dev/null 2>&1 &&
         "$venv/bin/pip" install -q --disable-pip-version-check pynvim jupyter_client ipykernel nbformat jupytext; then
        ok "venv at ${venv/#$HOME/\~}"
    else
        warn "venv setup failed (python3-venv missing?); notebooks in nvim will not run"
        return
    fi

    if command -v jupytext >/dev/null; then
        skip "jupytext on PATH"
    elif [ -x "$venv/bin/jupytext" ] || "$venv/bin/pip" install -q --disable-pip-version-check jupytext; then
        mkdir -p "$HOME/.local/bin"
        ln -sfn "$venv/bin/jupytext" "$HOME/.local/bin/jupytext"
        ok "jupytext -> venv"
    else
        warn "jupytext install failed; .ipynb files will not open in nvim"
    fi
}

nvim_phase() {
    phase "neovim plugins"
    local nvim="$HOME/.local/bin/nvim"
    [ -x "$nvim" ] || nvim=$(command -v nvim || true)
    [ -n "$nvim" ] || { warn "no nvim on PATH; skipping"; return; }

    export PATH="$HOME/.local/bin:$PATH"
    # install fetches at branch head; restore pins to lazy-lock.json, which
    # keeps telescope off 0.1.x — it calls master-only treesitter APIs.
    "$nvim" --headless "+Lazy! install" +qa 2>&1 | grep -viE '^\s*$' | tail -3 || true
    "$nvim" --headless "+Lazy! restore" +qa 2>&1 | grep -viE '^\s*$' | tail -3 || true
    ok "plugins at lazy-lock.json"

    # Parsers install async; a slow clone must not fail the install.
    timeout 300 "$nvim" --headless "+TSUpdateSync" +qa >/dev/null 2>&1 \
        && ok "treesitter parsers built" \
        || warn "treesitter parsers unfinished — nvim will finish them on first start"
}

# ── login session ────────────────────────────────────────────────────────
session_phase() {
    phase "greetd session"
    # No pid-1 systemd (container, chroot): write the config, enable nothing.
    local has_systemd=1
    systemctl is-system-running >/dev/null 2>&1 || [ -d /run/systemd/system ] || has_systemd=0

    # Test for tuigreet, not the vt: the stock config.toml already sets
    # vt 7, and runs agreety.
    local conf=/etc/greetd/config.toml
    if [ -f "$conf" ] && grep -q 'tuigreet' "$conf" 2>/dev/null; then
        skip "greetd already runs tuigreet"
    else
        sudo install -d -m 755 /etc/greetd
        if [ -f "$conf" ]; then sudo cp -n "$conf" "$conf.bak"; fi
        sudo tee "$conf" >/dev/null <<'TOML'
# tuigreet reads the session .desktop files, so "Hyprland (uwsm-managed)"
# appears in the picker. --remember-session pins it after the first login.

[terminal]
vt = 7

[default_session]
command = "tuigreet --time --remember --remember-session --asterisks --sessions /usr/share/wayland-sessions"
user = "_greetd"
TOML
        ok "wrote $conf"
    fi

    if [ $has_systemd -eq 0 ]; then
        warn "systemd not running here; enable greetd yourself: sudo systemctl enable greetd"
        return
    fi

    local unit
    # display-manager.service is an alias following whichever DM is enabled.
    for unit in greetd bluetooth power-profiles-daemon; do
        if systemctl is-enabled "$unit.service" >/dev/null 2>&1; then
            skip "$unit.service enabled"
        elif sudo systemctl enable "$unit.service" >/dev/null 2>&1; then
            ok "$unit.service enabled"
        else
            warn "could not enable $unit.service"
        fi
    done
}

# ── run ──────────────────────────────────────────────────────────────────
if [ $STOW_ONLY -eq 1 ]; then
    stow_phase
    [ "$ACTION" = "-D" ] || { seed_phase; }
    printf '\n%sdone%s\n' "$B" "$N"
    exit 0
fi

if [ $DO_SUDO -eq 1 ]; then
    backports_phase
    apt_phase
    brave_phase
    discord_phase
else
    warn "--no-sudo: skipping apt, brave, discord and the login session"
fi

neovim_phase
tree_sitter_phase
font_phase
fd_phase
zsh_phase
stow_phase
seed_phase
jupyter_phase
nvim_phase
if [ $DO_SUDO -eq 1 ] && [ $DO_SESSION -eq 1 ]; then session_phase; fi

cat <<EOF

${B}done${N}

  Log out and back in — the greeter lists "Hyprland (uwsm-managed)".
  Wallpapers are not shipped; put at least one image in ~/Pictures/wallpapers.
  Hardware firmware (firmware-iwlwifi, firmware-nvidia-graphics, …) is not
  installed here; it is hardware-specific and the Debian installer's job.
EOF
