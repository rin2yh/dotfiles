local M = {}

-- mise の go shim は GOROOT env を無視するため、直接の go binary を PATH 先頭に
-- 置いてから gopls を起動する（gopls 内部の `go env` に TinyGo overlay を反映）。
local go_dir = vim.fs.dirname(vim.trim(vim.fn.system('mise which go')))
M.cmd = { 'env', 'PATH=' .. go_dir .. ':' .. vim.env.PATH, 'gopls-lazy' }
M.filetypes = { 'go', 'gomod' }
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

-- sago35/tinygo.vim の `:TinygoTarget` を .tinygo.json 検出時に自動実行する。
-- `:TinygoTarget` は内部で GOROOT/GOOS/GOARCH/GOFLAGS を gopls の cmd_env に書き込み、
-- `vim.lsp.enable('gopls', false → true)` で gopls を再起動する。
vim.pack.add({ 'https://github.com/sago35/tinygo.vim' })

-- キャッシュしないと FileType go の度に `:TinygoTarget` が走り、gopls が毎回再起動する。
local applied = {}
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'go',
  group = vim.api.nvim_create_augroup('tinygo-auto', {}),
  callback = function(args)
    local root = vim.fs.root(args.buf, '.tinygo.json')
    if not root then return end
    local ok, cfg = pcall(vim.json.decode,
      table.concat(vim.fn.readfile(vim.fs.joinpath(root, '.tinygo.json')), '\n'))
    if not ok or type(cfg) ~= 'table' or not cfg.target then return end
    if applied[root] == cfg.target then return end
    applied[root] = cfg.target
    vim.cmd({ cmd = 'TinygoTarget', args = { cfg.target } })
  end,
})

return M
