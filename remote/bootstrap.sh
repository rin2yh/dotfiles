#!/usr/bin/env bash
# リモートで一度実行。mise で LSP/CLI を導入する（コンパイラ等は入れない）。README.md 参照。
#   ssh <host> 'bash -s' < remote/bootstrap.sh   # mise.toml も転送しておくこと
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
manifest="${here}/mise.toml"
[[ -f "${manifest}" ]] || { echo "error: ${manifest} が無い" >&2; exit 1; }

# --- mise ---
command -v mise >/dev/null 2>&1 || curl -fsSL https://mise.run | sh
export PATH="${HOME}/.local/bin:${HOME}/.local/share/mise/shims:${PATH}"
command -v mise >/dev/null 2>&1 || { echo "error: mise 導入失敗" >&2; exit 1; }

# treesitter parser のビルドには C コンパイラが要るが、ここでは何も入れない方針。
# リモートに既に cc/gcc/clang があればそれで parser がビルドされる。無い場合は
# Neovim 同梱 parser + 組み込み regex syntax にフォールバックする（README 参照）。

# --- LSP/CLI ツール ---
mkdir -p "${HOME}/.config/mise/conf.d"
cp "${manifest}" "${HOME}/.config/mise/conf.d/remote-nvim.toml"
mise install || true
mise reshim || true

# --- 非対話シェル(ssh 実行)でも nvim が mise shims を見つけられるよう PATH を通す ---
paths='export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"'
for rc in "${HOME}/.profile" "${HOME}/.bashrc"; do
  [[ -f "${rc}" ]] && ! grep -qF "remote-nvim: PATH" "${rc}" \
    && printf '\n# remote-nvim: PATH\n%s\n' "${paths}" >> "${rc}" || true
done

# --- 検証: 期待バイナリが PATH に載ったか。未導入(=spec 要修正)を名指しで報告 ---
missing=()
for bin in typescript-language-server vscode-css-language-server \
           emmet-language-server lua-language-server terraform-ls \
           rg lazygit lazydocker tree-sitter; do
  command -v "${bin}" >/dev/null 2>&1 || missing+=("${bin}")
done
if ((${#missing[@]})); then
  echo "!! 未導入: ${missing[*]}"
  echo "   → 各 tool を \`mise registry | grep <name>\` で確認し mise.toml の spec を直して再実行"
  exit 1
fi
echo "==> 完了。全ツール OK"
