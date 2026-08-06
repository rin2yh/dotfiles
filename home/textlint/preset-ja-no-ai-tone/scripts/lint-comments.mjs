#!/usr/bin/env node
// Markdown 以外のファイルに書かれた日本語コメントを textlint にかける。
//
// なぜ必要か: textlint が見るのは Markdown の本文だけで、YAML・シェル・JS のコメントは
// 対象外になる。設定リポジトリでは日本語の大半がコメント側にあり、
// このプリセットを入れても書いた文章の大部分が素通りしていた。
// 実際、このプリセットを追加した変更自体が 22 ファイル中 17 ファイルを検査できていなかった。
//
// コメント行だけを抜き出して疑似 Markdown に組み直し、textlint の --stdin に渡す。
// 行番号は元ファイルのものに戻して報告する。
//
//   node scripts/lint-comments.mjs <file>...
//
// 検査には .textlintrc.comments.json を使う。コメントは 1 行が文の断片になりがちで、
// 文末の句点や文長といった「文章としての体裁」を問う規則を当てると指摘が誤りだらけになる。
// 中身の薄さを見る規則（AI 文体・助詞の重複・表記）だけを残してある。
//
// 「」で囲んだ語はインラインコードに変換してから渡す。辞書のコメントは
// 検出対象の語を「不可欠」のように引用して説明するので、そのまま当てると
// 自分自身を指摘し続けることになる。Markdown 側でバッククォートを使うのと同じ扱いにしている。

import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const textlintDir = path.join(here, "..", "..");

// 拡張子ごとの行コメント記号。ブロックコメントは扱わない
// （この構成では使っておらず、対応すると誤爆のほうが増える）。
const LINE_COMMENT = {
  ".yml": "#",
  ".yaml": "#",
  ".sh": "#",
  ".bash": "#",
  ".nix": "#",
  ".toml": "#",
  ".txt": "#",
  ".js": "//",
  ".mjs": "//",
  ".cjs": "//",
  ".ts": "//",
  ".lua": "--",
};

const HAS_JAPANESE = /[ぁ-んァ-ヶ一-龠]/;

// 引用された語は検査対象から外す（Markdown のインラインコードと同じ扱い）。
const unquote = (text) => text.replace(/「([^」]{1,40})」/g, "`$1`");

function commentsOf(file, prose) {
  const rows = [];
  const lines = fs.readFileSync(file, "utf8").split("\n");
  // --prose はファイル全体を地の文として扱う。PR の本文やコミットメッセージのように、
  // リポジトリに残らないぶん検査から漏れやすい文章を通すための入口。
  const marker = prose ? null : LINE_COMMENT[path.extname(file)];
  if (!prose && !marker) return [];
  lines.forEach((line, index) => {
    const trimmed = line.trim();
    let text = trimmed;
    if (marker) {
      if (!trimmed.startsWith(marker)) return;
      text = trimmed.slice(marker.length).trim();
    }
    if (!text || !HAS_JAPANESE.test(text)) return;
    rows.push({ line: index + 1, text: unquote(text) });
  });
  return rows;
}

const args = process.argv.slice(2);
const prose = args.includes("--prose");
const files = args.filter((a) => a !== "--prose");
if (files.length === 0) {
  console.error("使い方: node scripts/lint-comments.mjs [--prose] <file>...");
  process.exit(2);
}

let problems = 0;
for (const file of files) {
  const rows = commentsOf(file, prose);
  if (rows.length === 0) continue;

  // 1 コメント行 = 1 段落にする。連結すると textlint が別の行をつないで
  // 文とみなし、助詞の重複などを誤検出する。
  const doc = rows.map((r) => r.text).join("\n\n");
  const result = spawnSync(
    path.join(textlintDir, "node_modules", ".bin", "textlint"),
    ["--config", path.join(textlintDir, ".textlintrc.comments.json"), "--stdin",
     "--stdin-filename", "comments.md", "--format", "json"],
    { input: doc, encoding: "utf8" },
  );

  let messages = [];
  try {
    messages = JSON.parse(result.stdout)[0]?.messages ?? [];
  } catch {
    continue;
  }
  for (const message of messages) {
    // 疑似 Markdown の段落番号から元ファイルの行番号へ戻す。
    const paragraph = Math.floor((message.line - 1) / 2);
    const origin = rows[paragraph]?.line ?? message.line;
    const text = message.message.split("\n")[0];
    console.log(`${file}:${origin}  ${text}  (${message.ruleId})`);
    problems += 1;
  }
}

if (problems > 0) {
  console.log(`\n${problems} problems`);
  process.exit(1);
}
