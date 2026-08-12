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
// 検査するのは 4 点。
//  1. prh が辞書をロードできること。prh は specs が 1 件でも外れるとロードに失敗するので、
//     これだけで「書いたつもりのパターンが実際にマッチするか」が確かめられる。
//  2. 辞書のパターンが Go の regexp でも扱えること。Go は RE2 なので先読みが無く、
//     textlint では動くのに会話検査の網だけが黙って減る、という事故を防ぐ。
//  3. ai-tone.yml の規則を全部当てても、壊れてはいけない文が変わらないこと。
//     specs はその規則の中でしか効かないので、規則をまたいだ事故はここでしか捕まえられない。
//  4. 辞書とスクリプト自身のコメントが、自分の規則に照らして問題ないこと。
//     辞書を書く側の日本語が野放しになるのは筋が通らない。
func RunCheck(config Config) int {
	if !config.Ready() {
		fmt.Fprintln(os.Stderr, "textlint が入っていない。make textlint を実行すること")
		return 2
	}
	var failures []string
	fail := func(format string, args ...any) { failures = append(failures, fmt.Sprintf(format, args...)) }
	ok := func(format string, args ...any) { fmt.Printf("  ok  "+format+"\n", args...) }

	fmt.Println("1. prh が辞書をロードできるか（specs の検証を兼ねる）")
	if stderr := probeTextlint(config); stderr != "" {
		fail("辞書のロードに失敗: %s", firstLine(stderr))
	} else {
		ok("%d ファイル", len(config.Dicts))
	}

	fmt.Println("2. 辞書のパターンを Go の regexp で扱えるか")
	matcher, skipped, err := LoadMatcher(config.Dicts, false)
	switch {
	case err != nil:
		fail("辞書を読めない: %v", err)
	case len(skipped) > 0:
		for _, entry := range skipped {
			fail("会話検査から落ちるパターン: %s", entry)
		}
	default:
		ok("%d 件すべて扱える", len(matcher.patterns))
	}

	fmt.Println("3. ai-tone.yml を当てても壊れてはいけない文が変わらないか")
	if broken, err := checkFixSafety(config); err != nil {
		fail("%v", err)
	} else if len(broken) > 0 {
		for _, entry := range broken {
			fail("--fix が本文を壊す: %s", entry)
		}
	} else {
		ok("fix-safety.txt の全文が無変化")
	}

	fmt.Println("4. 辞書とスクリプト自身のコメントが自分の規則に照らして問題ないか")
	targets := append([]string{config.FixSafety}, config.Dicts...)
	var problems []string
	for _, target := range targets {
		found, err := config.LintFile(target)
		if err != nil {
			fail("%s の検査に失敗: %v", target, err)
			continue
		}
		problems = append(problems, found...)
	}
	if len(problems) > 0 {
		for _, problem := range problems {
			fail("コメントの指摘: %s", problem)
		}
	} else {
		ok("%d ファイルのコメントに指摘なし", len(targets))
	}

	if len(failures) > 0 {
		fmt.Fprintln(os.Stderr, "\n失敗:")
		for _, failure := range failures {
			fmt.Fprintln(os.Stderr, "  - "+failure)
		}
		return 1
	}
	fmt.Println("\nすべて通過")
	return 0
}

// probeTextlint は辞書を読ませるためだけに textlint を空入力で走らせる。
// specs が外れていれば prh がロードに失敗し、stderr に出る。
func probeTextlint(config Config) string {
	command := exec.Command(config.TextlintBin,
		"--config", config.TextlintRC, "--stdin", "--stdin-filename", "probe.md", "--format", "json")
	command.Stdin = strings.NewReader("検査用の空文\n")
	var stderr strings.Builder
	command.Stderr = &stderr
	output, _ := command.Output()
	// 辞書のロードに失敗すると JSON ではなくエラーが返る。
	if len(output) > 0 && output[0] == '[' {
		return ""
	}
	if stderr.Len() > 0 {
		return stderr.String()
	}
	return string(output)
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
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		sentences = append(sentences, line)
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
	before := strings.Join(sentences, "\n\n")
	if err := os.WriteFile(probe, []byte(before+"\n"), 0o600); err != nil {
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
			broken = append(broken, fmt.Sprintf("「%s」 → 「%s」", sentences[index], line))
		}
	}
	return broken, nil
}

// runFix は機械的に直せる指摘だけを自動修正する。
// 方針を書いた expected を持つ ai-tone-review は linter だけで登録してあるので、
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
