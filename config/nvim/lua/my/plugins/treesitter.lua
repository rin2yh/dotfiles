local add, later = MiniDeps.add, MiniDeps.later

add({
  source = 'https://github.com/nvim-treesitter/nvim-treesitter',
  hooks = {
    post_checkout = function()
      vim.cmd.TSUpdate()
    end
  },
})

later(function()
  require('nvim-treesitter').install({ 'lua', 'vim', 'tsx', 'go', 'typescript', 'html', 'markdown', 'markdown_inline',
    'bash', 'terraform', 'hcl', 'dockerfile' })

  vim.api.nvim_create_autocmd('FileType', {
    pattern = '*',
    callback = function()
      pcall(vim.treesitter.start)
    end,
  })
end)
