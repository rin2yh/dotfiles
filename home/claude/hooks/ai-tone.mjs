#!/usr/bin/env node
// AI っぽい日本語表現を検出する Claude Code フックの本体。
// 起動は ai-tone.sh が担い、ここには処理だけを置く。
//
// 発火点ごとに手段を変えている理由:
//   Stop        … 毎ターン走るので速度が要る。生成済みパターンを ripgrep で当てる（数 ms）。
//                 会話は短く砕けているため誤検出しやすく、既定は警告のみ。
//   PostToolUse … Markdown やコメントを書いた直後だけ走る。頻度が低いので textlint 本体を使い、
//                 preset-ja-technical-writing の検査も含めて既定でブロックする。
//   PreToolUse  … PR の本文・レビュー・コミットメッセージのように、
//                 リポジトリに残らないので他のどの経路でも拾えない文章を投稿の直前で止める。
//                 「書いたら検査する」を記憶に任せると必ず飛ばすため、送信口に置いた。
//
// 強度は環境変数で変えられる。記事を書くセッションだけ会話も止めたい、
// といった切り替えを設定ファイルの編集なしで行えるようにしてある。
//   CLAUDE_AI_TONE_CHAT=off|warn|block   （既定: warn）
//   CLAUDE_AI_TONE_FILE=off|warn|block   （既定: block）
//   CLAUDE_AI_TONE_POST=off|warn|block   （既定: block）
//   CLAUDE_AI_TONE_DIR                   （既定は ~/workspace/dotfiles/home/textlint）

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";

const TEXTLINT_DIR =
  process.env.CLAUDE_AI_TONE_DIR || path.join(os.homedir(), "workspace/dotfiles/home/textlint");
const PATTERN_DIR = path.join(TEXTLINT_DIR, "preset-ja-no-ai-tone/dict/generated");
const LINT_COMMENTS = path.join(TEXTLINT_DIR, "preset-ja-no-ai-tone/scripts/lint-comments.mjs");
const TEXTLINT_BIN = path.join(TEXTLINT_DIR, "node_modules/.bin/textlint");

const mode = (name, fallback) => process.env[name] || fallback;
const CHAT_MODE = mode("CLAUDE_AI_TONE_CHAT", "warn");
const FILE_MODE = mode("CLAUDE_AI_TONE_FILE", "block");
const POST_MODE = mode("CLAUDE_AI_TONE_POST", "block");

const HAS_JAPANESE = /[ぁ-んァ-ヶ一-龠]/;

// フックのせいで会話が止まるのは最悪なので、迷ったら何もせず通す。
const pass = () => process.exit(0);
const emit = (payload) => {
  process.stdout.write(`${JSON.stringify(payload)}\n`);
  process.exit(0);
};

function readStdin() {
  try {
    return JSON.parse(fs.readFileSync(0, "utf8"));
  } catch {
    return null;
  }
}

// --------------------------------------------------------------------
// Stop: 直前の応答本文を検査する
// --------------------------------------------------------------------
function checkChat(input) {
  if (CHAT_MODE === "off") pass();
  const patterns = path.join(PATTERN_DIR, "chat.patterns");
  if (!fs.existsSync(patterns)) pass();
  // ブロック後の書き直しでまた止めると往復が終わらない。二周目は必ず通す。
  if (input.stop_hook_active) pass();

  const message = input.last_assistant_message || "";
  if (!message) pass();

  // コード中の語は文体の問題ではないので、フェンスドブロックとインラインコードを落とす。
  let fenced = false;
  const prose = message
    .split("\n")
    .filter((line) => {
      if (/^\s*```/.test(line)) {
        fenced = !fenced;
        return false;
      }
      return !fenced;
    })
    .join("\n")
    .replace(/`[^`]*`/g, "");

  const result = spawnSync(
    "rg",
    ["--only-matching", "--no-filename", "--no-line-number", "--file", patterns],
    { input: prose, encoding: "utf8" },
  );
  if (result.error || !result.stdout) pass();

  const hits = [...new Set(result.stdout.split("\n").filter(Boolean))].slice(0, 12);
  if (hits.length === 0) pass();
  const list = hits.join("、");

  if (CHAT_MODE === "block") {
    emit({
      decision: "block",
      reason:
        `直前の応答に AI 文体の常套句が含まれている: ${list}。` +
        "これらは削るか、具体的な語に置き換えて応答し直すこと。" +
        "語を消して意味が変わらないなら、その語は不要。",
    });
  }
  emit({ systemMessage: `AI っぽい語: ${list}` });
}

// --------------------------------------------------------------------
// PostToolUse: 書き込まれたファイルを検査する
// --------------------------------------------------------------------
const MARKDOWN = new Set([".md", ".mdx", ".markdown"]);
const WITH_COMMENTS = new Set([
  ".yml", ".yaml", ".sh", ".bash", ".nix", ".toml", ".js", ".mjs", ".cjs", ".ts", ".lua",
]);

async function checkFile(input) {
  if (FILE_MODE === "off") pass();
  if (!["Write", "Edit", "MultiEdit", "NotebookEdit"].includes(input.tool_name)) pass();

  const file = input.tool_input?.file_path || input.tool_input?.notebook_path || "";
  if (!file || !fs.existsSync(file)) pass();
  if (!fs.existsSync(TEXTLINT_BIN)) pass();

  // Markdown は本文を、それ以外はコメントだけを検査する。
  // textlint が見るのは Markdown の本文だけなので、設定リポジトリのように
  // 日本語の大半がコメント側にあると、入れただけでは大部分が素通りになる。
  const extension = path.extname(file);
  let report;
  if (MARKDOWN.has(extension)) {
    const result = spawnSync(
      TEXTLINT_BIN,
      ["--config", path.join(TEXTLINT_DIR, ".textlintrc.json"), "--format", "compact", file],
      { encoding: "utf8" },
    );
    report = (result.stdout || "").trim();
  } else if (WITH_COMMENTS.has(extension)) {
    const { lintFile } = await import(LINT_COMMENTS);
    report = lintFile(file).join("\n");
  } else {
    pass();
  }
  if (!report) pass();

  // 出力が長いと後続の判断を圧迫するので、先頭 20 件だけ渡す。
  report = report.split("\n").slice(0, 20).join("\n");

  if (FILE_MODE === "block") {
    emit({
      decision: "block",
      reason:
        `${file} に AI 文体の指摘がある。指摘箇所を書き直してから次に進むこと。\n${report}\n` +
        "機械的に直せるものは `npm --prefix ~/workspace/dotfiles/home/textlint run fix -- " +
        `${file}\` で片付く。残りは指摘文が書き直しの方針を示しているので、それに従って本文を直す。`,
    });
  }
  emit({
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: `AI 文体の指摘:\n${report}`,
    },
  });
}

// --------------------------------------------------------------------
// PreToolUse: 投稿しようとしている文章を送信の直前で検査する
// --------------------------------------------------------------------

// git commit の実行コマンドからメッセージ本体を取り出す。
// -F <file> / ヒアドキュメント / -m の 3 通りに対応する。
// 取り出せなければ空を返し、フックは黙って通す。
// コミットできなくなるほうが、指摘を 1 件見逃すより困る。
export function commitMessageOf(command) {
  const file = command.match(/-F\s+(\S+)/)?.[1];
  if (file && file !== "-" && fs.existsSync(file)) {
    return fs.readFileSync(file, "utf8");
  }
  const heredoc = command.match(/<<-?\s*['"]?([A-Za-z_][A-Za-z0-9_]*)['"]?\s*\n([\s\S]*?)\n\1\b/);
  if (heredoc) return heredoc[2];
  const inline = [...command.matchAll(/-m\s+(['"])([\s\S]*?)\1/g)].map((m) => m[2]);
  return inline.join("\n\n");
}

// GitHub へ投稿する MCP ツール。PR の本文・タイトル、レビュー、コメントを含む。
const POSTS_TO_GITHUB = /^mcp__github__.*(pull_request|issue|comment|review)/;

async function checkPost(input) {
  if (POST_MODE === "off") pass();
  if (!fs.existsSync(TEXTLINT_BIN)) pass();

  let text = "";
  let label = "";
  if (POSTS_TO_GITHUB.test(input.tool_name || "")) {
    const { title = "", body = "" } = input.tool_input ?? {};
    text = [title, body].filter(Boolean).join("\n\n");
    label = "GitHub に投稿しようとしている本文";
  } else if (input.tool_name === "Bash") {
    const command = input.tool_input?.command || "";
    if (!command.includes("git commit")) pass();
    text = commitMessageOf(command);
    label = "コミットメッセージ";
  } else {
    pass();
  }

  // 日本語を含まない本文は対象外。英語の PR まで止める理由がない。
  if (!text.trim() || !HAS_JAPANESE.test(text)) pass();

  const { lintText } = await import(LINT_COMMENTS);
  const problems = lintText(text).slice(0, 20);
  if (problems.length === 0) pass();
  const report = problems.join("\n");

  if (POST_MODE === "block") {
    emit({
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason:
          `${label}に AI 文体の指摘がある。書き直してから投稿すること。\n${report}`,
      },
    });
  }
  emit({ systemMessage: `${label}の指摘:\n${report}` });
}

const input = readStdin();
if (!input) pass();
switch (input.hook_event_name) {
  case "Stop":
  case "SubagentStop":
    checkChat(input);
    break;
  case "PostToolUse":
    await checkFile(input);
    break;
  case "PreToolUse":
    await checkPost(input);
    break;
  default:
    pass();
}
