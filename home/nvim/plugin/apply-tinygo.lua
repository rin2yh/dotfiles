-- sago35/tinygo.vim の `:TinygoTarget` を .tinygo.json 検出時に自動実行する。
-- `:TinygoTarget` 内部で `vim.lsp.enable('gopls', false → true)` を呼び、
-- Neovim 0.11.2 以降はこの流れで gopls が新しい cmd_env で再 attach する。
vim.pack.add({ 'https://github.com/sago35/tinygo.vim' })

-- キャッシュしないと FileType go の度に `:TinygoTarget` が走り、gopls が毎回再起動する。
local applied = {}
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'go',
  group = vim.api.nvim_create_augroup('tinygo-auto', {}),
  callback = function(args)
    local root = vim.fs.root(args.buf, '.tinygo.json')
    if not root then return end
    local config_path = vim.fs.joinpath(root, '.tinygo.json')
    local ok, cfg = pcall(function()
      return vim.json.decode(table.concat(vim.fn.readfile(config_path), '\n'))
    end)
    if not ok or type(cfg) ~= 'table' or not cfg.target then return end
    if applied[root] == cfg.target then return end
    applied[root] = cfg.target
    vim.cmd({ cmd = 'TinygoTarget', args = { cfg.target } })
  end,
})
