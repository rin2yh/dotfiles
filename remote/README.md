# remote-nvim (VSCode Remote SSH 相当) セットアップ

SSH 先の Linux ホストで、この Neovim 設定を **VSCode Remote SSH と同じ体験**で
使うための手順。`amitds1997/remote-nvim.nvim` を前提にする。

> このディレクトリはリモート専用のプロビジョニング資材。`home.nix` が
> `~/.config/nvim` に symlink する `home/nvim/` の**外**（リポジトリ直下）に
> 意図的に置いてある。ローカル(Mac)の nvim 設定ディレクトリには配置されない。

## 仕組み（ここだけ先に理解する）

remote-nvim は「Neovim 本体をリモートで動かし、手元は画面(TUI)に徹する」ツール。
VSCode Remote SSH の Neovim 版で、対応はほぼ 1:1：

| | VSCode Remote SSH | remote-nvim |
|---|---|---|
| Server 本体 | `~/.vscode-server` に自動 | `~/.remote-nvim` に自動 |
| 拡張/プラグイン | リモートに自動 DL | `vim.pack` がリモートに自動 DL |
| **LSP サーバ** | 拡張として自動で入る | **自前で用意（← ここだけ差）** |
| 手元 | UI だけ | TUI だけ |

**nvim もプラグインも LSP もリモート側で動く。** だから LSP サーバ等はリモートに
必要になる。これは remote-nvim の癖ではなく、VSCode Remote SSH でも同じこと
（`~/.vscode-server` 配下に隠れて入っているだけ）。

## この設定固有の相性

- ✅ **設定が nix 非依存で移植可能。** `home/nvim` は純 Lua + `vim.pack` だけで、
  home-manager の symlink や nix ストアパスを実行時に踏まない。SCP コピーで素直に動く。
- ✅ **`vim.pack` は Neovim 0.12 で stable 入り**（0.12.0=2026-03, 0.12.1=2026-04）。
  **nightly は不要。** リモートには **手元と同じ 0.12 系**を入れる。experimental 表記の
  API 差異を避けるため、手元とリモートで同じパッチバージョンに揃えるのが安全。
- ✅ **個人リモート（外向き通信あり）なら `vim.pack` のプラグイン取得も treesitter
  parser 取得もそのまま通る。**
- ⚠️ **LSP サーバ / rg / lazygit / tree-sitter CLI はリモートに無い。**
  → 本ディレクトリの `mise.toml` + `bootstrap.sh` で埋める（下記）。
- ⚠️ nix はリモート(Linux)に流用しづらい（`home.nix` が macOS 特化）。mise は
  クロスプラットフォームなので **mac 用の資産がそのまま Linux でも効く**。

## セットアップ手順

### 1. 手元(Mac)に remote-nvim を入れる

`home/nvim` のプラグイン管理は `vim.pack` なので、他プラグインと同様に追加する：

```lua
vim.pack.add({ 'https://github.com/amitds1997/remote-nvim.nvim' })
-- 依存: plenary.nvim / nui.nvim / telescope.nvim も必要（remote-nvim のドキュメント参照）
require('remote-nvim').setup({
  -- リモートに入れる Neovim バージョンは手元と同じ 0.12 系に固定する。
  -- ※ 正確なオプションキーは remote-nvim のドキュメントで確認して調整すること
  --   （バージョン指定は stable / タグ(例 v0.12.1) を選べる）。
})
```

> オプションキー名（`copy_dirs` / Neovim バージョン指定など）は remote-nvim 側の
> 更新で変わりうるので、必ず本家 README/ヘルプで確認する。

### 2. リモートに接続してセッションを張る

remote-nvim のコマンド（`:RemoteStart` 等）でホストを指定して接続。初回に
Neovim 本体のインストールと `home/nvim` のコピー、`vim.pack` によるプラグイン
取得がリモート側で走る。

### 3. リモートで bootstrap を一度だけ実行（LSP/ツール導入）

```sh
# 手元から流し込む例（mise.toml も一緒に転送）
scp remote/mise.toml <host>:/tmp/mise.toml
scp remote/bootstrap.sh <host>:/tmp/bootstrap.sh
ssh <host> 'cd /tmp && bash bootstrap.sh'
```

`bootstrap.sh` がやること: mise 導入 → `mise.toml` を `~/.config/mise/conf.d/` に
配置 → `mise install` → shims を PATH に通す。全て `~/.local/share/mise` 配下に
隔離され、消せば消える。

導入されるツールは `home/nvim/lua/lsp/*.lua` の `M.cmd` と対応：

| バイナリ | mise spec | 由来 LSP |
|---|---|---|
| `gopls` | `go:golang.org/x/tools/gopls` | gopls |
| `typescript-language-server` | `npm:typescript-language-server` (+`npm:typescript`) | ts_ls |
| `vscode-css-language-server` 他 | `npm:vscode-langservers-extracted` | css_ls |
| `emmet-language-server` | `npm:@olrtg/emmet-language-server` | emmet_ls |
| `lua-language-server` | `aqua:LuaLS/lua-language-server` | lua_ls |
| `terraform-ls` | `aqua:hashicorp/terraform-ls` | terraform_ls |
| `rust-analyzer` | `aqua:rust-lang/rust-analyzer` | rust_ls |

`nixd` はリモートで nix を編集しない前提で意図的に除外。

### 4. 確認

```sh
mise ls
which gopls rg lazygit
```

nvim を開いて `:checkhealth vim.lsp`（設定の `:LspHealth`）で attach を確認。

## 補足（任意・低優先）

SSH 越しで動かすと効いてくる、LSP とは別の調整。必要になったら入れる：

- **`edit.lua` の `im-select`（macOS 専用）を OS ガード。** Linux リモートでは
  `im-select` が無く、InsertLeave のたびに無駄なプロセス起動になる：

  ```lua
  vim.api.nvim_create_autocmd("InsertLeave", {
    pattern = "*",
    callback = function()
      if vim.fn.has("mac") == 1 and vim.fn.executable("im-select") == 1 then
        vim.fn.system("im-select com.apple.keylayout.ABC")
      end
    end,
  })
  ```

- **OSC52 クリップボード。** SSH 越しの yank を手元クリップボードに載せる：

  ```lua
  vim.g.clipboard = {
    name = 'OSC52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {
      ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
      ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
    },
  }
  ```

## 既知の前提・ハマりどころ

- **C コンパイラ**が無いと nvim-treesitter(main) の parser ビルドが失敗する。
  リモートに `build-essential` 等を入れておく。
- **Rust** を触るなら rust-analyzer に加えて `rustup`(cargo/rustc/rust-src) が必要。
- `mise.toml` の `[要確認]` 印の spec は、入らなければ
  `mise registry | grep <tool>` で正しい識別子に差し替える。
