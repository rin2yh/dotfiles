-- Git系

local safely = MiniMisc.safely

safely('later', require('mini.diff').setup)

safely('later', function()
  require('mini.git').setup()

  vim.keymap.set({ 'n', 'x' }, '<space>gs', MiniGit.show_at_cursor, { desc = 'Show at cursor' })
end)

