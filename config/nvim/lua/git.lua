-- Git系

local later = MiniDeps.later

later(require('mini.diff').setup)

later(function()
  require('mini.git').setup()

  vim.keymap.set({ 'n', 'x' }, '<space>gs', MiniGit.show_at_cursor, { desc = 'Show at cursor' })
end)

later(function()
  vim.pack.add({ 'https://github.com/akinsho/toggleterm.nvim' })
  require('toggleterm').setup()

  local Terminal = require('toggleterm.terminal').Terminal
  local lazygit = Terminal:new({
    cmd = 'lazygit',
    direction = 'float',
    hidden = true,
    float_opts = { border = 'rounded' },
  })

  vim.keymap.set('n', '<leader>lg', function() lazygit:toggle() end,
    { desc = 'Lazygit' })
end)

