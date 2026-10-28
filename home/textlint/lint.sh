#!/bin/sh
# 辞書を当てて textlint を呼ぶ。引数はそのまま textlint に渡る。
#
# mise は npm パッケージごとに別の prefix へ入れるため、textlint は隣に置かれた
# ルールを自力では見つけられない。NODE_PATH で場所を渡す。
# 置き場所は入れた時期で違う。古いものは <prefix>/lib/node_modules、
# 新しいものは <prefix>/node_modules に入るので、両方を渡す。
# ルール名を知っているのはこのファイルだけにする。フック側には持たせない。

set -u

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

NODE_PATH=
for pkg in textlint-rule-prh textlint-rule-preset-ja-technical-writing; do
  prefix=$(mise where "npm:$pkg")
  NODE_PATH="${NODE_PATH:+$NODE_PATH:}$prefix/lib/node_modules:$prefix/node_modules"
done
export NODE_PATH

exec textlint --config "$DIR/.textlintrc.json" --format compact "$@"
