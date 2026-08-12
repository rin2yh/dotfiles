"use strict";

const path = require("path");
// textlint-rule-prh は ESM interop の都合で { default: { linter, fixer } } を返す。
const prhModule = require("textlint-rule-prh");
const prh = prhModule.default || prhModule;

const dict = (name) => path.join(__dirname, "dict", name);

// prh を 2 つのルール ID に分けて登録する。
// ai-tone        … 機械的に直せる規則。linter と fixer の両方を登録する。
// ai-tone-review … 人間の判断が要る規則。expected は置換候補ではなく書き直しの方針なので、
//                  linter だけを登録して --fix が構造的に触れないようにしてある。
// 1 つの辞書に混ぜると、自動修正できる規則まで手作業に巻き込まれる。
module.exports = {
  rules: {
    "ai-tone": prh,
    "ai-tone-review": prh.linter,
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
