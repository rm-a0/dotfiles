# ─────────────────────────────────────────────────────────────────────────
#  zsh
#  p10k instant prompt must stay at the top: any stdout above it disables it.
# ─────────────────────────────────────────────────────────────────────────
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── oh-my-zsh ────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

zstyle ':omz:update' mode reminder
zstyle ':omz:update' frequency 14

plugins=(
  git
  sudo              # press ESC twice to prepend sudo
  command-not-found
  colored-man-pages
)

source "$ZSH/oh-my-zsh.sh"

# ── History ──────────────────────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
setopt SHARE_HISTORY INC_APPEND_HISTORY

# ── Environment ──────────────────────────────────────────────────────────
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export MANPAGER="less -R"

# ~/.local/bin holds the rice-* helper scripts.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# uv / uvx shims
[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"

# ── Aliases ──────────────────────────────────────────────────────────────
alias fetch='rice-fetch'
alias ll='ls -lh --group-directories-first'
alias la='ls -lAh --group-directories-first'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias vim='nvim'

# Rice helpers
alias wall='rice-wallpaper'
alias shot='rice-screenshot'

# Reload the whole desktop after editing dotfiles.
alias rice-reload='hyprctl reload && systemctl --user restart waybar mako && echo "rice reloaded"'

# ── Powerlevel10k ────────────────────────────────────────────────────────
# Run `p10k configure` to regenerate.
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
