package main

import (
	"fmt"
	"os"
	"regexp"
	"strings"

	"gopkg.in/yaml.v3"
)

// Rule は prh の辞書ファイルの 1 規則。必要な項目だけを読む。
// scope は prh が無視する独自キーで、会話出力の検査に含めるかを示す。
type Rule struct {
	Expected string   `yaml:"expected"`
	Pattern  string   `yaml:"pattern"`
	Patterns []string `yaml:"patterns"`
	Scope    string   `yaml:"scope"`
}

type dictFile struct {
	Rules []Rule `yaml:"rules"`
}

// prh は /.../ の形を正規表現リテラルとして扱い、フラグは gimy しか受け付けない。
var regexpLiteral = regexp.MustCompile(`^/(.*)/([gimy]*)$`)

// Matcher は辞書から作った照合器。会話出力の検査に使う。
type Matcher struct {
	patterns []*regexp.Regexp
}

// LoadMatcher は辞書 YAML を読んで照合器を組み立てる。
// chatOnly を立てると scope: chat の規則だけを対象にする。
//
// Go の regexp は RE2 なので、先読みや後方参照を含むパターンは受け付けない。
// prh 側でそういう規則を書くと辞書とフックの網がずれるため、
// ここで弾かれたものは check が指摘する。
func LoadMatcher(paths []string, chatOnly bool) (*Matcher, []string, error) {
	m := &Matcher{}
	var skipped []string
	for _, path := range paths {
		body, err := os.ReadFile(path)
		if err != nil {
			return nil, nil, fmt.Errorf("%s の読み込みに失敗: %w", path, err)
		}
		var doc dictFile
		if err := yaml.Unmarshal(body, &doc); err != nil {
			return nil, nil, fmt.Errorf("%s の解析に失敗: %w", path, err)
		}
		for _, rule := range doc.Rules {
			if chatOnly && rule.Scope != "chat" {
				continue
			}
			for _, source := range rule.sources() {
				compiled, err := regexp.Compile(source)
				if err != nil {
					skipped = append(skipped, fmt.Sprintf("%s: %s（%v）", path, source, err))
					continue
				}
				m.patterns = append(m.patterns, compiled)
			}
		}
	}
	return m, skipped, nil
}

// sources は規則が持つパターンを Go の正規表現の文字列に直す。
func (r Rule) sources() []string {
	raw := r.Patterns
	if len(raw) == 0 && r.Pattern != "" {
		raw = []string{r.Pattern}
	}
	if len(raw) == 0 && r.Expected != "" {
		// prh は pattern を省くと expected 自体を対象にする。
		raw = []string{r.Expected}
	}
	sources := make([]string, 0, len(raw))
	for _, pattern := range raw {
		if literal := regexpLiteral.FindStringSubmatch(pattern); literal != nil {
			sources = append(sources, literal[1])
			continue
		}
		// 素の文字列は prh 側でもリテラル一致になる。
		sources = append(sources, regexp.QuoteMeta(pattern))
	}
	return sources
}

// FindAll は本文に当たった語を、重複を除いて出現順に返す。
func (m *Matcher) FindAll(text string, limit int) []string {
	var hits []string
	seen := map[string]bool{}
	for _, pattern := range m.patterns {
		for _, hit := range pattern.FindAllString(text, -1) {
			hit = strings.TrimSpace(hit)
			if hit == "" || seen[hit] {
				continue
			}
			seen[hit] = true
			hits = append(hits, hit)
			if len(hits) >= limit {
				return hits
			}
		}
	}
	return hits
}
