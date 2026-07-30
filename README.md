# My Dotfiles

## Setup

```bash
make
```

別のプロファイル（マシン）を適用する場合:

```bash
make PROFILE=work
```

This will:
1. Initialize git submodules
2. Install mise (if not installed)
3. Install Nix (if not installed)
4. Apply nix-darwin + home-manager configuration (`darwin-rebuild switch --flake .#<profile>`)
5. Install development tools (`mise install`, `gopls`)

### Individual Targets

```bash
make submodule-init   # Initialize and update git submodules
make mise-install     # Install mise via curl (if not installed)
make nix-install      # Install Nix via official installer (if not installed)
make darwin-switch    # Apply nix-darwin + home-manager configuration (flake, PROFILE=<name>)
make tools            # Install development tools (mise install, gopls)
make profile          # Show the profile that darwin-switch will apply
make help             # Show available targets
```

## Structure

```
.
├── flake.nix
├── darwin/         # 全マシン共通の nix-darwin システム設定 + home-manager 統合
├── home/           # 全マシン共通の home-manager 設定と各ツール設定
├── profiles/       # マシンごとの差分
│   ├── default/
│   │   ├── darwin.nix
│   │   └── home.nix
│   └── work/
│       ├── darwin.nix
│       └── home.nix
└── Makefile
```

## Profiles

マシンごとの差分はブランチではなく `profiles/<name>/` で管理する。`flake.lock` や共通設定が
1 本の `main` に集約されるので、Dependabot の更新やマシン間のコンフリクト対応が 1 回で済む。

- 共通の設定 → `darwin/`, `home/`
- そのマシンだけの設定 → `profiles/<name>/darwin.nix`（システム / Homebrew）、
  `profiles/<name>/home.nix`（home-manager）
- プロファイルの選択は `--flake .#<profile>` の明示指定。`networking.hostName` は
  移植性のため全プロファイル `default` 固定で、ホスト名には依存しない。
- 適用したプロファイル名は `.current-profile`（gitignore 済み）に記録され、以降の
  `make darwin-switch` は引数なしで同じプロファイルを使う。

### プロファイルを追加する

1. `profiles/<name>/darwin.nix` と `profiles/<name>/home.nix` を作る（中身は空の `{ }` でよい）
2. `flake.nix` の `darwinConfigurations` に `<name> = mkDarwin { profile = "<name>"; };` を追加
3. `.github/workflows/ci.yml` の `matrix.profile` に `<name>` を追加

`mkDarwin` は `username` と `dotfilesDir`（リポジトリのクローン先。既定は
`/Users/<username>/workspace/dotfiles`）も受け取るので、ユーザー名やクローン先が違う
マシンはここで上書きする。

## Notes

- `home/` 配下のファイルは `mkOutOfStoreSymlink` でリポジトリ実体への symlink として配置されている。既存ファイル（`.zshrc` / `nvim/` / `claude/CLAUDE.md` など）の内容だけを編集する場合、`darwin-rebuild switch` は不要で保存すれば即反映される。
- 以下のケースでは `make darwin-switch` が必要:
  - `home/home.nix` の `home.packages` にパッケージを追加/削除
  - `home.file` / `xdg.configFile` に新しい symlink エントリを追加
  - `darwin/` 配下 (`configuration.nix` / `homebrew.nix` など) の変更
  - `flake.nix` / `flake.lock` の更新
- `flake.lock` を更新する場合は `nix flake update` 後に `make darwin-switch`。
