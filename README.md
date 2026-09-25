# My Dotfiles

## Setup

Apple Silicon Mac 向け。Xcode 本体は不要ですが、Git・Homebrew 用に Command Line Tools が必要です。

未導入の場合は、先に次を実行してダイアログからインストールします。

```bash
xcode-select --install
```

インストール完了後、`xcode-select -p` で開発ツールのパスが表示されることを確認します。その後、任意の場所に clone し、リポジトリ直下で実行します。

```bash
./bootstrap.sh
```

This will:
1. Initialize git submodules
2. Install Nix (if not installed)

Then apply the configuration via flake apps:

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
nix run .#darwin-switch   # Apply nix-darwin + home-manager configuration (mise 等のパッケージもここで入る)
exec zsh -l              # 新しい PATH を読み込む
nix run .#tools           # Install development tools (mise install)
```

`darwin-switch` は実行ユーザーと現在の配置先を取得します。`sudo` を付けずに実行してください。配置先を移動した場合は、新しい場所で再実行します。

Nix 導入時の環境読み込みは `bootstrap.sh` の外に引き継がれないため、上記の `.` コマンドが必要です。

Claude Code の初回起動時にマーケットプレイスの確認が出たら承認します。`rin2yh-plugins` の取得元と有効プラグインは `home/claude/settings.json` で管理しています。

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

* Go / TinyGo は Nix で管理し、Go は TinyGo が依存するバージョンに合わせる
* `jq` は Nix、`im-select` は Homebrew で導入
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
