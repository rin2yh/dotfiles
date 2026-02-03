# Path
## brew
export PATH=$PATH:/opt/homebrew/bin

## golang
export PATH=$PATH:$(go env GOPATH)/bin

# GCloud
if [ -f '/Users/yuuki/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/yuuki/google-cloud-sdk/path.zsh.inc'; fi

# Completion path
fpath=(~/.zsh/completion $fpath)

# mise
eval "$(mise activate zsh)"

# Path重複解除
typeset -U PATH
