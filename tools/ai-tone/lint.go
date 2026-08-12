package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

// textlint の JSON 出力のうち、使う項目だけ。
type textlintResult struct {
	Messages []struct {
		Line    int    `json:"line"`
		Message string `json:"message"`
		RuleID  string `json:"ruleId"`
	} `json:"messages"`
}

var (
	hasJapanese = regexp.MustCompile(`[ぁ-んァ-ヶ一-龠]`)
	// 「」で囲んだ語は Markdown のインラインコードと同じ扱いで検査対象から外す。
	// 辞書のコメントは検出対象の語を「不可欠」のように引用して説明するので、
	// そのまま当てると自分自身を指摘し続けることになる。
	quoted = regexp.MustCompile(`「([^」]{1,40})」`)
)

// 拡張子ごとの行コメント記号。ブロックコメントは扱わない。
// この構成では使っておらず、対応すると誤爆のほうが増える。
var lineComment = map[string]string{
	".yml": "#", ".yaml": "#", ".sh": "#", ".bash": "#", ".nix": "#",
	".toml": "#", ".txt": "#", ".js": "//", ".mjs": "//", ".cjs": "//",
	".ts": "//", ".lua": "--",
}

var markdownExt = map[string]bool{".md": true, ".mdx": true, ".markdown": true}

// row は検査に回す 1 行と、元の文章での行番号。
type row struct {
	line int
	text string
}

// extract は本文から検査対象の行を取り出す。
// prose を立てると全行を地の文として扱う。立てなければコメント行だけを拾う。
func extract(body, extension string, prose bool) []row {
	marker := ""
	if !prose {
		marker = lineComment[extension]
		if marker == "" {
			return nil
		}
	}
	var rows []row
	for index, line := range strings.Split(body, "\n") {
		text := strings.TrimSpace(line)
		if marker != "" {
			if !strings.HasPrefix(text, marker) {
				continue
			}
			text = strings.TrimSpace(strings.TrimPrefix(text, marker))
		}
		if text == "" || !hasJapanese.MatchString(text) {
			continue
		}
		rows = append(rows, row{line: index + 1, text: quoted.ReplaceAllString(text, "`$1`")})
	}
	return rows
}

// runTextlint は textlint を呼び、"<場所>:<行>  <指摘>  (<規則>)" の一覧を返す。
func (c Config) runTextlint(args []string, stdin string) ([]string, error) {
	command := exec.Command(c.TextlintBin, args...)
	if stdin != "" {
		command.Stdin = strings.NewReader(stdin)
	}
	output, err := command.Output()
	if len(output) == 0 {
		return nil, err
	}
	var results []textlintResult
	if err := json.Unmarshal(output, &results); err != nil {
		return nil, fmt.Errorf("textlint の出力を解析できない: %w", err)
	}
	var problems []string
	for _, result := range results {
		for _, message := range result.Messages {
			problems = append(problems, fmt.Sprintf("%d  %s  (%s)",
				message.Line, firstLine(message.Message), message.RuleID))
		}
	}
	return problems, nil
}

func firstLine(text string) string {
	if index := strings.Index(text, "\n"); index >= 0 {
		return text[:index]
	}
	return text
}

// LintRows は抜き出した行を textlint にかける。
// 1 行 = 1 段落にして渡す。連結すると textlint が別の行をつないで文とみなし、
// 助詞の重複などを誤検出する。行番号は元の文章のものに戻して報告する。
func (c Config) LintRows(rows []row, label string) ([]string, error) {
	if len(rows) == 0 {
		return nil, nil
	}
	texts := make([]string, len(rows))
	for i, r := range rows {
		texts[i] = r.text
	}
	// コメントや地の文は 1 行が文の断片になりがちで、文末の句点や文長といった
	// 「文章としての体裁」を問う規則を当てると指摘が誤りだらけになる。
	// 中身の薄さを見る規則だけを残した設定を使う。
	problems, err := c.runTextlint([]string{
		"--config", c.CommentsRC, "--stdin", "--stdin-filename", "comments.md", "--format", "json",
	}, strings.Join(texts, "\n\n"))
	if err != nil && len(problems) == 0 {
		return nil, err
	}
	reported := make([]string, 0, len(problems))
	for _, problem := range problems {
		var paragraph int
		var rest string
		if _, err := fmt.Sscanf(problem, "%d  %s", &paragraph, &rest); err != nil {
			continue
		}
		index := (paragraph - 1) / 2
		origin := paragraph
		if index >= 0 && index < len(rows) {
			origin = rows[index].line
		}
		_, after, _ := strings.Cut(problem, "  ")
		reported = append(reported, fmt.Sprintf("%s:%d  %s", label, origin, after))
	}
	return reported, nil
}

// LintText は文字列を地の文として検査する。
// PR の本文やコミットメッセージのように、ファイルになっていない文章に使う。
func (c Config) LintText(text, label string) ([]string, error) {
	return c.LintRows(extract(text, "", true), label)
}

// LintFile はファイルを検査する。Markdown は本文を、それ以外はコメントだけを見る。
// textlint が見るのは Markdown の本文だけなので、設定リポジトリのように
// 日本語の大半がコメント側にあると、入れただけでは大部分が素通りになる。
func (c Config) LintFile(path string) ([]string, error) {
	extension := filepath.Ext(path)
	if markdownExt[extension] {
		problems, err := c.runTextlint([]string{
			"--config", c.TextlintRC, "--format", "json", path,
		}, "")
		if err != nil && len(problems) == 0 {
			return nil, err
		}
		reported := make([]string, 0, len(problems))
		for _, problem := range problems {
			reported = append(reported, path+":"+problem)
		}
		return reported, nil
	}
	body, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	return c.LintRows(extract(string(body), extension, false), path)
}
