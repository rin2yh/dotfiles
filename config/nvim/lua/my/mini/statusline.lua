MiniDeps.now(function()
  require('mini.statusline').setup()

  -- 下に表示されるステータスを非表示にして、上に表示する
  vim.opt.laststatus = 0
  vim.o.winbar = "%{%v:lua.MiniStatusline.active()%}"

  vim.opt.cmdheight = 0
end)
