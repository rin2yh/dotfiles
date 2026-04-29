if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export PATH="$HOME/.local/bin:$PATH"

for f in "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh" \
         "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"; do
  [ -r "$f" ] && . "$f" && break
done
