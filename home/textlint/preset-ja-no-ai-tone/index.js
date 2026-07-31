"use strict";

const path = require("path");
// textlint-rule-prh は ESM interop の都合で { default: { linter, fixer } } を返す。
const prhModule = require("textlint-rule-prh");
const prh = prhModule.default || prhModule;

const dict = (name) => path.join(__dirname, "dict", name);

// prh を二つのルール ID に分けて登録する。
// ai-tone        … 機械的に直せる規則だけ。--fix を当てても壊れない。
// ai-tone-review … 人間の判断が要る規則。expected は書き直しの方針なので --fix を当てない。
// 一つの辞書にまとめると、自動修正できる規則まで手作業に巻き込まれる。
module.exports = {
  rules: {
    "ai-tone": prh,
    "ai-tone-review": prh,
  },
  rulesConfig: {
    "ai-tone": {
      rulePaths: [dict("ai-tone.yml")],
    },
    "ai-tone-review": {
      rulePaths: [dict("ai-tone-review.yml")],
      severity: "warning",
    },
  },
};
