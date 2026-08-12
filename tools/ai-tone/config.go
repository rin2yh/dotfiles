package main

import (
	"os"
	"path/filepath"
)

// Config は辞書と textlint の場所、および各検査の強度。
// 強度を環境変数で持つのは、記事を書くセッションだけ会話も止めたい、
// といった切り替えを設定ファイルの編集なしで行えるようにするため。
type Config struct {
	Dir         string
	Dicts       []string
	TextlintBin string
	TextlintRC  string
	CommentsRC  string
	FixRC       string
	FixSafety   string

	ChatMode string // 会話出力（既定 warn）
	FileMode string // ファイル書き込み（既定 block）
	PostMode string // PR 本文・コミットメッセージ（既定 block）
}

func envOr(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}

func LoadConfig() Config {
	home, _ := os.UserHomeDir()
	dir := envOr("CLAUDE_AI_TONE_DIR", filepath.Join(home, "workspace/dotfiles/home/textlint"))
	dict := filepath.Join(dir, "preset-ja-no-ai-tone", "dict")
	return Config{
		Dir:         dir,
		Dicts:       []string{filepath.Join(dict, "ai-tone.yml"), filepath.Join(dict, "ai-tone-review.yml")},
		TextlintBin: filepath.Join(dir, "node_modules", ".bin", "textlint"),
		TextlintRC:  filepath.Join(dir, ".textlintrc.json"),
		CommentsRC:  filepath.Join(dir, ".textlintrc.comments.json"),
		FixRC:       filepath.Join(dir, ".textlintrc.fix.json"),
		FixSafety:   filepath.Join(dict, "fix-safety.txt"),
		ChatMode:    envOr("CLAUDE_AI_TONE_CHAT", "warn"),
		FileMode:    envOr("CLAUDE_AI_TONE_FILE", "block"),
		PostMode:    envOr("CLAUDE_AI_TONE_POST", "block"),
	}
}

// Ready は textlint が入っているか。入っていなければ検査を諦めて黙って通す。
func (c Config) Ready() bool {
	_, err := os.Stat(c.TextlintBin)
	return err == nil
}
