local safely = MiniMisc.safely

safely('later', function()
  -- nvim-treesitter は treesitter ブロックで既に追加済み (depends 相当)
  vim.pack.add({ 'https://github.com/folke/ts-comments.nvim' })
  require('ts-comments').setup()
end)
