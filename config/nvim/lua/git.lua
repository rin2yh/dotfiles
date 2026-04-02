-- Git系

local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

later(require('mini.diff').setup)

later(function()
  require('mini.git').setup()

  vim.keymap.set({ 'n', 'x' }, '<space>gs', MiniGit.show_at_cursor, { desc = 'Show at cursor' })
end)

later(function()
  add({ source = 'https://github.com/kdheepak/lazygit.nvim' })
  vim.keymap.set('n', '<leader>lg', '<cmd>LazyGit<cr>', { desc = 'Lazygit' })
end)
