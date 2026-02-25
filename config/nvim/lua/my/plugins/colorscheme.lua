local now, add = MiniDeps.now, MiniDeps.add

now(function()
  add({ source = 'https://github.com/folke/tokyonight.nvim' })
  require("tokyonight").setup({
    style = "storm",
    on_highlights = function(hl, c)
      hl.WinSeparator = {
        fg = c.blue,
        bold = true,
      }
    end,
  })
  vim.cmd.colorscheme('tokyonight')
end)
