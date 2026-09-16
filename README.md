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

- `home/` 配下のファイルは `mkOutOfStoreSymlink` でリポジトリ実体への symlink として配置されている。既存ファイル（`.zshrc` / `nvim/` / `claude/CLAUDE.md` など）の内容だけを編集する場合、`darwin-rebuild switch` は不要で保存すれば即反映される。
- 以下のケースでは `nix run .#darwin-switch` が必要:
  - `home/home.nix` の `home.packages` にパッケージを追加/削除
  - `home.file` / `xdg.configFile` に新しい symlink エントリを追加
  - `darwin/` 配下 (`configuration.nix` / `homebrew.nix` など) の変更
  - `flake.nix` / `flake.lock` の更新
- `flake.lock` を更新する場合は `nix flake update` 後に `nix run .#darwin-switch`。
- Neovim のプラグインは `vim.pack` 管理で、リビジョンは `home/nvim/nvim-pack-lock.json` に記録される。
  GitHub Actions の `Update Neovim plugins` が毎月 1 日に `vim.pack.update()` を実行する。
  lockfile に差分があるときだけ PR を作る（手動実行は Actions タブの workflow_dispatch から）。
  取り込んだあとは `:restart` で新しいリビジョンが読み込まれる。
