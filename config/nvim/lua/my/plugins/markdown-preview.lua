local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

now(function()
  add({
    source = 'iamcco/markdown-preview.nvim',
  })
end)

later(function()
  vim.fn['mkdp#util#install']()
  vim.keymap.set('n', '<leader>mp', '<cmd>MarkdownPreviewToggle<cr>', { desc = 'Markdown Preview Toggle' })
end)
