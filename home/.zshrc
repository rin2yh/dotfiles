# golang
if command -v go &> /dev/null; then
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
alias n="nvim"

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
  # auto-suggest
  source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

  # peco
  function peco-src () {
    local selected_dir=$(ghq list -p | peco --query "$LBUFFER")
    if [ -n "$selected_dir" ]; then
      BUFFER="cd ${selected_dir}"
      zle accept-line
    fi
    zle clear-screen
  }
  zle -N peco-src
  bindkey '^]' peco-src
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
if command -v mise &> /dev/null; then
    eval "$(mise activate zsh --shims)"
    fastfetch
    eval "$(starship init zsh)"
fi

# Path重複解除
typeset -U PATH
