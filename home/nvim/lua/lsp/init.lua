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
local function mise_which(tool)
  local path = vim.trim(vim.fn.system({ 'mise', 'which', tool }))
  if vim.v.shell_error == 0 and path ~= '' then return path end
  return vim.fn.exepath(tool)
end

local function format_buffer(bufnr)
  vim.lsp.buf.format({ bufnr = bufnr })
  if vim.bo[bufnr].filetype ~= 'go' then return end

  local gofumpt = mise_which('gofumpt')
  if gofumpt == '' then return end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local text = table.concat(lines, '\n')
  if vim.bo[bufnr].endofline then text = text .. '\n' end
  local result = vim.system({ gofumpt }, { stdin = text, text = true }):wait()
  if result.code ~= 0 then
    vim.notify(result.stderr, vim.log.levels.ERROR, { title = 'gofumpt' })
    return
  end

  local formatted = vim.split(result.stdout, '\n', { trimempty = false })
  if formatted[#formatted] == '' then table.remove(formatted) end
  -- gofumpt retains trailing empty lines in some blocks, such as for loops.
  for i = #formatted - 1, 1, -1 do
    if formatted[i]:match('^%s*$') and formatted[i + 1]:match('^%s*}') then
      table.remove(formatted, i)
    end
  end
  if not vim.deep_equal(lines, formatted) then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
  end
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = augroup,
  callback = function(args)
    vim.keymap.set('n', 'grd', function()
      vim.lsp.buf.definition()
    end, { buffer = args.buf, desc = 'vim.lsp.buf.definition()' })

    vim.keymap.set('n', '<M-f>', function()
      format_buffer(args.buf)
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
  'terraformls',
  'ts_ls',
})
