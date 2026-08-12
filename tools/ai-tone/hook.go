package main

import (
	"encoding/json"
	"io"
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

	// 会話は scope: chat の規則だけを当てる。
	// 短く砕けた文に文書向けの規則をそのまま当てると誤検出が増える。
	chatOnly := input.EventName == "Stop" || input.EventName == "SubagentStop"
	matcher, _, err := LoadMatcher(config.Dicts, chatOnly)
	if err != nil {
		return ""
	}

	switch input.EventName {
	case "Stop", "SubagentStop":
		// 止めた後の書き直しでまた止めると往復が終わらない。二周目は必ず通す。
		if input.StopHookActive || input.LastAssistantOutput == "" {
			return ""
		}
		problems := Scan(matcher, input.LastAssistantOutput, "直前の応答", false)
		if len(problems) == 0 {
			return ""
		}
		return "AI 文体の常套句が含まれている。削るか具体的な語に置き換えて応答し直すこと。\n" +
			joinReport(problems)

	case "PostToolUse":
		if !editTools[input.ToolName] {
			return ""
		}
		path := input.ToolInput.FilePath
		if path == "" {
			path = input.ToolInput.NotebookPath
		}
		problems, err := ScanFile(matcher, path)
		if err != nil || len(problems) == 0 {
			return ""
		}
		return path + " に AI 文体の指摘がある。書き直してから次に進むこと。\n" + joinReport(problems)

	case "PreToolUse":
		if !postsToGitHub.MatchString(input.ToolName) {
			return ""
		}
		text := strings.TrimSpace(input.ToolInput.Title + "\n\n" + input.ToolInput.Body)
		problems := Scan(matcher, text, "投稿しようとしている本文", false)
		if len(problems) == 0 {
			return ""
		}
		return "投稿しようとしている本文に AI 文体の指摘がある。書き直してから投稿すること。\n" +
			joinReport(problems)
	}
	return ""
}

// joinReport は指摘を並べる。長いと後続の判断を圧迫するので先頭だけ渡す。
func joinReport(problems []string) string {
	if len(problems) > maxReportLines {
		problems = problems[:maxReportLines]
	}
	return strings.Join(problems, "\n")
}
