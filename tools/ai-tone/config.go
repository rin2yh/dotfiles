package main

import (
	"os"
	"os/exec"
	"path/filepath"
)

// Config は辞書の場所と、textlint の呼び出し方。
type Config struct {
	Dir        string
	Dict       string
	TextlintRC string
}

// textlint は npx がその場で解決する。リポジトリに package.json も node_modules も置かない。
// lock ファイルが差分の 76% を占めていたので、固定する代わりに毎回解決させている。
var textlintPackages = []string{
	"--yes",
	"--package", "textlint",
	"--package", "textlint-rule-prh",
	"--package", "textlint-rule-preset-ja-technical-writing",
	"--", "textlint",
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
	return Config{
		Dir:        dir,
		Dict:       filepath.Join(dir, "dict", "ai-tone.yml"),
		TextlintRC: filepath.Join(dir, ".textlintrc.json"),
	}
}

// Textlint は textlint を呼ぶコマンドを組み立てる。
// 設定ファイルの相対パスが辞書を指すので、必ず設定のあるディレクトリで動かす。
func (c Config) Textlint(args ...string) *exec.Cmd {
	command := exec.Command("npx", append(append([]string{}, textlintPackages...), args...)...)
	command.Dir = c.Dir
	return command
}

// Ready は npx が使えるか。使えなければ検査を諦めて黙って通す。
func (c Config) Ready() bool {
	_, err := exec.LookPath("npx")
	return err == nil
}
