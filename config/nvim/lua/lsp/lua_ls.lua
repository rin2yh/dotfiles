local M = {}

M.cmd = { 'lua-language-server' }
M.filetypes = { 'lua' }

M.settings = {
  Lua = {
    runtime = {
      version = 'LuaJIT'
    },
    diagnostics = {
      globals = { 'vim' },
      -- 未使用変数は冒頭に`_`をつけていれば警告なし
      unusedLocalExclude = { '_*' }
    },
    workspace = {
        checkThirdParty = false,
        library = vim.api.nvim_get_runtime_file('lua', true)
      }
  }
}

return M
