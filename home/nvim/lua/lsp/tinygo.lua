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
    -- tinygo プロジェクトは gopls-lazy 経由だと TinygoTarget の env が反映されないため、
    -- .tinygo.json を検出したタイミングで cmd を素の gopls に差し替えてから restart させる。
    local cmd = vim.deepcopy(vim.lsp.config.gopls.cmd)
    cmd[#cmd] = 'gopls'
    vim.lsp.config('gopls', { cmd = cmd })
    applied[root] = cfg.target
    vim.cmd({ cmd = 'TinygoTarget', args = { cfg.target } })
  end,
})
