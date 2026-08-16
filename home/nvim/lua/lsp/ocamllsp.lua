local M = {}

-- ocamllsp は Nix でも mise でもなく dune の dev-tool として
-- `_build/.dev-tools.locks/` 以下に入るため PATH に直接は載らない。`dune tools exec` を
-- 挟むと、未インストールならその場で lock/build してから起動してくれる (初回はビルドを
-- 待たされる)。対象のワークスペースは dune がプロセスの cwd から辿って決めるので、
-- `nvim .` のようにプロジェクトルートで起動している前提。
M.cmd = { 'dune', 'tools', 'exec', 'ocamllsp' }

-- .ml / .mli / .mll / .mly はすべて filetype 'ocaml'（Neovim の filetype.lua）。
-- dune / dune-project / dune-workspace は filetype 'dune' で、ocamllsp が
-- `dune format-dune-file` 相当のフォーマットを提供する。
M.filetypes = { 'ocaml', 'dune' }
M.root_markers = { 'dune-project', 'dune-workspace', '.git' }

-- ocamllsp の設定は didChangeConfiguration の settings 直下に置く（`ocaml` でラップしない）。
-- codelens / inlayHints は vim.lsp.codelens.refresh() / vim.lsp.inlay_hint.enable() を
-- クライアント側で呼んでいないため有効にしても効かないので入れていない。
M.settings = {
  -- K (lsp/init.lua の hover) で doc コメントまで出すために両方必要
  extendedHover = { enable = true },
  syntaxDocumentation = { enable = true },
  -- Merlin のジャンプは <space>w (code_action) 経由でしか呼べない
  merlinJumpCodeActions = { enable = true },
}

-- フォーマットは ocamllsp が ocamlformat を PATH から探して呼ぶ。`dune tools exec` は
-- 全 dev-tool の bin ディレクトリを PATH に足してから exec するので、プロジェクトで
-- 一度 `dune tools install ocamlformat` しておけば <M-f> (vim.lsp.buf.format) が効く。
-- gopls の gofumpt / nixd の nixfmt と同じ扱い。

return M
