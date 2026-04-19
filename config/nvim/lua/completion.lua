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

local autotrigger_group = vim.api.nvim_create_augroup('lsp/completion', {})
local autotrigger_timer = vim.uv.new_timer()
local autotrigger_ms = 150

vim.api.nvim_create_autocmd('LspAttach', {
  group = autotrigger_group,
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client == nil or not client:supports_method('textDocument/completion') then
      return
    end
    vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })

    -- 単語途中でも LSP 補完を自動発火（triggerCharacters 以外もデバウンス付きで）
    vim.api.nvim_create_autocmd('TextChangedI', {
      group = autotrigger_group,
      buffer = ev.buf,
      callback = function()
        autotrigger_timer:stop()
        local col = vim.api.nvim_win_get_cursor(0)[2]
        if col == 0 then return end
        if vim.fn.pumvisible() == 1 then return end
        local prev_char = vim.api.nvim_get_current_line():sub(col, col)
        if not prev_char:match('[%w_]') then return end
        local buf = ev.buf
        autotrigger_timer:start(autotrigger_ms, 0, vim.schedule_wrap(function()
          if vim.api.nvim_get_current_buf() ~= buf then return end
          if vim.fn.mode() ~= 'i' or vim.fn.pumvisible() ~= 0 then return end
          vim.lsp.completion.get()
        end))
      end,
    })
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
  if vim.fn.pumvisible() == 1 then
    return keys.cn
  end
  return keys.ct
end, { expr = true, desc = 'Select next item if popup is visible' })

vim.keymap.set('i', '<s-tab>', function()
  if vim.fn.pumvisible() == 1 then
    return keys.cp
  end
  return keys.cd
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
