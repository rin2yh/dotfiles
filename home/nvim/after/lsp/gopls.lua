local M = {}

M.filetypes = { 'go', 'gomod' }

-- golance は `go list` を使うため、Go と golance の実体を PATH shim 経由にしない。
local function mise_which(tool)
  local path = vim.trim(vim.fn.system({ 'mise', 'which', tool }))
  if vim.v.shell_error == 0 and path ~= '' then return path end
  return vim.fn.exepath(tool)
end

local go_bin = mise_which('go')
local golance_bin = mise_which('golance')
local go_dir = go_bin ~= '' and vim.fs.dirname(go_bin) or ''
local path = go_dir ~= '' and (go_dir .. ':' .. vim.env.PATH) or vim.env.PATH
M.cmd = { 'env', 'PATH=' .. path, golance_bin ~= '' and golance_bin or 'golance' }

M.init_options = {
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

return M
