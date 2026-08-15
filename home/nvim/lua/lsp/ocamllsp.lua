local M = {}

-- ocamllsp は Nix でも mise でもなく opam switch の中に入るため PATH に直接は載らない。
-- `opam exec --` を挟んで switch を解決してから起動する。switch はプロセスの cwd から
-- 決まるので、`nvim .` のようにプロジェクトルートで起動している前提。
M.cmd = { 'opam', 'exec', '--', 'ocamllsp' }

-- .ml / .mli / .mll / .mly はすべて filetype 'ocaml'（Neovim の filetype.lua）。
-- dune / dune-project / dune-workspace は filetype 'dune' で、ocamllsp が
-- `dune format-dune-file` 相当のフォーマットを提供する。
M.filetypes = { 'ocaml', 'dune' }
M.root_markers = { 'dune-project', 'dune-workspace', '.git' }

-- ocamllsp の設定は didChangeConfiguration の settings 直下に置く（`ocaml` でラップしない）。
-- codelens / inlayHints は vim.lsp.codelens.refresh() / vim.lsp.inlay_hint.enable() を
-- クライアント側で呼んでいないため有効にしても効かないので入れていない。
M.settings = {
  -- 型に加えて doc コメントもホバーに出す（K にバインド済み）
  extendedHover = { enable = true },
  syntaxDocumentation = { enable = true },
  -- 定義・実装への移動を code action として出す（<space>w にバインド済み）
  merlinJumpCodeActions = { enable = true },
}

-- フォーマットは ocamllsp が switch 内の ocamlformat を呼ぶため、<M-f>
-- (vim.lsp.buf.format) がそのまま効く。gopls の gofumpt / nixd の nixfmt と同じ扱い。

return M
