-- Git系

local later = MiniDeps.later

later(function()
  require('mini.diff').setup()
end)

MiniDeps.later(function()
  require('mini.git').setup()

  vim.keymap.set({ 'n', 'x' }, '<space>gs', MiniGit.show_at_cursor, { desc = 'Show at cursor' })
end)
