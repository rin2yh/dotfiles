#!/usr/bin/env bash
# リモートで一度実行し、mise で LSP サーバ/CLI を導入する。詳細は README.md。
#   ssh <host> 'bash -s' < remote/bootstrap.sh   # mise.toml も転送しておくこと
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
manifest="${here}/mise.toml"
[[ -f "${manifest}" ]] || { echo "error: ${manifest} が無い" >&2; exit 1; }

if ! command -v mise >/dev/null 2>&1; then
  curl -fsSL https://mise.run | sh
fi
export PATH="${HOME}/.local/bin:${PATH}"
command -v mise >/dev/null 2>&1 || { echo "error: mise 導入失敗" >&2; exit 1; }

mkdir -p "${HOME}/.config/mise/conf.d"
cp "${manifest}" "${HOME}/.config/mise/conf.d/remote-nvim.toml"

mise install
mise reshim || true

# 非対話シェル(ssh 実行)でも nvim が shims を見つけられるよう PATH を通す
shims='export PATH="$HOME/.local/share/mise/shims:$PATH"'
for rc in "${HOME}/.profile" "${HOME}/.bashrc"; do
  if [[ -f "${rc}" ]] && ! grep -qF "mise/shims" "${rc}"; then
    printf '\n# remote-nvim: mise shims\n%s\n' "${shims}" >> "${rc}"
  fi
done

echo "==> 完了。確認: which gopls rg lazygit"
