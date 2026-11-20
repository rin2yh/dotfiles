#!/usr/bin/env zsh
# 2つのチェックアウトについて、対話zshが最初に入力されたコマンドを実行するまでの時間を比較し、
# 結果をMarkdownで出力する。/etc と $HOME を書き換えるので、使い捨てのmacOS CIランナー専用。
#
#   bench.zsh <base-dir> <head-dir> [rounds]

emulate -L zsh
setopt err_exit pipe_fail
zmodload zsh/zpty zsh/datetime

typeset -A dirs=(base ${${1:?base dir}:A} head ${${2:?head dir}:A})
rounds=${3:-15}

state=${RUNNER_TEMP:-/tmp}/zsh-startup-bench
mkdir -p $state

read -r user dotfiles_dir <<< "$(
  nix eval --raw --file $dirs[head]/machine.nix --apply 'm: "${m.username} ${m.dotfilesDir}"'
)"

# ログインシェル: Ghosttyのタブと同じ条件（SHLVL=1 になり fastfetch も実行される）
# サブシェル: nvimのターミナルなど
typeset -A shells=(
  login 'env TERM=xterm-256color SHLVL=0 zsh -il'
  sub 'env TERM=xterm-256color SHLVL=1 zsh -i'
)
metrics=(login sub)
typeset -A labels=(
  login 'ログインシェル（Ghosttyのタブ相当）'
  sub 'サブシェル（nvimのターミナルなど）'
)

# base と head の system / home-files を1回の評価でまとめてビルドする
print -u2 '==> build'
out=$(
  nix build --no-link --print-out-paths \
    "$dirs[base]#darwinConfigurations.default.system" \
    "$dirs[base]#darwinConfigurations.default.config.home-manager.users.$user.home-files" \
    "$dirs[head]#darwinConfigurations.default.system" \
    "$dirs[head]#darwinConfigurations.default.config.home-manager.users.$user.home-files"
)
paths=(${(f)out})
(( $#paths == 4 )) || { print -u2 "unexpected build outputs: $paths"; exit 1 }
typeset -A sys=(base $paths[1] head $paths[3]) home=(base $paths[2] head $paths[4])

current=
activate() {
  local name=$1 f target
  for f in zshenv zprofile zshrc; do
    sudo cp -fL $sys[$name]/etc/$f /etc/$f
  done
  sudo mkdir -p /etc/profiles/per-user ${dotfiles_dir:h}
  sudo ln -sfn ${sys[$name]:A}/etc/profiles/per-user/$user /etc/profiles/per-user/$USER
  sudo ln -sfn $dirs[$name] $dotfiles_dir
  # home-manager が張るリンクをすべて再現する
  for f in ${home[$name]:?}/**/*(D@); do
    target=$HOME/${f#$home[$name]/}
    mkdir -p ${target:h}
    rm -rf -- $target
    ln -s $f $target
  done
  # 補完のダンプは設定ごとに分けて持つ
  if [[ -n $current && -e $HOME/.zcompdump ]]; then
    mv -f $HOME/.zcompdump $state/$current.zcompdump
  fi
  if [[ -e $state/$name.zcompdump ]]; then
    mv -f $state/$name.zcompdump $HOME/.zcompdump
  fi
  current=$name
}

measure() {
  local t0=$EPOCHREALTIME out
  zpty bench "$1"
  zpty -w bench 'print -r -- READY$((40+2))'
  zpty -r bench out '*READY42*'
  zpty -d bench
  print -- $(( (EPOCHREALTIME - t0) * 1000 ))
}

median() {
  local -a v=(${(on)=1})
  print -- ${v[(( ($#v + 1) / 2 ))]}
}

# ラウンド0はウォームアップとして捨てる
typeset -A samples
for i in {0..$rounds}; do
  print -u2 "==> round $i/$rounds"
  for name in base head; do
    activate $name
    for m in $metrics; do
      t=$(measure $shells[$m])
      if (( i > 0 )); then
        samples[$name:$m]+=" $t"
      fi
    done
  done
done

print -- '### zsh 起動時間'
print
print -- "コマンド入力を受け付けるまでの時間（${rounds}回の中央値）"
print
print -- '| シェル | base | PR | 差分 |'
print -- '|---|---:|---:|---:|'
for m in $metrics; do
  b=$(median $samples[base:$m])
  h=$(median $samples[head:$m])
  d=$(( h - b ))
  printf '| %s | %.0f ms | %.0f ms | %+.0f ms (%+.1f%%) |\n' $labels[$m] $b $h $d $(( d * 100.0 / b ))
done
print
print -- "CIランナーでの計測値なので、実機の値とは異なる。base: \`$(git -C $dirs[base] rev-parse --short HEAD)\`"
