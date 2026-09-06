local M = {}

-- mise の go shim は GOROOT env を無視するため、直接の go binary を PATH 先頭に
-- 置いてから gopls を起動する（gopls 内部の `go env` に TinyGo overlay を反映）。
local go_dir = vim.fs.dirname(vim.trim(vim.fn.system('mise which go')))
local prefix = { 'env', 'PATH=' .. go_dir .. ':' .. vim.env.PATH }
local cmd_lazy = vim.list_extend(vim.deepcopy(prefix), { 'gopls-lazy' })
M.cmd = cmd_lazy

M.settings = {
  gopls = {
    analyses = {
      unusedparams = true,
      shadow = true,
    },
    staticcheck = true,
    gofumpt = true,
    completeUnimported = true,
    semanticTokens = true,
    hints = {
      assignVariableTypes = true,
      compositeLiteralFields = true,
      compositeLiteralTypes = true,
      constantValues = true,
      functionTypeParameters = true,
      parameterNames = true,
      rangeVariableTypes = true,
    },
  }
}

return M
