#!/usr/bin/env zsh
# 2つのチェックアウトについて、対話zshが最初に入力されたコマンドを実行するまでの時間を比較し、
# 結果をMarkdownで出力する。/etc と $HOME を書き換えるので、使い捨てのmacOS CIランナー専用。
#
#   bench.zsh <base-dir> <head-dir> [rounds]

emulate -L zsh
setopt err_exit pipe_fail
zmodload zsh/zpty zsh/datetime

base_dir=${1:?base dir}
head_dir=${2:?head dir}
rounds=${3:-15}
typeset -A dirs=(base ${base_dir:A} head ${head_dir:A})

state=${RUNNER_TEMP:-/tmp}/zsh-startup-bench
mkdir -p $state

user=$(nix eval --raw --file $dirs[head]/machine.nix username)
dotfiles_dir=$(nix eval --raw --file $dirs[head]/machine.nix dotfilesDir)

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

build() {
  local name=$1 dir=$2
  print -u2 "==> build $name"
  nix build "$dir#darwinConfigurations.default.system" --out-link $state/$name-system
  nix build "$dir#darwinConfigurations.default.config.home-manager.users.$user.home-files" \
    --out-link $state/$name-home
}

current=
activate() {
  local name=$1 dir=$2 sys=$state/$1-system home=$state/$1-home f
  for f in zshenv zprofile zshrc; do
    sudo cp -fL $sys/etc/$f /etc/$f
  done
  sudo mkdir -p /etc/profiles/per-user ${dotfiles_dir:h}
  sudo ln -sfn ${sys:A}/etc/profiles/per-user/$user /etc/profiles/per-user/$USER
  sudo ln -sfn $dir $dotfiles_dir
  mkdir -p $HOME/.config
  for f in .zshrc .zprofile .config/fastfetch .config/starship.toml .config/mise; do
    rm -rf -- $HOME/$f
    ln -s $home/$f $HOME/$f
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

build base $dirs[base]
build head $dirs[head]

typeset -A samples
for name in base head; do
  activate $name $dirs[$name]
  for m in $metrics; do
    repeat 3 measure $shells[$m] >/dev/null
  done
done

for i in {1..$rounds}; do
  print -u2 "==> round $i/$rounds"
  for name in base head; do
    activate $name $dirs[$name]
    for m in $metrics; do
      samples[$name:$m]+=" $(measure $shells[$m])"
    done
  done
done

print -- '<!-- zsh-startup-bench -->'
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
