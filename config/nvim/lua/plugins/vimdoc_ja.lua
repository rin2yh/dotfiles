local add, later = MiniDeps.add, MiniDeps.later

later(function()
  add('https://github.com/vim-jp/vimdoc-ja')
  vim.opt.helplang:prepend('ja')
end)
