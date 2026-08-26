# Shared helpers for the rice-*-menu fallbacks. Sourced, not executed.
# Anchored under the bar: 6px margin + 34px bar = 46px y-margin.

RICE_ANCHOR="${RICE_ANCHOR:-top-right}"
RICE_X_MARGIN="${RICE_X_MARGIN:-10}"
RICE_Y_MARGIN="${RICE_Y_MARGIN:-46}"

# Call from the main shell, not a pipeline. fuzzel is single-instance, so a
# second invocation would fail silently -- close the open one instead, which
# makes a second click a toggle.
rice_toggle_guard() {
    if pgrep -x fuzzel >/dev/null 2>&1; then
        pkill -x fuzzel 2>/dev/null || true
        exit 0
    fi
}

# rice_menu <prompt> [lines] [width]   -- entries on stdin, choice on stdout.
# Exits non-zero when dismissed, which every caller treats as "do nothing".
rice_menu() {
    fuzzel --dmenu \
        --anchor="$RICE_ANCHOR" \
        --x-margin="$RICE_X_MARGIN" \
        --y-margin="$RICE_Y_MARGIN" \
        --prompt="$1  " \
        --lines="${2:-10}" \
        --width="${3:-38}"
}

# rice_password <prompt>  -- masked single-line input, no stdin needed.
rice_password() {
    fuzzel --dmenu --password \
        --anchor="$RICE_ANCHOR" \
        --x-margin="$RICE_X_MARGIN" \
        --y-margin="$RICE_Y_MARGIN" \
        --prompt-only="$1  " \
        --width="${2:-38}"
}

rice_notify() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send -a "${1}" "${2}" "${3:-}"
}

# PipeWire device names share a long controller prefix; strip it.
rice_trim_common_prefix() {
    local -a lines=()
    local line
    while IFS= read -r line; do lines+=("$line"); done
    [ ${#lines[@]} -eq 0 ] && return 0

    if [ ${#lines[@]} -eq 1 ]; then
        printf '%s\n' "${lines[0]}"
        return 0
    fi

    local prefix="${lines[0]}" candidate
    for line in "${lines[@]:1}"; do
        while [ -n "$prefix" ] && [ "${line#"$prefix"}" = "$line" ]; do
            prefix="${prefix% *}"
            [ "$prefix" = "${prefix% *}" ] && break
        done
    done

    for line in "${lines[@]}"; do
        candidate="${line#"$prefix"}"
        printf '%s\n' "${candidate# }"
    done
}
