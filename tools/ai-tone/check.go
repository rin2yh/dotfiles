package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// RunCheck は辞書の回帰テスト。辞書を更新したら通してからコミットする。
//
// 辞書に textlint を通すこと自体が prh のロードを兼ねる。prh は specs が 1 件でも
// 外れるとロードに失敗するので、それだけで「書いたつもりのパターンが実際に
// マッチするか」が確かめられる。
func RunCheck(config Config) int {
	if !config.Ready() {
		fmt.Fprintln(os.Stderr, "npx が見つからない。node を入れること")
		return 2
	}
	var failures []string

	// Go の regexp は RE2 なので先読みが無い。prh 側で書くと textlint では動くのに
	// フックの網だけが黙って減るので、ここで気づけるようにする。
	matcher, skipped, err := LoadMatcher(config.Dicts, false)
	if err != nil {
		failures = append(failures, fmt.Sprintf("辞書を読めない: %v", err))
	}
	for _, entry := range skipped {
		failures = append(failures, "フックの検査から落ちるパターン: "+entry)
	}

	if err := runProbe(config); err != nil {
		failures = append(failures, err.Error())
	}

	// specs はその規則の中しか検査しないので、
	// 規則をまたいで --fix が本文を壊す事故はここでしか捕まえられない。
	broken, err := checkFixSafety(config)
	if err != nil {
		failures = append(failures, err.Error())
	}
	failures = append(failures, broken...)

	// 辞書自身のコメントも自分の規則に当てる。書く側の日本語が野放しなのは筋が通らない。
	if matcher != nil {
		for _, dict := range config.Dicts {
			found, err := ScanFile(matcher, dict)
			if err == nil {
				failures = append(failures, found...)
			}
		}
	}

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

// runProbe は辞書を読ませるためだけに textlint を空入力で走らせる。
// specs が外れていれば prh がロードに失敗する。
func runProbe(config Config) error {
	command := config.Textlint("--config", config.TextlintRC, "--stdin", "--stdin-filename", "probe.md")
	command.Stdin = strings.NewReader("検査用の文である。\n")
	var stderr strings.Builder
	command.Stderr = &stderr
	command.Output()
	if strings.Contains(stderr.String(), "Error while loading rule") {
		return fmt.Errorf("辞書のロードに失敗: %s", strings.SplitN(stderr.String(), "\n", 2)[0])
	}
	return nil
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
	config.Textlint("--fix", "--config", config.FixRC, probe).Run()
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
