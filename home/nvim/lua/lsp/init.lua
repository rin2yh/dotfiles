vim.pack.add({
  'https://github.com/neovim/nvim-lspconfig',
})

vim.diagnostic.config({
  virtual_text = true,
})

vim.api.nvim_create_user_command(
  'LspHealth',
  'checkhealth vim.lsp',
  { desc = 'LSP health check' })

vim.api.nvim_create_user_command('LspRestart', function()
  for _, client in ipairs(vim.lsp.get_clients()) do
    client:stop()
  end
  vim.defer_fn(function()
    vim.cmd('edit')
    vim.notify('LSP restarted', vim.log.levels.INFO)
  end, 100)
end, { desc = 'Restart all LSP clients' })

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
require('lsp.tinygo')

vim.lsp.enable({
  'cssls',
  'emmet_language_server',
  'gopls',
  'lua_ls',
  'nixd',
  'ocamllsp',
  'rust_analyzer',
  'terraformls',
  'ts_ls',
})
