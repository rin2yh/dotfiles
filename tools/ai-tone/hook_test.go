package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func testMatcher(t *testing.T) *Matcher {
	t.Helper()
	dir := t.TempDir()
	dict := filepath.Join(dir, "d.yml")
	body := `version: 1
rules:
  - expected: ""
    scope: chat
    patterns:
      - 非常に
  - expected: 数を書くか列挙する
    patterns:
      - 様々な
`
	if err := os.WriteFile(dict, []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
	matcher, skipped, err := LoadMatcher([]string{dict}, false)
	if err != nil || len(skipped) > 0 {
		t.Fatalf("err=%v skipped=%v", err, skipped)
	}
	return matcher
}

func TestScanSkipsCode(t *testing.T) {
	matcher := testMatcher(t)
	body := "様々な要因。\n```\n非常に\n```\n`様々な` は引用。\n「非常に」も引用。"
	got := strings.Join(Scan(matcher, body, "x", false), "\n")
	if strings.Contains(got, ":3") {
		t.Errorf("フェンスドブロックの中を拾っている: %q", got)
	}
	if strings.Contains(got, ":5") || strings.Contains(got, ":6") {
		t.Errorf("インラインコードか引用を拾っている: %q", got)
	}
	if !strings.Contains(got, "x:1  様々な => 数を書くか列挙する") {
		t.Errorf("地の文を拾えていない: %q", got)
	}
}

func TestScanCommentsOnly(t *testing.T) {
	matcher := testMatcher(t)
	body := "# 様々な要因がある\nkey: 様々な\n"
	got := Scan(matcher, body, "x.yml", true)
	if len(got) != 1 || !strings.Contains(got[0], "x.yml:1") {
		t.Errorf("コメント行だけを拾えていない: %v", got)
	}
}

func TestAdviceForEmptyExpected(t *testing.T) {
	// expected が空の規則は削る指示として読ませる。
	matcher := testMatcher(t)
	got := Scan(matcher, "非常に重い", "x", false)
	if len(got) != 1 || !strings.HasSuffix(got[0], "非常に => 削る") {
		t.Errorf("削る指示になっていない: %v", got)
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
			if got := strings.Join(test.rule.sources(), "|"); got != strings.Join(test.want, "|") {
				t.Errorf("got %v, want %v", got, test.want)
			}
		})
	}
}

func TestLoadMatcherChatScope(t *testing.T) {
	dir := t.TempDir()
	dict := filepath.Join(dir, "d.yml")
	body := "version: 1\nrules:\n  - expected: \"\"\n    scope: chat\n    patterns:\n      - 非常に\n  - expected: \"\"\n    patterns:\n      - 極めて\n"
	if err := os.WriteFile(dict, []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
	chat, _, err := LoadMatcher([]string{dict}, true)
	if err != nil {
		t.Fatal(err)
	}
	hits := chat.FindAll("非常に極めて", 10)
	if len(hits) != 1 || hits[0].Word != "非常に" {
		t.Errorf("scope: chat で絞れていない: %v", hits)
	}
}
