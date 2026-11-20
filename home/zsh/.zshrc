# golang
if command -v go &>/dev/null; then
  export PATH=$PATH:${GOPATH:-$HOME/go}/bin
fi

# GCloud
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then
  . "$HOME/google-cloud-sdk/path.zsh.inc"
fi

# alias
alias path='echo $PATH | tr ":" "\n"'
alias g="git"
alias dc="docker-compose"
alias mtr="mise t r"
alias m="mise"
alias n="nvim ."
alias c="cargo"
alias lg="lazygit"
alias ld="lazydocker"
alias kc="kubectl"

# load completion
autoload -U compinit
# skip the security check and dump regeneration if the dump was updated within 24 hours
_zcompdump=(${ZDOTDIR:-$HOME}/.zcompdump(N.mh-24))
if (( $#_zcompdump )); then
  compinit -C
else
  compinit -ui
  touch "${ZDOTDIR:-$HOME}/.zcompdump"
fi
unset _zcompdump

# Docker completion
if type docker &>/dev/null; then
  zstyle ':completion:*:*:docker:*' option-stacking yes
  zstyle ':completion:*:*:docker-*:*' option-stacking yes
fi

# GCloud completion (deferred to first precmd to keep startup fast)
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then
  autoload -Uz add-zsh-hook
  _gcloud_completion_load() {
    . "$HOME/google-cloud-sdk/completion.zsh.inc"
    add-zsh-hook -d precmd _gcloud_completion_load
    unfunction _gcloud_completion_load
  }
  add-zsh-hook precmd _gcloud_completion_load
fi

# OrbStack
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# mise
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# starship
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# zoxide
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"

  zi() {
    local prefix="$HOME/workspace"
    local dir
    dir=$(zoxide query -l | grep "^$prefix" | head -n 50 | sed "s|^$prefix/||" | fzf --reverse)
    [ -n "$dir" ] && z "$dir"
  }
fi

# fastfetch (top-level shells only)
if [[ $SHLVL -eq 1 ]] && command -v fastfetch &>/dev/null; then
  case $((RANDOM % 3)) in
    0) fastfetch ;;
    1) fastfetch --logo apple ;;
    2) fastfetch --logo nixos_small ;;
  esac
fi

# zsh-autosuggestions
for f in "/etc/profiles/per-user/$USER/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
         "$HOME/.nix-profile/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"; do
  [ -r "$f" ] && . "$f" && break
done

# Path重複解除
typeset -U PATH
