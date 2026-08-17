# golang
if command -v go &>/dev/null; then
  export PATH=$PATH:${GOPATH:-$HOME/go}/bin
fi

# GCloud
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then
  . "$HOME/google-cloud-sdk/path.zsh.inc"
fi

# OCaml (nix には dune_3 だけ入れ、処理系は dune の package management に任せている)
if command -v dune &>/dev/null; then
  # ocaml / ocamlc などのコンパイラ本体は dune pkg が ~/.cache/dune/toolchains 以下に
  # ビルドするため PATH に載らない。最新の toolchain の bin を PATH に足す。
  _ocaml_toolchain=(${XDG_CACHE_HOME:-$HOME/.cache}/dune/toolchains/ocaml-compiler.*/target/bin(N/om))
  (( $#_ocaml_toolchain )) && export PATH=$PATH:$_ocaml_toolchain[1]
  unset _ocaml_toolchain

  # ocamlformat / ocamllsp / utop は dev-tool としてプロジェクトの _build 以下に入る。
  # dune 経由で呼ぶため、dune-project のあるディレクトリで実行すること。
  ocamlformat() { dune tools exec ocamlformat -- "$@" }
  ocamllsp() { dune tools exec ocamllsp -- "$@" }
  utop() { dune utop "$@" }
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

# load completion
autoload -U compinit
compinit -ui

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
  eval "$(mise activate zsh --shims)"
fi

# tinygo completion (via tinygo-autocmpl; needs mise shims on PATH)
if command -v tinygo-autocmpl &>/dev/null; then
  eval "$(tinygo-autocmpl --completion-script-zsh)"
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

# fastfetch
if command -v fastfetch &>/dev/null; then
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
