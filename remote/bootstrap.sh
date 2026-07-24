#!/usr/bin/env bash
# リモートで一度実行。mise で LSP/CLI を導入し、前提(Cコンパイラ)も自動解決する。README.md 参照。
#   ssh <host> 'bash -s' < remote/bootstrap.sh   # mise.toml も転送しておくこと
#   WITH_RUST=1 を付けると rustup(+rust-src) も導入し rust-analyzer を完全化する。
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
manifest="${here}/mise.toml"
[[ -f "${manifest}" ]] || { echo "error: ${manifest} が無い" >&2; exit 1; }

# --- mise ---
command -v mise >/dev/null 2>&1 || curl -fsSL https://mise.run | sh
export PATH="${HOME}/.local/bin:${HOME}/.local/share/mise/shims:${PATH}"
command -v mise >/dev/null 2>&1 || { echo "error: mise 導入失敗" >&2; exit 1; }

# --- 前提: C コンパイラ (nvim-treesitter の parser ビルド用。失敗しても非致命) ---
install_cc() {
  local sudo=""; [[ ${EUID:-$(id -u)} -ne 0 ]] && command -v sudo >/dev/null 2>&1 && sudo="sudo"
  if   command -v apt-get >/dev/null 2>&1; then $sudo apt-get update && $sudo apt-get install -y build-essential
  elif command -v dnf     >/dev/null 2>&1; then $sudo dnf -y install gcc
  elif command -v yum     >/dev/null 2>&1; then $sudo yum -y install gcc
  elif command -v pacman  >/dev/null 2>&1; then $sudo pacman -Sy --noconfirm base-devel
  elif command -v apk     >/dev/null 2>&1; then $sudo apk add build-base
  elif command -v zypper  >/dev/null 2>&1; then $sudo zypper -n install gcc
  else return 2; fi
}
if ! command -v cc >/dev/null 2>&1 && ! command -v gcc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1; then
  echo "==> C コンパイラが無いので導入を試みます"
  install_cc || echo "!! C コンパイラを自動導入できず。gcc/clang を手動で（treesitter parser ビルドに影響）" >&2
fi

# --- LSP/CLI ツール ---
mkdir -p "${HOME}/.config/mise/conf.d"
cp "${manifest}" "${HOME}/.config/mise/conf.d/remote-nvim.toml"
mise install || true
mise reshim || true

# --- 前提: Rust (WITH_RUST=1 のときだけ。user-local, root 不要) ---
if [[ "${WITH_RUST:-}" == "1" ]] && ! command -v rustup >/dev/null 2>&1; then
  echo "==> rustup + rust-src を導入"
  curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal
  "${HOME}/.cargo/bin/rustup" component add rust-src || true
fi

# --- 非対話シェル(ssh 実行)でも nvim が shims を見つけられるよう PATH を通す ---
shims='export PATH="$HOME/.local/share/mise/shims:$PATH"'
for rc in "${HOME}/.profile" "${HOME}/.bashrc"; do
  [[ -f "${rc}" ]] && ! grep -qF "mise/shims" "${rc}" \
    && printf '\n# remote-nvim: mise shims\n%s\n' "${shims}" >> "${rc}" || true
done

# --- 検証: 期待バイナリが PATH に載ったか。未導入(=spec 要修正)を名指しで報告 ---
missing=()
for bin in gopls typescript-language-server vscode-css-language-server \
           emmet-language-server lua-language-server terraform-ls rust-analyzer \
           rg lazygit lazydocker tree-sitter; do
  command -v "${bin}" >/dev/null 2>&1 || missing+=("${bin}")
done
if ((${#missing[@]})); then
  echo "!! 未導入: ${missing[*]}"
  echo "   → 各 tool を \`mise registry | grep <name>\` で確認し mise.toml の spec を直して再実行"
  exit 1
fi
echo "==> 完了。全ツール OK"
