local add, later = MiniDeps.add, MiniDeps.later

later(function()
  add({
    source = 'iamcco/markdown-preview.nvim',
    hooks = { post_install = function() vim.fn['mkdp#util#install']() end },
  })

  vim.keymap.set('n', '<leader>mp', '<cmd>MarkdownPreviewToggle<cr>', { desc = 'Markdown Preview Toggle' })
end)
