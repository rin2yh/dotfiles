# My Dotfiles

## Setup

```bash
./bootstrap.sh
```

This will:
1. Initialize git submodules
2. Install Nix (if not installed)

Then apply the configuration via flake apps:

```bash
nix run .#darwin-switch   # Apply nix-darwin + home-manager configuration (mise 等のパッケージもここで入る)
nix run .#tools           # Install development tools (mise install)
```

### Other flake apps

```bash
nix run .#clean           # nh clean all --keep-since 30d --keep-one
```

## Structure

```
.
├── bootstrap.sh    # Nix 導入前の最小限のセットアップ
├── flake.nix
├── darwin/         # nix-darwin システム設定 + home-manager 統合
└── home/           # home-manager 配下の各ツール設定
```

## Notes

* `home/` 配下は `mkOutOfStoreSymlink` で配置
  * `.zshrc` / `nvim/` / `claude/CLAUDE.md` など、既存ファイルの編集は保存後すぐ反映
* `nix run .#darwin-switch` が必要な変更
  * `home.packages` の追加・削除
  * `home.file` / `xdg.configFile` の symlink 追加
  * `darwin/` 配下の変更
  * `flake.nix` / `flake.lock` の更新
    * `flake.lock` は `nix flake update` 後に実行
* Neovim plugins
  * `vim.pack` で管理し、`home/nvim/nvim-pack-lock.json` に revision を記録
  * GitHub Actions が毎月1日に更新し、差分がある場合のみ PR を作成
  * 手動更新は `Update Neovim plugins` の `workflow_dispatch`
  * 更新取り込み後は `:restart`
