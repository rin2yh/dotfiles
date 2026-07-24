#!/usr/bin/env bash
# リモートで一度実行。mise で LSP/CLI を導入し、前提(Cコンパイラ)も自動解決する。README.md 参照。
#   ssh <host> 'bash -s' < remote/bootstrap.sh   # mise.toml も転送しておくこと
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
manifest="${here}/mise.toml"
[[ -f "${manifest}" ]] || { echo "error: ${manifest} が無い" >&2; exit 1; }

# --- mise ---
command -v mise >/dev/null 2>&1 || curl -fsSL https://mise.run | sh
export PATH="${HOME}/.local/bin:${HOME}/.local/share/mise/shims:${PATH}"
command -v mise >/dev/null 2>&1 || { echo "error: mise 導入失敗" >&2; exit 1; }

# --- 前提: C コンパイラ (treesitter parser ビルド用) ---
# 共有ホスト/root 無しでも完結するよう、system に無ければ zig を user-local に入れて
# ~/.local/bin/cc (= zig cc) を用意する（sudo 不要・システムを汚さない）。
if ! command -v cc >/dev/null 2>&1 && ! command -v gcc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1; then
  echo "==> C コンパイラが無いので zig を user-local に入れて cc として使う"
  if mise use -g zig@latest && mise reshim; then
    mkdir -p "${HOME}/.local/bin"
    printf '#!/bin/sh\nexec zig cc "$@"\n' > "${HOME}/.local/bin/cc"
    chmod +x "${HOME}/.local/bin/cc"
  else
    echo "!! zig 導入に失敗。gcc/clang を用意してください（treesitter parser ビルドに影響）" >&2
  fi
fi

# --- LSP/CLI ツール ---
mkdir -p "${HOME}/.config/mise/conf.d"
cp "${manifest}" "${HOME}/.config/mise/conf.d/remote-nvim.toml"
mise install || true
mise reshim || true

# --- 非対話シェル(ssh 実行)でも nvim が shims / cc を見つけられるよう PATH を通す ---
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
