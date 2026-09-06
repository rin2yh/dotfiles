local M = {}

-- ocamllsp は dune の dev-tool として `_build/` 以下に入るため PATH に載らない。
-- ワークスペースは cwd から解決されるので `nvim .` で開いている前提。
M.cmd = { 'dune', 'tools', 'exec', 'ocamllsp' }

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

-- <M-f> (vim.lsp.buf.format) は ocamllsp が PATH 上の ocamlformat を呼ぶ。dune tools exec
-- が dev-tool の bin を PATH に足すため `dune tools install ocamlformat` 済みなら効く。

return M
