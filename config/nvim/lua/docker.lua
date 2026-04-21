-- Docker系

local later = MiniDeps.later

later(function()
  vim.pack.add({ 'https://github.com/akinsho/toggleterm.nvim' })
  require('toggleterm').setup()

  local Terminal = require('toggleterm.terminal').Terminal
  local lazydocker = Terminal:new({
    cmd = 'lazydocker',
    direction = 'float',
    hidden = true,
    float_opts = { border = 'rounded' },
  })

  vim.keymap.set('n', '<leader>ld', function() lazydocker:toggle() end,
    { desc = 'Lazydocker' })
end)
