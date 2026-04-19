-- 補完系

-- snippets（LSP server として残す）
local gen_loader = require('mini.snippets').gen_loader
require('mini.snippets').setup({
  snippets = { gen_loader.from_lang() },
  mappings = { jump_prev = '<c-k>' },
})
MiniSnippets.start_lsp_server()

-- completion（Neovim 0.12 ネイティブ）
vim.o.pumborder = 'rounded'
vim.opt.completeopt = { 'menu', 'menuone', 'noselect', 'fuzzy', 'popup' }
vim.opt.complete = { '.', 'w', 'k', 'b', 'u' }
vim.opt.dictionary:append('/usr/share/dict/words')

-- LSP attach 時にネイティブ補完を有効化
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp/completion', {}),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
  end,
})

-- 既存のキーマップは維持
local keys = {
  cn = vim.keycode('<c-n>'),
  cp = vim.keycode('<c-p>'),
  ct = vim.keycode('<c-t>'),
  cd = vim.keycode('<c-d>'),
  cr = vim.keycode('<cr>'),
  cy = vim.keycode('<c-y>'),
}

vim.keymap.set('i', '<tab>', function()
  return vim.fn.pumvisible() == 1 and keys.cn or keys.ct
end, { expr = true, desc = 'Select next item if popup is visible' })

vim.keymap.set('i', '<s-tab>', function()
  return vim.fn.pumvisible() == 1 and keys.cp or keys.cd
end, { expr = true, desc = 'Select previous item if popup is visible' })

vim.keymap.set('i', '<cr>', function()
  if vim.fn.pumvisible() == 0 then
    return require('mini.pairs').cr()
  end
  local item_selected = vim.fn.complete_info()['selected'] ~= -1
  if item_selected then
    return keys.cy
  end
  return keys.cy .. keys.cr
end, { expr = true, desc = 'Complete current item if item is selected' })
