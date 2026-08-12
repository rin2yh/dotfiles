package main

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

// 拡張子ごとの行コメント記号。ブロックコメントは扱わない。
// この構成では使っておらず、対応すると誤爆のほうが増える。
var lineComment = map[string]string{
	".yml": "#", ".yaml": "#", ".sh": "#", ".bash": "#", ".nix": "#",
	".toml": "#", ".txt": "#", ".js": "//", ".mjs": "//", ".cjs": "//",
	".ts": "//", ".lua": "--",
}

var markdownExt = map[string]bool{".md": true, ".mdx": true, ".markdown": true}

var (
	fence      = regexp.MustCompile("^\\s*```")
	inlineCode = regexp.MustCompile("`[^`]*`")
	// 「」で囲んだ語は引用とみなして検査から外す。辞書やスキルの文章は
	// 検出対象の語を「不可欠」のように引用して説明するので、
	// そのまま当てると自分自身を指摘し続けることになる。
	quoted = regexp.MustCompile(`「[^」]{1,40}」`)
)

// Scan は本文を 1 行ずつ辞書に当て、"場所:行  語 => 方針" を返す。
//
// textlint を経由しないのは、これが毎ターン走る経路だから。
// textlint は起動だけで 1.3 秒かかり、辞書の照合は 6 ミリ秒で済む。
// 文長や助詞の重複といった汎用の検査は ai-tone lint のほうで受け持つ。
func Scan(matcher *Matcher, body, label string, commentsOnly bool) []string {
	marker := ""
	if commentsOnly {
		marker = lineComment[filepath.Ext(label)]
		if marker == "" {
			return nil
		}
	}
	var problems []string
	inFence := false
	for index, line := range strings.Split(body, "\n") {
		text := strings.TrimSpace(line)
		if fence.MatchString(text) {
			inFence = !inFence
			continue
		}
		if inFence {
			continue
		}
		if marker != "" {
			if !strings.HasPrefix(text, marker) {
				continue
			}
			text = strings.TrimSpace(strings.TrimPrefix(text, marker))
		}
		// コード中の語は文体の問題ではない。
		text = inlineCode.ReplaceAllString(text, "")
		text = quoted.ReplaceAllString(text, "")
		for _, hit := range matcher.FindAll(text, maxReportLines) {
			problems = append(problems, fmt.Sprintf("%s:%d  %s => %s", label, index+1, hit.Word, hit.Advice))
		}
	}
	return problems
}

// ScanFile はファイルを辞書に当てる。Markdown は本文を、それ以外はコメントだけを見る。
// textlint が見るのは Markdown の本文だけなので、設定リポジトリのように
// 日本語の大半がコメント側にあると、辞書を入れただけでは大部分が素通りになる。
func ScanFile(matcher *Matcher, path string) ([]string, error) {
	extension := filepath.Ext(path)
	if !markdownExt[extension] && lineComment[extension] == "" {
		return nil, nil
	}
	body, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	return Scan(matcher, string(body), path, !markdownExt[extension]), nil
}
