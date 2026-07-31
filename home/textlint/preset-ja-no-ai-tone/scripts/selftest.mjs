#!/usr/bin/env node
// 辞書の回帰テスト。辞書を更新したら必ずこれを通してからコミットする。
//
// 検証するのは三つ。
//   1. prh が両方の辞書をロードできること。prh は specs が一つでも外れるとロードに失敗するので、
//      これだけで「書いたつもりのパターンが実際にマッチするか」が確かめられる。
//   2. コミットされたパターンファイルが辞書と一致すること。ずれるとフックだけが古い規則で動く。
//   3. パターンが ripgrep でも実際にコンパイルできること。JS の正規表現として妥当でも
//      Rust の regex では通らない構文があるため、フックが黙って壊れるのを防ぐ。

import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { createRequire } from "node:module";
import { build, dictDir, outDir } from "./gen-patterns.mjs";

const require = createRequire(import.meta.url);

const failures = [];
const fail = (msg) => failures.push(msg);
const ok = (msg) => console.log(`  ok  ${msg}`);

console.log("1. prh が辞書をロードできるか（specs の検証を兼ねる）");
{
  const prh = require("prh");
  for (const file of ["ai-tone.yml", "ai-tone-review.yml"]) {
    try {
      const config = prh.fromYAMLFilePath(path.join(dictDir, file));
      ok(`${file} — ${config.rules.length} 規則`);
    } catch (err) {
      fail(`${file} のロードに失敗: ${err.message}`);
    }
  }
}

console.log("2. 生成済みパターンが辞書と一致するか");
{
  const expected = build(() => {});
  for (const [name, body] of Object.entries(expected)) {
    const file = path.join(outDir, name);
    const actual = fs.existsSync(file) ? fs.readFileSync(file, "utf8") : null;
    if (actual === body) {
      ok(name);
    } else {
      fail(`${name} が辞書と食い違っている。\`npm run gen\` を実行してコミットすること`);
    }
  }
}

console.log("3. パターンが ripgrep でコンパイルできるか");
{
  const probe = spawnSync("rg", ["--version"], { encoding: "utf8" });
  if (probe.status !== 0) {
    console.log("  skip  ripgrep が見つからないため省略");
  } else {
    const file = path.join(outDir, "all.patterns");
    const patterns = fs.readFileSync(file, "utf8").split("\n").filter(Boolean);
    // 空行が一行でも混ざると「すべてに一致する空パターン」になり、検査が実質無効化される。
    if (fs.readFileSync(file, "utf8").split("\n").slice(0, -1).some((line) => line === "")) {
      fail("all.patterns に空行が混ざっている。空パターンは全行に一致してフックを壊す");
    }
    for (const pattern of patterns) {
      const result = spawnSync("rg", ["--quiet", "--regexp", pattern, "--", "-"], {
        input: "",
        encoding: "utf8",
      });
      // 一致なしは終了コード 1、正規表現が不正なら 2。
      if (result.status === 2) {
        fail(`ripgrep がパターンを拒否: ${pattern} — ${result.stderr.trim().split("\n")[0]}`);
      }
    }
    ok(`${patterns.length} 件すべてコンパイル可能`);
  }
}

if (failures.length > 0) {
  console.error("\n失敗:");
  for (const message of failures) console.error(`  - ${message}`);
  process.exit(1);
}
console.log("\nすべて通過");
