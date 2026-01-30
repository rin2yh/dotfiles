local add, later = MiniDeps.add, MiniDeps.later

-- vimjp doc
later(function()
  add('https://github.com/vim-jp/vimdoc-ja')
  -- Prefer Japanese as the help language
  vim.opt.helplang:prepend('ja')
end)

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
    'bash' })

  -- 全てのファイルタイプでハイライト有効化
  vim.api.nvim_create_autocmd('FileType', {
    pattern = '*',
    callback = function()
      pcall(vim.treesitter.start)
    end,
  })
end)

add("pcolladosoto/tinygo.nvim")
