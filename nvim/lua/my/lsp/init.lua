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
local lua_ls_opts = require('my/lsp/lua_ls')
vim.lsp.config('lua_ls', lua_ls_opts)
vim.lsp.enable('lua_ls')
