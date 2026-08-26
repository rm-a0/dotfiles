#!/usr/bin/env bash
# install.sh — symlink every package into $HOME with GNU stow.
#
#   ./install.sh            stow everything
#   ./install.sh hypr kitty stow only those packages
#   ./install.sh -D         unstow everything (restore a bare $HOME)

set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

command -v stow >/dev/null 2>&1 || {
    echo "install.sh: GNU stow is required — sudo apt install stow" >&2
    exit 1
}

ACTION="-R"                        # restow: safe to re-run
if [ "${1:-}" = "-D" ]; then ACTION="-D"; shift; fi

PACKAGES=("$@")
if [ ${#PACKAGES[@]} -eq 0 ]; then
    mapfile -t PACKAGES < <(
        find . -maxdepth 1 -mindepth 1 -type d -not -name '.git' -printf '%f\n' | sort
    )
fi

echo "stow $ACTION -> $HOME"
printf '  %s\n' "${PACKAGES[@]}"
# stow knows nothing about .gitignore, and __pycache__ regenerates itself.
stow --verbose=1 --no-folding --ignore='__pycache__' --ignore='\.pyc$' \
     --target="$HOME" "$ACTION" "${PACKAGES[@]}"

# A missing accent fragment is a config that fails to parse, not a missing
# colour. `seed` writes only what is absent.
if [ "$ACTION" != "-D" ]; then
    PATH="$HOME/.local/bin:$PATH" rice-accent seed || true
fi
# dconf is binary and mimeapps.list is app-written; neither can be stowed.
if [ "$ACTION" != "-D" ]; then
    PATH="$HOME/.local/bin:$PATH" rice-gsettings || true
    PATH="$HOME/.local/bin:$PATH" rice-mime     || true
fi
echo "done"
