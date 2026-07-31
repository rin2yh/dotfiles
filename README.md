# My Dotfiles

## Setup

```bash
make
```

This will:
1. Initialize git submodules
2. Install mise (if not installed)
3. Install Nix (if not installed)
4. Apply nix-darwin + home-manager configuration (`darwin-rebuild switch --flake .#<hostname>`)
5. Install development tools (`mise install`, `gopls`)

### Individual Targets

```bash
make submodule-init   # Initialize and update git submodules
make mise-install     # Install mise via curl (if not installed)
make nix-install      # Install Nix via official installer (if not installed)
make darwin-switch    # Apply nix-darwin + home-manager configuration (flake)
make tools            # Install development tools (mise install, gopls)
make textlint         # Install the Japanese proofreading toolchain (home/textlint)
make help             # Show available targets
```

## Structure

```
.
├── flake.nix
├── darwin/         # nix-darwin システム設定 + home-manager 統合
├── home/           # home-manager 配下の各ツール設定
│   └── textlint/   # 日本語の校正環境（AI 文体検出プリセットを含む）
└── Makefile
```

## 日本語の校正

`home/textlint/` に textlint の環境を置いている。汎用の
`preset-ja-technical-writing` に加えて、LLM が書きがちな文体を検出する自作プリセット
`preset-ja-no-ai-tone` を併用する。

Claude Code は 2 つの経路で検査する。強度は環境変数で変えられ、設定ファイルの編集は要らない。

| 経路 | 対象 | 手段 | 既定 | 環境変数 |
| --- | --- | --- | --- | --- |
| `PostToolUse` フック | 書き込まれた Markdown の本文 | textlint 本体 | ブロック | `CLAUDE_AI_TONE_FILE` |
| `PostToolUse` フック | YAML / シェル / JS などのコメント | `lint-comments.mjs` | ブロック | `CLAUDE_AI_TONE_FILE` |
| `Stop` フック | 直前の応答本文 | ripgrep（生成済みパターン） | 警告のみ | `CLAUDE_AI_TONE_CHAT` |

textlint が見るのは Markdown の本文だけなので、コメントは別経路で検査する。
この構成では日本語の大半がコメント側にあり、プリセットを入れただけでは大部分が素通りになる
（このプリセットを追加した変更自体、22 ファイル中 17 ファイルが検査対象外だった）。

会話の検査に textlint を使わないのは、起動に 1.5 〜 2 秒かかり毎ターン走らせるには重いため。
辞書の更新手順は `home/claude/skills/ai-tone-dict/SKILL.md` にある。

## Notes

- `home/` 配下のファイルは `mkOutOfStoreSymlink` でリポジトリ実体への symlink として配置されている。既存ファイル（`.zshrc` / `nvim/` / `claude/CLAUDE.md` など）の内容だけを編集する場合、`darwin-rebuild switch` は不要で保存すれば即反映される。
- 以下のケースでは `make darwin-switch` が必要:
  - `home/home.nix` の `home.packages` にパッケージを追加/削除
  - `home.file` / `xdg.configFile` に新しい symlink エントリを追加
  - `darwin/` 配下 (`configuration.nix` / `homebrew.nix` など) の変更
  - `flake.nix` / `flake.lock` の更新
- `flake.lock` を更新する場合は `nix flake update` 後に `make darwin-switch`。
