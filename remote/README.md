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
4. **確認**: `which rg lazygit lua-language-server` ／ nvim で `:LspHealth`

入るツールと mise spec の一覧は `mise.toml` のコメント参照。`nixd` は除外。

## bootstrap が自動でやること

- LSP/CLI ツール導入（`mise.toml` 記載分）。
- コンパイラ等は**入れない**。treesitter parser のビルドには C コンパイラが要るが、
  リモートに無ければ下記の方針でフォールバックする。
- 導入後に**各バイナリを検証**。`[要確認]` spec が解決できなければ、どれが失敗したかと
  直し方（`mise registry | grep <name>`）を名指しで表示して停止するので、手探りにならない。

## treesitter (コンパイラを入れない場合)

nvim-treesitter(main) は parser をリモートでコンパイルするため C コンパイラが要る。
リモートに入れたくない/入れられない場合の扱い:

- **既に cc/gcc/clang があるリモート**なら、そのまま普通に parser がビルドされる（何もしない）。
- **無い場合**は parser コンパイルは行われず、以下にフォールバック:
  - lua/vim/markdown 等 **Neovim 同梱 parser** はコンパイル不要でそのまま treesitter が効く。
  - それ以外(bash/yaml/ts/tsx/html/terraform/dockerfile/nix 等)は **組み込み regex syntax**
    (`syntax enable`) で色付け。折り畳み(treesitter foldexpr)は当該言語で効かなくなる。
- フル treesitter を維持したいなら、**x86_64-linux 向けにビルド済みの `parser/*.so` を用意**して
  リモートの runtimepath に置く手もある（nix の grammar を linux 向けにビルドして scp 等）。設定は要相談。

SSH 越しで使うなら手元 `home/nvim` 側で `im-select`(macOS専用) の OS ガードと OSC52 を入れると快適。
