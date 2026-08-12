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

// Matcher は辞書から作った照合器。
type Matcher struct {
	patterns []pattern
}

// pattern は 1 つの正規表現と、当たったときに出す書き直しの方針。
type pattern struct {
	re     *regexp.Regexp
	advice string
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
				m.patterns = append(m.patterns, pattern{re: compiled, advice: rule.advice()})
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

// advice は指摘文に出す文言。expected が空の規則は削る指示とみなす。
func (r Rule) advice() string {
	if strings.TrimSpace(r.Expected) == "" {
		return "削る"
	}
	return r.Expected
}

// Hit は当たった語と、その書き直しの方針。
type Hit struct {
	Word   string
	Advice string
}

// FindAll は本文に当たった語を、重複を除いて返す。
func (m *Matcher) FindAll(text string, limit int) []Hit {
	var hits []Hit
	seen := map[string]bool{}
	for _, p := range m.patterns {
		for _, word := range p.re.FindAllString(text, -1) {
			word = strings.TrimSpace(word)
			if word == "" || seen[word] {
				continue
			}
			seen[word] = true
			hits = append(hits, Hit{Word: word, Advice: p.advice})
			if len(hits) >= limit {
				return hits
			}
		}
	}
	return hits
}
