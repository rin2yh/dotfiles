// ai-tone は AI っぽい日本語表現の検査をまとめたコマンド。
// Claude Code のフックからも、手元の CLI としても同じ実装を使う。
//
// 規則そのものは textlint と prh（どちらも Node）が持っている。
// このコマンドが受け持つのは、検査する文章を取り出すことと、
// 発火点ごとの応答を組み立てること。
package main

import (
	"fmt"
	"os"
)

const usage = `ai-tone <command> [args]

  hook            標準入力のフック JSON を読んで応答を返す
  lint <file>...  Markdown は本文を、それ以外はコメントを検査する
  text <file>...  ファイル全体を地の文として検査する（PR 本文・コミットメッセージ）
  fix <file>...   機械的に直せる指摘だけを自動修正する
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
		if err := RunHook(config, os.Stdin, os.Stdout); err != nil {
			os.Exit(0) // フックのせいで会話が止まるのは最悪なので、失敗しても通す
		}
	case "lint":
		os.Exit(report(lintAll(config, args, config.LintFile)))
	case "text":
		os.Exit(report(lintAll(config, args, func(path string) ([]string, error) {
			body, err := os.ReadFile(path)
			if err != nil {
				return nil, err
			}
			return config.LintText(string(body), path)
		})))
	case "fix":
		os.Exit(runFix(config, args))
	case "check":
		os.Exit(RunCheck(config))
	default:
		fmt.Fprint(os.Stderr, usage)
		os.Exit(2)
	}
}

func lintAll(config Config, paths []string, lint func(string) ([]string, error)) []string {
	if !config.Ready() {
		fmt.Fprintln(os.Stderr, "textlint が入っていない。make textlint を実行すること")
		os.Exit(2)
	}
	var problems []string
	for _, path := range paths {
		found, err := lint(path)
		if err != nil {
			fmt.Fprintf(os.Stderr, "%s: %v\n", path, err)
			continue
		}
		problems = append(problems, found...)
	}
	return problems
}

func report(problems []string) int {
	for _, problem := range problems {
		fmt.Println(problem)
	}
	if len(problems) == 0 {
		return 0
	}
	fmt.Printf("\n%d problems\n", len(problems))
	return 1
}
