#!/usr/bin/env node
// 辞書 YAML から ripgrep 用のパターンファイルを生成する。
//
// なぜ必要か: textlint の起動には 1.5 〜 2 秒かかる。Claude Code の Stop フックは
// 毎ターン走るため、そこで textlint を呼ぶと会話のたびに 2 秒待たされる。
// ripgrep なら同じ辞書を数ミリ秒で当てられるので、会話出力の検査だけは
// 生成済みパターンで行う。ファイルへの書き込みは頻度が低いので textlint 本体を使う。
//
// 生成物はビルド成果物だが、フックが npm install 済みでなくても動くようコミットする。
// 辞書と生成物がずれていないかは `npm test` が検証する。

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const yaml = require("js-yaml");

const here = path.dirname(fileURLToPath(import.meta.url));
export const dictDir = path.join(here, "..", "dict");
export const outDir = path.join(dictDir, "generated");

const REGEXP_LITERAL = /^\/(.*)\/([gimy]*)$/;

// ripgrep は Rust の regex クレートを使うので、先読み・後読み・後方参照が無い。
// 該当するパターンは会話チェックから落とす（textlint 側では従来どおり動く）。
const UNSUPPORTED = /\(\?[=!<]/;

const REGEXP_META = /[.*+?^${}()|[\]\\]/g;

// パターンファイルは `rg --file` に直接渡す。ripgrep は行を無条件にパターンとして読むため、
// コメント行と空行を書けない（空行は「すべてに一致する空パターン」になり検査が壊れる）。
// 「自動生成物である」という注記は dict/generated/README.md 側に置いてある。

function toRegexSource(pattern) {
  const literal = String(pattern).match(REGEXP_LITERAL);
  if (literal) return literal[1];
  // 素の文字列は prh 側でもリテラル一致になるため、メタ文字を潰す。
  return String(pattern).replace(REGEXP_META, "\\$&");
}

function patternsOf(rule) {
  const raw = rule.patterns ?? rule.pattern ?? rule.expected;
  return Array.isArray(raw) ? raw : [raw];
}

function collect(file, warn) {
  const doc = yaml.load(fs.readFileSync(path.join(dictDir, file), "utf8"));
  const rows = [];
  for (const rule of doc.rules ?? []) {
    for (const pattern of patternsOf(rule)) {
      if (pattern == null || pattern === "") continue;
      const source = toRegexSource(pattern);
      if (UNSUPPORTED.test(source)) {
        warn(`skip (ripgrep 非対応の構文): ${source}`);
        continue;
      }
      try {
        new RegExp(source);
      } catch (err) {
        warn(`skip (正規表現として不正): ${source} — ${err.message}`);
        continue;
      }
      rows.push({ source, scope: rule.scope ?? "file" });
    }
  }
  return rows;
}

// 辞書からパターンファイルの中身を組み立てる。書き出しはしない。
export function build(warn = console.warn) {
  const rows = [...collect("ai-tone.yml", warn), ...collect("ai-tone-review.yml", warn)];
  const dedupe = (list) => [...new Set(list)];
  const render = (list) => list.join("\n") + "\n";
  return {
    "all.patterns": render(dedupe(rows.map((r) => r.source))),
    // scope: chat を付けたルールだけが会話出力の検査対象になる。
    "chat.patterns": render(dedupe(rows.filter((r) => r.scope === "chat").map((r) => r.source))),
  };
}

const isCli = process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1]);
if (isCli) {
  const files = build();
  fs.mkdirSync(outDir, { recursive: true });
  for (const [name, body] of Object.entries(files)) {
    fs.writeFileSync(path.join(outDir, name), body);
    console.log(`${name}: ${body.trimEnd().split("\n").length} 件`);
  }
}
