package main

import (
	"encoding/json"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

// HookInput は Claude Code がフックに渡す JSON のうち、使う項目だけ。
type HookInput struct {
	EventName           string `json:"hook_event_name"`
	ToolName            string `json:"tool_name"`
	StopHookActive      bool   `json:"stop_hook_active"`
	LastAssistantOutput string `json:"last_assistant_message"`
	ToolInput           struct {
		FilePath     string `json:"file_path"`
		NotebookPath string `json:"notebook_path"`
		Command      string `json:"command"`
		Title        string `json:"title"`
		Body         string `json:"body"`
	} `json:"tool_input"`
}

const maxReportLines = 20

var editTools = map[string]bool{
	"Write": true, "Edit": true, "MultiEdit": true, "NotebookEdit": true,
}

// GitHub へ投稿する MCP ツール。PR の本文・タイトル、レビュー、コメントを含む。
var postsToGitHub = regexp.MustCompile(`^mcp__github__.*(pull_request|issue|comment|review)`)

var fence = regexp.MustCompile("(?m)^\\s*```")
var inlineCode = regexp.MustCompile("`[^`]*`")

// RunHook は標準入力のフック JSON を読み、指摘があれば理由を返す。
// 指摘が無ければ空文字。呼び出し側は空でなければ stderr に書いて 2 で終わる。
//
// 終了コード 2 は Stop・PostToolUse・PreToolUse のいずれでも
// 「stderr を理由として Claude に渡し、その操作を止める」と決まっている。
// 発火点ごとに違う JSON を組み立てる必要がない。
//
// フックのせいで会話が止まるのは最悪なので、想定外は何も言わずに通す。
func RunHook(config Config, stdin io.Reader) string {
	body, err := io.ReadAll(stdin)
	if err != nil {
		return ""
	}
	var input HookInput
	if err := json.Unmarshal(body, &input); err != nil {
		return ""
	}
	switch input.EventName {
	case "Stop", "SubagentStop":
		return checkChat(config, input)
	case "PostToolUse":
		return checkFile(config, input)
	case "PreToolUse":
		return checkPost(config, input)
	}
	return ""
}

// stripCode はフェンスドブロックとインラインコードを落とす。
// コード中の語は文体の問題ではない。
func stripCode(message string) string {
	var kept []string
	inFence := false
	for _, line := range strings.Split(message, "\n") {
		if fence.MatchString(line) {
			inFence = !inFence
			continue
		}
		if !inFence {
			kept = append(kept, line)
		}
	}
	return inlineCode.ReplaceAllString(strings.Join(kept, "\n"), "")
}

// checkChat は直前の応答本文を検査する。毎ターン走るので textlint は使わず、
// 辞書から組み立てた正規表現を直接当てる。
func checkChat(config Config, input HookInput) string {
	// 止めた後の書き直しでまた止めると往復が終わらない。二周目は必ず通す。
	if input.StopHookActive || input.LastAssistantOutput == "" {
		return ""
	}
	matcher, _, err := LoadMatcher(config.Dicts, true)
	if err != nil {
		return ""
	}
	hits := matcher.FindAll(stripCode(input.LastAssistantOutput), 12)
	if len(hits) == 0 {
		return ""
	}
	return "直前の応答に AI 文体の常套句が含まれている: " + strings.Join(hits, "、") +
		"。これらは削るか、具体的な語に置き換えて応答し直すこと。" +
		"語を消して意味が変わらないなら、その語は不要。"
}

// checkFile は書き込まれたファイルを検査する。
func checkFile(config Config, input HookInput) string {
	if !editTools[input.ToolName] || !config.Ready() {
		return ""
	}
	path := input.ToolInput.FilePath
	if path == "" {
		path = input.ToolInput.NotebookPath
	}
	if path == "" {
		return ""
	}
	if _, err := os.Stat(path); err != nil {
		return ""
	}
	problems, err := config.LintFile(path)
	if err != nil || len(problems) == 0 {
		return ""
	}
	return path + " に AI 文体の指摘がある。指摘箇所を書き直してから次に進むこと。\n" +
		joinReport(problems) +
		"\n機械的に直せるものは `ai-tone fix " + path + "` で片付く。" +
		"残りは指摘文が書き直しの方針を示しているので、それに従って本文を直す。"
}

// postedText は投稿しようとしている文章と、指摘文で使う呼び名を返す。
func postedText(input HookInput) (text, label string) {
	if postsToGitHub.MatchString(input.ToolName) {
		parts := []string{}
		for _, part := range []string{input.ToolInput.Title, input.ToolInput.Body} {
			if part != "" {
				parts = append(parts, part)
			}
		}
		return strings.Join(parts, "\n\n"), "GitHub に投稿しようとしている本文"
	}
	if input.ToolName == "Bash" && strings.Contains(input.ToolInput.Command, "git commit") {
		return CommitMessageOf(input.ToolInput.Command), "コミットメッセージ"
	}
	return "", ""
}

// checkPost は PR の本文やコミットメッセージを送信の直前で検査する。
// リポジトリに残らないので、ファイル書き込みの検査では拾えない。
func checkPost(config Config, input HookInput) string {
	if !config.Ready() {
		return ""
	}
	text, label := postedText(input)
	// 日本語を含まない本文は対象外。英語の PR まで止める理由がない。
	if strings.TrimSpace(text) == "" || !hasJapanese.MatchString(text) {
		return ""
	}
	problems, err := config.LintText(text, "<本文>")
	if err != nil || len(problems) == 0 {
		return ""
	}
	return label + "に AI 文体の指摘がある。書き直してから投稿すること。\n" + joinReport(problems)
}

// joinReport は指摘を並べる。長いと後続の判断を圧迫するので先頭だけ渡す。
func joinReport(problems []string) string {
	if len(problems) > maxReportLines {
		problems = problems[:maxReportLines]
	}
	return strings.Join(problems, "\n")
}

var (
	commitFile     = regexp.MustCompile(`-F\s+(\S+)`)
	commitHeredoc  = regexp.MustCompile(`<<-?\s*['"]?([A-Za-z_][A-Za-z0-9_]*)['"]?\s*\n`)
	commitInlineDQ = regexp.MustCompile(`-m\s+"([^"]*)"`)
	commitInlineSQ = regexp.MustCompile(`-m\s+'([^']*)'`)
)

// CommitMessageOf は git commit の実行コマンドからメッセージ本体を取り出す。
// -F <file> / ヒアドキュメント / -m の 3 通りに対応する。
// 取り出せなければ空を返して黙って通す。
// コミットできなくなるほうが、指摘 1 件の見逃しより困る。
func CommitMessageOf(command string) string {
	if match := commitFile.FindStringSubmatch(command); match != nil && match[1] != "-" {
		if body, err := os.ReadFile(filepath.Clean(match[1])); err == nil {
			return string(body)
		}
	}
	if body := heredocBody(command); body != "" {
		return body
	}
	var messages []string
	for _, pattern := range []*regexp.Regexp{commitInlineDQ, commitInlineSQ} {
		for _, match := range pattern.FindAllStringSubmatch(command, -1) {
			messages = append(messages, match[1])
		}
	}
	return strings.Join(messages, "\n\n")
}

// heredocBody は <<TAG から TAG だけの行までを返す。
func heredocBody(command string) string {
	found := commitHeredoc.FindStringSubmatchIndex(command)
	if found == nil {
		return ""
	}
	tag := command[found[2]:found[3]]
	var body []string
	for _, line := range strings.Split(command[found[1]:], "\n") {
		if strings.TrimSpace(line) == tag {
			return strings.Join(body, "\n")
		}
		body = append(body, line)
	}
	return ""
}
