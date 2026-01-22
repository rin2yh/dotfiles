# alias
## PathShow
alias path="echo $PATH | tr ':' '\n'"

## Git
alias g="git"

## Docker
alias dc="docker-compose"


## Mise
alias mtr="mise t r"

PROMPT='%F{white}%~%f %# '

# load
autoload -U compinit
compinit -ui
