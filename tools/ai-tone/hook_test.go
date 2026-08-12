package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestCommitMessageOf(t *testing.T) {
	dir := t.TempDir()
	file := filepath.Join(dir, "msg.txt")
	if err := os.WriteFile(file, []byte("fix: 修正\n\n本文\n"), 0o600); err != nil {
		t.Fatal(err)
	}

	tests := []struct {
		name    string
		command string
		want    string
	}{
		{"-F でファイルを渡す", "git commit -F " + file, "fix: 修正\n\n本文\n"},
		{"-m を二重引用符で渡す", `git commit -m "fix: 直す"`, "fix: 直す"},
		{"-m を単一引用符で渡す", `git commit -m 'fix: 直す'`, "fix: 直す"},
		{"-m を 2 つ渡す", `git commit -m "件名" -m "本文"`, "件名\n\n本文"},
		{"ヒアドキュメントで渡す", "git commit -F - <<'MSG'\n件名\n\n本文\nMSG\n", "件名\n\n本文"},
		{"取り出せない形", "git commit --amend --no-edit", ""},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			if got := CommitMessageOf(test.command); got != test.want {
				t.Errorf("got %q, want %q", got, test.want)
			}
		})
	}
}

func TestStripCode(t *testing.T) {
	message := "様々な要因。\n```\n不可欠\n```\n`掘り下げ` は残らない。"
	got := stripCode(message)
	if strings.Contains(got, "不可欠") {
		t.Errorf("フェンスドブロックの中が残っている: %q", got)
	}
	if strings.Contains(got, "掘り下げ") {
		t.Errorf("インラインコードの中が残っている: %q", got)
	}
	if !strings.Contains(got, "様々な") {
		t.Errorf("地の文が消えている: %q", got)
	}
}

func TestExtract(t *testing.T) {
	body := "# 様々な要因がある\nkey: value\n# ascii only\n"
	rows := extract(body, ".yml", false)
	if len(rows) != 1 {
		t.Fatalf("コメント行だけを拾えていない: %+v", rows)
	}
	if rows[0].line != 1 {
		t.Errorf("行番号が元ファイルのものになっていない: %d", rows[0].line)
	}

	prose := extract("様々な要因がある\n\nascii only\n", "", true)
	if len(prose) != 1 {
		t.Fatalf("地の文を拾えていない: %+v", prose)
	}
}

func TestExtractUnquotesJapaneseQuotes(t *testing.T) {
	// 辞書のコメントは検出対象の語を引用して説明するので、
	// 「」で囲んだ語はインラインコード扱いにして検査から外す。
	rows := extract("# 「不可欠」は避ける\n", ".yml", false)
	if len(rows) != 1 || !strings.Contains(rows[0].text, "`不可欠`") {
		t.Errorf("引用がインラインコードになっていない: %+v", rows)
	}
}

func TestRuleSources(t *testing.T) {
	tests := []struct {
		name string
		rule Rule
		want []string
	}{
		{"正規表現リテラル", Rule{Pattern: "/しっかり([^し])/"}, []string{"しっかり([^し])"}},
		{"素の文字列はエスケープする", Rule{Pattern: "a.b"}, []string{`a\.b`}},
		{"patterns を並べる", Rule{Patterns: []string{"様々な", "さまざまな"}}, []string{"様々な", "さまざまな"}},
		{"pattern を省くと expected を使う", Rule{Expected: "不可欠"}, []string{"不可欠"}},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			got := test.rule.sources()
			if strings.Join(got, "|") != strings.Join(test.want, "|") {
				t.Errorf("got %v, want %v", got, test.want)
			}
		})
	}
}

func TestMatcherFindAll(t *testing.T) {
	dir := t.TempDir()
	dict := filepath.Join(dir, "d.yml")
	body := `version: 1
rules:
  - expected: ""
    scope: chat
    patterns:
      - 非常に
  - expected: ""
    patterns:
      - 極めて
`
	if err := os.WriteFile(dict, []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}

	all, skipped, err := LoadMatcher([]string{dict}, false)
	if err != nil || len(skipped) > 0 {
		t.Fatalf("err=%v skipped=%v", err, skipped)
	}
	if got := all.FindAll("非常に極めて", 10); len(got) != 2 {
		t.Errorf("全規則を対象にできていない: %v", got)
	}

	chat, _, err := LoadMatcher([]string{dict}, true)
	if err != nil {
		t.Fatal(err)
	}
	got := chat.FindAll("非常に極めて", 10)
	if len(got) != 1 || got[0] != "非常に" {
		t.Errorf("scope: chat で絞れていない: %v", got)
	}
}

func TestPostedText(t *testing.T) {
	var input HookInput
	input.ToolName = "mcp__github__create_pull_request"
	input.ToolInput.Title = "件名"
	input.ToolInput.Body = "本文"
	text, label := postedText(input)
	if text != "件名\n\n本文" || label == "" {
		t.Errorf("PR の本文を取り出せていない: %q %q", text, label)
	}

	var other HookInput
	other.ToolName = "Bash"
	other.ToolInput.Command = "ls -la"
	if text, _ := postedText(other); text != "" {
		t.Errorf("git commit 以外を拾っている: %q", text)
	}
}
