local M = {}

-- mise の go shim は GOROOT env を無視するため、直接の go binary を PATH 先頭に
-- 置いてから gopls を起動する（gopls 内部の `go env` に TinyGo overlay を反映）。
local go_dir = vim.fs.dirname(vim.trim(vim.fn.system('mise which go')))
M.cmd = { 'env', 'PATH=' .. go_dir .. ':' .. vim.env.PATH, 'gopls' }
M.filetypes = { 'go', 'gomod'}
M.root_markers = { 'go.mod' }

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

-- TinyGo 用の target 切替。sago35 さんの tinygo.vim が `:TinygoTarget <target>`
-- で GOROOT/GOOS/GOARCH/GOFLAGS を LSP config に流し込むが、Neovim native LSP
-- 分岐で edit を叩かないため、FileType 再発火で gopls を再 attach させる
-- ラッパー `:Tinygo` を用意する。
vim.pack.add({ 'https://github.com/sago35/tinygo.vim' })

vim.api.nvim_create_user_command('Tinygo', function(opts)
  vim.cmd.TinygoTarget(opts.args)
  local buf = vim.api.nvim_get_current_buf()
  vim.schedule(function()
    vim.api.nvim_exec_autocmds('FileType', { buffer = buf })
  end)
end, {
  nargs = 1,
  complete = function(arglead) return vim.fn['tinygo#TinygoTargets'](arglead, '', 0) end,
})

-- Go バッファを開いた時、上位に .tinygo.json があれば自動で :Tinygo を叩く。
-- 同一ファイル + 同一 target は 1 セッション 1 回だけ。
local tinygo_applied = {}
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'go',
  group = vim.api.nvim_create_augroup('tinygo-auto', {}),
  callback = function(args)
    local search = vim.fs.dirname(vim.api.nvim_buf_get_name(args.buf))
    local found = vim.fs.find({ '.tinygo.json' }, { upward = true, path = search })
    if vim.tbl_isempty(found) then return end
    local f = io.open(found[1], 'r')
    if not f then return end
    local raw = f:read('a')
    f:close()
    local ok, cfg = pcall(vim.json.decode, raw)
    if not ok or type(cfg) ~= 'table' or cfg.target == nil then return end
    if tinygo_applied[found[1]] == cfg.target then return end
    tinygo_applied[found[1]] = cfg.target
    vim.cmd({ cmd = 'Tinygo', args = { cfg.target } })
  end,
})

return M
