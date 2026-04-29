# Path
## brew
export PATH="/opt/homebrew/bin:$PATH"

## local bin (mise 等)
export PATH="$HOME/.local/bin:$PATH"

## nix home-manager
. "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
