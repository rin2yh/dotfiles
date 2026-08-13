package main

import (
	"fmt"
	"os"
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
	matcher, skipped, err := LoadMatcher([]string{config.Dict}, false)
	if err != nil {
		failures = append(failures, fmt.Sprintf("辞書を読めない: %v", err))
	}
	for _, entry := range skipped {
		failures = append(failures, "フックの検査から落ちるパターン: "+entry)
	}

	if err := runProbe(config); err != nil {
		failures = append(failures, err.Error())
	}

	// 辞書自身のコメントも自分の規則に当てる。書く側の日本語が野放しなのは筋が通らない。
	if matcher != nil {
		if found, err := ScanFile(matcher, config.Dict); err == nil {
			failures = append(failures, found...)
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
