-- config of lsp

local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later
vim.diagnostic.config({
  virtual_text = true,
})

vim.api.nvim_create_user_command(
  'LspHealth',
  'checkhealth vim.lsp',
  { desc = 'LSP health check' })

-- augroup for this config file
local augroup = vim.api.nvim_create_augroup('lsp/init.lua', {})

-- format
vim.api.nvim_create_autocmd('LspAttach', {
  group = augroup,
  callback = function(args)
    vim.keymap.set('n', 'grd', function()
      vim.lsp.buf.definition()
    end, { buffer = args.buf, desc = 'vim.lsp.buf.definition()' })

    vim.keymap.set('n', '<M-f>', function()
      vim.lsp.buf.format({ bufnr = args.buf })
    end, { buffer = args.buf, desc = 'Format buffer' })

    vim.keymap.set('n', '<space>w', vim.lsp.buf.code_action,
      { buffer = args.buf, desc = 'LSP code action' })
  end,
})

vim.api.nvim_create_user_command('LspRestart', function()
  local clients = vim.lsp.get_clients()
  for _, client in ipairs(clients) do
    client:stop()
  end
  vim.defer_fn(function()
    vim.cmd('edit')
    print("LSP Restarted (Bun dependencies refreshed)")
  end, 100)
end, {})

vim.lsp.config('*', {
  root_markers = { '.git' },
})

vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'LSP hover information' })
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local opts = { buffer = args.buf }

    -- hoverを実行する時に直接UI設定を渡す
    vim.keymap.set('n', 'K', function()
      vim.lsp.buf.hover({ border = "rounded" })
    end, opts)
  end,
})
-- load lsp/lua_ls.lua
local dirname = vim.fn.stdpath('config') .. '/lua/lsp'

-- 設定したlspを保存する配列
local lsp_names = {}

-- 同一ディレクトリのファイルをループ
for file, ftype in vim.fs.dir(dirname) do
  if ftype == 'file' and vim.endswith(file, '.lua') and file ~= 'init.lua' then
    local lsp_name = file:sub(1, -5)
    local ok, result = pcall(require, 'lsp/' .. lsp_name)
    if ok then
      vim.lsp.config(lsp_name, result)
      table.insert(lsp_names, lsp_name)
    else
      vim.notify('Error loading LSP: ' .. lsp_name .. '\n' .. result, vim.log.levels.WARN)
    end
  end
end

vim.lsp.enable(lsp_names)
