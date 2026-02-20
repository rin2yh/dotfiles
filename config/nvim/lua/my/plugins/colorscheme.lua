local now, add = MiniDeps.now, MiniDeps.add

now(function()
  add({ source = 'https://github.com/folke/tokyonight.nvim' })
  vim.cmd.colorscheme('tokyonight')
end)
