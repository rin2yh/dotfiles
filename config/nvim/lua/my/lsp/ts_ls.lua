local M = {}

M.cmd = { 'typescript-language-server', '--stdio' }
M.filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' }

local inlayHints = {
  includeInlayParameterNameHints = 'all',
  includeInlayParameterNameHintsWhenArgumentMatchesName = false,
  includeInlayFunctionParameterTypeHints = true,
  includeInlayVariableTypeHints = true,
  includeInlayPropertyDeclarationTypeHints = true,
  includeInlayFunctionLikeReturnTypeHints = true,
  includeInlayEnumMemberValueHints = true,
}

M.settings = {
  typescript = {
    inlayHints = inlayHints
  },
  javascript = {
    inlayHints = inlayHints
  }
}

return M
