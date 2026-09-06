local M = {}

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
    inlayHints = inlayHints,
    tsserver = {
      path = "", -- 空文字列でnode_modules内のtypescriptを自動検出
    },
  },
  javascript = {
    inlayHints = inlayHints
  }
}

return M
