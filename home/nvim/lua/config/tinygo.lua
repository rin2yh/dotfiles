-- sago35/tinygo.vim の `:TinygoTarget` を .tinygo.json 検出時に自動実行する。
-- `:TinygoTarget` は GOROOT/GOOS/GOARCH/GOFLAGS を LSP の cmd_env に設定し、
-- `vim.lsp.enable('gopls', false → true)` で golance を再起動する。
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
