local now, add, later = MiniDeps.now, MiniDeps.add, MiniDeps.later

now(function()
  add({
    source = 'https://github.com/nvim-treesitter/nvim-treesitter',
    hooks = {
      post_checkout = function()
        vim.cmd.TSUpdate()
      end
    },
    config = function()
      -- tree-sitterとfiletypeが違う罠
      -- tsx:typescriptreact, bash:sh
      require('nvim-treesitter.configs').setup({
        ensure_installed = {
          'lua', 'vim', 'markdown', 'markdown_inline', 'bash', 'yaml', 'zsh',
          'tsx', 'typescript', 'html',
          'go', 'rust',
          'terraform', 'dockerfile'
        },
        highlight = { enable = true },
      })
    end
  })
  require('nvim-treesitter.install').update({ with_sync = true })
end)

later(function()
  add({
    source = 'https://github.com/folke/ts-comments.nvim',
    depends = { 'nvim-treesitter/nvim-treesitter' },
  })
  require('ts-comments').setup()
end)

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
