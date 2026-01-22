# Path
## brew, arch switching
export PATH=$PATH:/opt/homebrew/bin
# eval "$(nodenv init -)" などはどちらかインストールした方に書く
# brew depends
if type brew &>/dev/null; then
  # auto-suggest
  source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

  # git
  export PATH="/usr/local/bin/git:$PATH"
 
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


## golang Air
export PATH=$PATH:$(go env GOPATH)/bin

# Docker
if type docker &>/dev/null; then
  zstyle ':completion:*:*:docker:*' option-stacking yes
  zstyle ':completion:*:*:docker-*:*' option-stacking yes
fi

# GCloud
# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/yuuki/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/yuuki/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/yuuki/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/yuuki/google-cloud-sdk/completion.zsh.inc'; fi


# Completion
fpath=(~/.zsh/completion $fpath)

# Added by OrbStack: command-line tools and integration
# Comment this line if you don't want it to be added again.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :


eval "$(mise activate zsh)"

# Path重複解除
typeset -U PATH


