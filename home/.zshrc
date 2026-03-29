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

# PROMPT
git_prompt() {
  local s branch flags=""
  s=$(git status --porcelain=2 --branch 2>/dev/null) || return

  # branch
  branch=$(printf "%s\n" "$s" | sed -n 's/^# branch.head //p')

  # staged / unstaged / untracked
  [[ "$s" == *$'\n1 '* || "$s" == *$'\n2 '* ]] && flags+="!"
  [[ "$s" == *$'\nu '* ]] && flags+="?"
  [[ "$s" == *$'\n1 '* && "$s" == *"M."* ]] && flags+="+"  # staged（簡易判定）

  # ahead / behind（数値で判定）
  local ahead=0 behind=0
  if printf "%s\n" "$s" | grep -q '^# branch.ab'; then
    read ahead behind <<<$(printf "%s\n" "$s" \
      | sed -n 's/^# branch.ab +\([0-9]*\) -\([0-9]*\)$/\1 \2/p')

    ((ahead > 0)) && flags+="⇡"
    ((behind > 0)) && flags+="⇣"
  fi

  print -P "%K{#1f3b73}%F{white}  ${branch}${flags:+ ${flags}} %f%k"
}
setopt prompt_subst
PROMPT='%F{white}%~%f $(git_prompt) %# '

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
fi

# Path重複解除
typeset -U PATH
