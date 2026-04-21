-- Docker系

local later = MiniDeps.later

later(function()
  vim.pack.add({ 'https://github.com/crnvl96/lazydocker.nvim' })
  require('lazydocker').setup()
  vim.keymap.set(
    { 'n', 't' },
    '<leader>ld',
    "<cmd>lua require('lazydocker').toggle({ engine = 'docker' })<CR>",
    { desc = 'Lazydocker' }
  )
end)
