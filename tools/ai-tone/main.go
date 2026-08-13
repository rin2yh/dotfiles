// ai-tone は AI っぽい日本語表現の検査をまとめたコマンド。
// Claude Code のフックからも、手元の CLI としても同じ辞書を使う。
//
// 2 つの経路がある。
//
//	hook   毎ターン走るので辞書を直接当てる。速い代わりに AI 文体の規則だけ。
//	lint   textlint を呼ぶ。preset-ja-technical-writing の汎用検査も含む。
package main

import (
	"fmt"
	"os"
)

const usage = `ai-tone <command> [args]

  hook            標準入力のフック JSON を読み、指摘があれば終了コード 2 で返す
  scan <file>...  辞書だけを当てる（Markdown は本文、それ以外はコメント）
  lint <file>...  textlint を呼ぶ。汎用プリセットの検査も含む
  check           辞書の回帰テスト
`

func main() {
	if len(os.Args) < 2 {
		fmt.Fprint(os.Stderr, usage)
		os.Exit(2)
	}
	config := LoadConfig()
	args := os.Args[2:]

	switch os.Args[1] {
	case "hook":
		// 終了コード 2 は「stderr を理由として Claude に渡し、その操作を止める」の合図。
		if reason := RunHook(config, os.Stdin); reason != "" {
			fmt.Fprintln(os.Stderr, reason)
			os.Exit(2)
		}
	case "scan":
		os.Exit(runScan(config, args))
	case "lint":
		os.Exit(runTextlint(config, args))
	case "check":
		os.Exit(RunCheck(config))
	default:
		fmt.Fprint(os.Stderr, usage)
		os.Exit(2)
	}
}

func runScan(config Config, paths []string) int {
	matcher, _, err := LoadMatcher([]string{config.Dict}, false)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return 2
	}
	var problems []string
	for _, path := range paths {
		found, err := ScanFile(matcher, path)
		if err != nil {
			fmt.Fprintf(os.Stderr, "%s: %v\n", path, err)
			continue
		}
		problems = append(problems, found...)
	}
	for _, problem := range problems {
		fmt.Println(problem)
	}
	if len(problems) == 0 {
		return 0
	}
	fmt.Printf("\n%d problems\n", len(problems))
	return 1
}

// runTextlint は textlint をそのまま呼ぶ。出力の加工はしない。
func runTextlint(config Config, paths []string) int {
	if !config.Ready() {
		fmt.Fprintln(os.Stderr, "npx が見つからない。node を入れること")
		return 2
	}
	command := config.Textlint(append([]string{"--config", config.TextlintRC}, paths...)...)
	command.Stdout = os.Stdout
	command.Stderr = os.Stderr
	if err := command.Run(); err != nil {
		return 1
	}
	return 0
}
