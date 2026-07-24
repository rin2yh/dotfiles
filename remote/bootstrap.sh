#!/usr/bin/env bash
#
# remote-nvim.nvim を使う Linux リモートホストで一度だけ実行する bootstrap。
# remote-nvim が埋めてくれない「LSP サーバ + CLI ツール」を mise で
# ユーザローカル(~/.local/share/mise 配下)に導入する。root 不要・隔離。
#
# 使い方(リモート側で):
#   ./bootstrap.sh
# 手元から流し込むなら:
#   ssh <host> 'bash -s' < remote/bootstrap.sh
#   （その場合は同ディレクトリの mise.toml も転送しておくこと）
#
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
manifest="${here}/mise.toml"

if [[ ! -f "${manifest}" ]]; then
  echo "error: ${manifest} が見つかりません。mise.toml と同じ場所で実行してください。" >&2
  exit 1
fi

# 1) mise 本体（無ければ導入）
if ! command -v mise >/dev/null 2>&1; then
  echo "==> mise が無いので導入します"
  curl -fsSL https://mise.run | sh
fi
export PATH="${HOME}/.local/bin:${PATH}"

if ! command -v mise >/dev/null 2>&1; then
  echo "error: mise の導入に失敗しました。https://mise.jdx.dev/ を参照してください。" >&2
  exit 1
fi

# 2) マニフェストをグローバル設定として有効化（全ディレクトリで PATH に載るように）
mkdir -p "${HOME}/.config/mise/conf.d"
cp "${manifest}" "${HOME}/.config/mise/conf.d/remote-nvim.toml"

# 3) ツール導入
echo "==> mise install（LSP サーバ / CLI ツール一式）"
mise install
mise reshim || true

# 4) 非対話シェル(ssh 実行)でも nvim が shims を見つけられるよう PATH を通す
shims='export PATH="$HOME/.local/share/mise/shims:$PATH"'
for rc in "${HOME}/.profile" "${HOME}/.bashrc"; do
  if [[ -f "${rc}" ]] && ! grep -qF "mise/shims" "${rc}"; then
    printf '\n# remote-nvim: mise shims\n%s\n' "${shims}" >> "${rc}"
    echo "==> ${rc} に mise shims への PATH を追記しました"
  fi
done

cat <<'EOF'

==> 完了。確認:
    mise ls                 # 入ったツール一覧
    which gopls rg lazygit  # PATH 解決の確認

注意:
  - nvim-treesitter(main) は parser をリモートでコンパイルするため C コンパイラ
    (gcc/clang) が別途必要です。無ければディストリのパッケージで入れてください
    (例: apt install build-essential / dnf groupinstall "Development Tools")。
  - Rust を触るなら rust-analyzer に加えて rustup(cargo/rustc/rust-src) を
    別途入れてください。mise の rust-analyzer 単体では解析が限定的です。
  - mise.toml に [要確認] と付けた spec は、入らなければ
    `mise registry | grep <tool>` で正しい識別子に差し替えてください。
EOF
