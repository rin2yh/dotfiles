local safely = MiniMisc.safely

safely('later', function()
  vim.pack.add({ 'https://github.com/vim-jp/vimdoc-ja' })
  vim.opt.helplang:prepend('ja')
end)
