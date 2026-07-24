# remote/ — SSH 先で home/nvim を使う (remote-nvim)

remote-nvim は **nvim 本体をリモートで動かす**ツール（VSCode Remote SSH の nvim 版）。
nvim も LSP もリモートで動くので LSP サーバ等はリモートに必要 → それを `mise` で入れる。
（このディレクトリは `home.nix` の symlink 対象外＝ローカルには配置されない）

## クイックスタート

1. **手元の nvim に remote-nvim を追加**（`vim.pack.add` + `setup`）。リモートに入れる
   Neovim は**手元と同じ 0.12 系**にする（`vim.pack` は 0.12 stable。**nightly 不要**）。
   正確なオプションキーは remote-nvim 本家 doc で確認。
2. **`:RemoteStart` で接続** → nvim 本体・設定・プラグインは自動で入る。
3. **リモートに LSP/ツールを入れる**:
   ```sh
   scp remote/mise.toml remote/bootstrap.sh <host>:/tmp/
   ssh <host> 'cd /tmp && bash bootstrap.sh'
   ```
4. **確認**: `which gopls rg lazygit` ／ nvim で `:LspHealth`

入るツールと mise spec の一覧は `mise.toml` のコメント参照。`nixd` は除外。

## ハマりどころ

- **C コンパイラ**が無いと treesitter parser ビルドが落ちる → `build-essential` 等を入れる。
- **Rust** は rust-analyzer に加え `rustup`(cargo/rustc/rust-src) が別途必要。
- `mise.toml` の `[要確認]` spec が入らなければ `mise registry | grep <tool>` で差し替え。
- SSH 越しで使うなら手元 `home/nvim` 側で `im-select`(macOS専用) の OS ガードと
  OSC52 クリップボードを入れると快適（必要になったら対応）。
