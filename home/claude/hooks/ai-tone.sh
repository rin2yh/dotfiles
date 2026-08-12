#!/usr/bin/env bash
# ai-tone.mjs の起動だけを担う。処理は Node 側に置いてある。
# フックは非対話シェルで動くので mise の shim が PATH に無いことがあり、
# node を見つける手順だけをここで面倒みる。見つからなければ黙って通す。
set -uo pipefail

for candidate in \
  "$(command -v node 2>/dev/null || true)" \
  "$HOME/.local/share/mise/shims/node" \
  "/opt/homebrew/bin/node" \
  "/usr/local/bin/node"; do
  if [ -n "$candidate" ] && [ -x "$candidate" ]; then
    exec "$candidate" "$(dirname "$0")/ai-tone.mjs"
  fi
done

exit 0
