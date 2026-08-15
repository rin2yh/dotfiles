#!/bin/sh
# 辞書を当てて textlint を呼ぶ。引数はそのまま textlint に渡る。
#
# mise は npm パッケージごとに別の prefix へ入れるため、textlint は隣に置かれた
# ルールを自力では見つけられない。NODE_PATH で場所を渡す。
# ルール名を知っているのはこのファイルだけにする。フック側には持たせない。

set -u

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

NODE_PATH="$(mise where npm:textlint-rule-prh)/lib/node_modules"
NODE_PATH="$NODE_PATH:$(mise where npm:textlint-rule-preset-ja-technical-writing)/lib/node_modules"
export NODE_PATH

exec textlint --config "$DIR/.textlintrc.json" --format compact "$@"
