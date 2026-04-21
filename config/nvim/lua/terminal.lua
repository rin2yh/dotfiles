-- Terminal系

local later = MiniDeps.later

vim.pack.add({ 'https://github.com/akinsho/toggleterm.nvim' })

later(function()
  require('toggleterm').setup()

  local Terminal = require('toggleterm.terminal').Terminal

  local lazygit = Terminal:new({
    cmd = 'lazygit',
    direction = 'float',
    hidden = true,
    float_opts = { border = 'rounded' },
  })

  local lazydocker = Terminal:new({
    cmd = 'lazydocker',
    direction = 'float',
    hidden = true,
    float_opts = { border = 'rounded' },
  })

  vim.keymap.set('n', '<leader>lg', function() lazygit:toggle() end, { desc = 'Lazygit' })
  vim.keymap.set('n', '<leader>ld', function() lazydocker:toggle() end, { desc = 'Lazydocker' })
end)
