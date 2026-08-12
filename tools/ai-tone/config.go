package main

import (
	"os"
	"path/filepath"
)

// Config は辞書と textlint の場所。
type Config struct {
	Dir         string
	Dicts       []string
	TextlintBin string
	TextlintRC  string
	FixSafety   string
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
		FixSafety:   filepath.Join(dict, "fix-safety.txt"),
	}
}

// Ready は textlint が入っているか。入っていなければ検査を諦めて黙って通す。
func (c Config) Ready() bool {
	_, err := os.Stat(c.TextlintBin)
	return err == nil
}
