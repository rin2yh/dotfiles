local now, add, later = MiniDeps.now, MiniDeps.add, MiniDeps.later

now(function()
  add({
    source = 'https://github.com/nvim-treesitter/nvim-treesitter',
    hooks = {
      post_checkout = function()
        vim.cmd.TSUpdate()
      end
    },
  })

  -- tree-sitterとfiletypeが違う罠
  -- tsx:typescriptreact, bash:sh
  require('nvim-treesitter.config').setup({
    ensure_installed = {
      'lua', 'vim', 'markdown', 'markdown_inline', 'bash',
      'tsx', 'typescript', 'html',
      'go',
      'terraform', 'dockerfile'
    },
    highlight = { enable = true },
  })
  vim.api.nvim_create_autocmd({ "FileType" }, {
    pattern = { 'lua', 'vim', 'markdown', 'sh', 'typescriptreact', 'typescript', 'html', 'go', 'terraform', 'dockerfile' },
    callback = function()
      vim.treesitter.start()
    end,
  })
end)

later(function()
  add({
    source = 'https://github.com/folke/ts-comments.nvim',
    depends = { 'nvim-treesitter/nvim-treesitter' },
  })
  require('ts-comments').setup()
end)
