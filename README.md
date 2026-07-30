# My Dotfiles

## Setup

```bash
make
```

別のマシンの設定を適用する場合:

```bash
make MACHINE=work
```

This will:
1. Initialize git submodules
2. Install mise (if not installed)
3. Install Nix (if not installed)
4. Apply nix-darwin + home-manager configuration (`darwin-rebuild switch --flake .#<machine>`)
5. Install development tools (`mise install`, `gopls`)

### Individual Targets

```bash
make submodule-init   # Initialize and update git submodules
make mise-install     # Install mise via curl (if not installed)
make nix-install      # Install Nix via official installer (if not installed)
make darwin-switch    # Apply nix-darwin + home-manager configuration (flake, MACHINE=<name>)
make tools            # Install development tools (mise install, gopls)
make help             # Show available targets
```

## Structure

```
.
├── flake.nix       # マシンごとの darwinConfigurations を定義
├── darwin/         # nix-darwin システム設定 + home-manager 統合
├── home/           # home-manager 配下の各ツール設定
└── Makefile
```

## Machines

複数マシンをブランチで分けず、1 本の `main` で扱う。`flake.lock` と設定が集約されるので、
Dependabot の更新やマシン間のコンフリクト対応が 1 回で済む。

nix レベルでマシン間に差があるのは `username` だけなので、`flake.nix` の
`darwinConfigurations` に 1 行足すだけでマシンを追加できる。

```nix
darwinConfigurations = {
  default = mkDarwin { };
  work = mkDarwin { username = "yukihayashi"; };
};
```

- `mkDarwin` は `username` と `dotfilesDir`（クローン先。既定は
  `/Users/<username>/workspace/dotfiles`）を受け取る
- 適用するマシンは `--flake .#<machine>`（= `make MACHINE=<name>`）で明示する。
  `networking.hostName` は移植性のため全マシン `default` 固定で、ホスト名には依存しない
- マシン固有のモジュールが必要になったら、その時点で `mkDarwin` に `extraModules` を
  足す。差分が無いうちは作らない
- nix で管理していないファイル（`home/` 配下の実体）にマシン差が出た場合は、各ツールの
  仕組みで受ける。Claude Code は `~/.claude/settings.local.json`（user settings より
  優先される）、mise は `~/.config/mise/conf.d/*.toml`、zsh は `.zshrc` からの
  local ファイル読み込み

## Notes

- `home/` 配下のファイルは `mkOutOfStoreSymlink` でリポジトリ実体への symlink として配置されている。既存ファイル（`.zshrc` / `nvim/` / `claude/CLAUDE.md` など）の内容だけを編集する場合、`darwin-rebuild switch` は不要で保存すれば即反映される。
- 以下のケースでは `make darwin-switch` が必要:
  - `home/home.nix` の `home.packages` にパッケージを追加/削除
  - `home.file` / `xdg.configFile` に新しい symlink エントリを追加
  - `darwin/` 配下 (`configuration.nix` / `homebrew.nix` など) の変更
  - `flake.nix` / `flake.lock` の更新
- `flake.lock` を更新する場合は `nix flake update` 後に `make darwin-switch`。
