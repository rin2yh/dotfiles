package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// RunCheck は辞書の回帰テスト。辞書を更新したら通してからコミットする。
//
// 辞書を lint に通すこと自体が prh のロードを兼ねる。prh は specs が 1 件でも
// 外れるとロードに失敗するので、それだけで「書いたつもりのパターンが実際に
// マッチするか」が確かめられる。あわせて辞書自身のコメントも検査される。
func RunCheck(config Config) int {
	if !config.Ready() {
		fmt.Fprintln(os.Stderr, "textlint が入っていない。make textlint を実行すること")
		return 2
	}
	var failures []string

	for _, target := range append([]string{config.FixSafety}, config.Dicts...) {
		problems, err := config.LintFile(target)
		if err != nil {
			failures = append(failures, fmt.Sprintf("%s: %v", target, err))
			continue
		}
		failures = append(failures, problems...)
	}

	// Go の regexp は RE2 なので先読みが無い。prh 側で書くと textlint では動くのに
	// 会話検査の網だけが黙って減るので、ここで気づけるようにする。
	if _, skipped, err := LoadMatcher(config.Dicts, false); err != nil {
		failures = append(failures, fmt.Sprintf("辞書を読めない: %v", err))
	} else {
		for _, entry := range skipped {
			failures = append(failures, "会話検査から落ちるパターン: "+entry)
		}
	}

	// specs はその規則の中しか検査しないので、
	// 規則をまたいで --fix が本文を壊す事故はここでしか捕まえられない。
	broken, err := checkFixSafety(config)
	if err != nil {
		failures = append(failures, err.Error())
	}
	failures = append(failures, broken...)

	if len(failures) > 0 {
		for _, failure := range failures {
			fmt.Fprintln(os.Stderr, "  "+failure)
		}
		fmt.Fprintf(os.Stderr, "\n%d problems\n", len(failures))
		return 1
	}
	fmt.Println("すべて通過")
	return 0
}

// checkFixSafety は fix-safety.txt の各文に --fix を当て、変わったものを返す。
func checkFixSafety(config Config) ([]string, error) {
	body, err := os.ReadFile(config.FixSafety)
	if err != nil {
		return nil, err
	}
	var sentences []string
	for _, line := range strings.Split(string(body), "\n") {
		line = strings.TrimSpace(line)
		if line != "" && !strings.HasPrefix(line, "#") {
			sentences = append(sentences, line)
		}
	}
	if len(sentences) == 0 {
		return nil, nil
	}

	// --fix はファイルを書き換えるので、一時ファイルに写してから当てる。
	dir, err := os.MkdirTemp("", "ai-tone")
	if err != nil {
		return nil, err
	}
	defer os.RemoveAll(dir)
	probe := filepath.Join(dir, "fix-safety.md")
	if err := os.WriteFile(probe, []byte(strings.Join(sentences, "\n\n")+"\n"), 0o600); err != nil {
		return nil, err
	}
	exec.Command(config.TextlintBin, "--fix", "--config", config.TextlintRC, probe).Run()
	after, err := os.ReadFile(probe)
	if err != nil {
		return nil, err
	}

	var broken []string
	for index, line := range strings.Split(strings.TrimRight(string(after), "\n"), "\n\n") {
		if index < len(sentences) && line != sentences[index] {
			broken = append(broken, fmt.Sprintf("--fix が本文を壊す: 「%s」 → 「%s」", sentences[index], line))
		}
	}
	return broken, nil
}

// runFix は機械的に直せる指摘だけを自動修正する。
// 方針を書いた expected を持つ ai-tone-review は linter だけを登録してあるので、
// --fix は構造的に触れない。設定を分ける必要はない。
func runFix(config Config, paths []string) int {
	if !config.Ready() || len(paths) == 0 {
		return 2
	}
	args := append([]string{"--fix", "--config", config.TextlintRC}, paths...)
	command := exec.Command(config.TextlintBin, args...)
	command.Stdout = os.Stdout
	command.Stderr = os.Stderr
	command.Run()
	return 0
}
