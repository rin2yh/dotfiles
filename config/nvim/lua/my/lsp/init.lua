-- config of lsp
vim.diagnostic.config({
  virtual_text = true,
})

vim.api.nvim_create_user_command(
  'LspHealth',
  'checkhealth vim.lsp',
  { desc = 'LSP health check' })

-- augroup for this config file
local augroup = vim.api.nvim_create_augroup('my/lsp/init.lua', {})

-- format
vim.api.nvim_create_autocmd('LspAttach', {
  group = augroup,
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    vim.keymap.set('n', 'grd', function()
      vim.lsp.buf.definition()
    end, { buffer = args.buf, desc = 'vim.lsp.buf.definition()' })

    vim.keymap.set('n', '<M-f>', function()
      vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
    end, { buffer = args.buf, desc = 'Format buffer' })
  end,
})

vim.lsp.config('*', {
  root_markers = { '.git' },
  capabilities = require('mini.completion').get_lsp_capabilities(),
})

-- load my/lsp/lua_ls.lua
local dirname = vim.fn.stdpath('config') .. '/lua/my/lsp'

-- 設定したlspを保存する配列
local lsp_names = {}

-- 同一ディレクトリのファイルをループ
for file, ftype in vim.fs.dir(dirname) do
  if ftype == 'file' and vim.endswith(file, '.lua') and file ~= 'init.lua' then
    local lsp_name = file:sub(1, -5)
    local ok, result = pcall(require, 'my/lsp/' .. lsp_name)
    if ok then
      vim.lsp.config(lsp_name, result)
      table.insert(lsp_names, lsp_name)
    else
      vim.notify('Error loading LSP: ' .. lsp_name .. '\n' .. result, vim.log.levels.WARN)
    end
  end
end

vim.lsp.enable(lsp_names)
