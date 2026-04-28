# golang
if command -v go &>/dev/null; then
  export PATH=$PATH:$(go env GOPATH)/bin
fi

# GCloud
if [ -f '/Users/yuuki/google-cloud-sdk/path.zsh.inc' ]; then
  . '/Users/yuuki/google-cloud-sdk/path.zsh.inc'
fi

# alias
## PathShow
alias path="echo $PATH | tr ':' '\n'"

## Git
alias g="git"

## Docker
alias dc="docker-compose"

## Mise
alias mtr="mise t r"
alias m="mise"

## nvim
alias n="nvim ."

## Rust Cargo
alias c="cargo"

## lazy
alias lg="lazygit"
alias ld="lazydocker"

# Completion path
fpath=(~/.zsh/completion $fpath)

# load completion
autoload -U compinit
compinit -ui

# brew depends
if type brew &>/dev/null; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  # auto-suggest
  source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Docker completion
if type docker &>/dev/null; then
  zstyle ':completion:*:*:docker:*' option-stacking yes
  zstyle ':completion:*:*:docker-*:*' option-stacking yes
fi

# GCloud completion
if [ -f '/Users/yuuki/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/yuuki/google-cloud-sdk/completion.zsh.inc'; fi

# OrbStack
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# mise
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh --shims)"
  if (( RANDOM % 2 )); then
    fastfetch
  else
    fastfetch --logo auto
  fi
  eval "$(starship init zsh)"
  eval "$(zoxide init zsh)"

  zi() {
    local prefix="$HOME/workspace"
    local dir
    dir=$(zoxide query -l | grep "^$prefix" | head -n 50 | sed "s|^$prefix/||" | fzf --reverse)
    [ -n "$dir" ] && z "$dir"
  }
fi

# Path重複解除
typeset -U PATH
