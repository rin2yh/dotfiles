local safely = MiniMisc.safely

-- colorscheme
safely('now', function()
  vim.pack.add({ 'https://github.com/folke/tokyonight.nvim' })
  require("tokyonight").setup({
    style = "storm",
    transparent = true,
    on_highlights = function(hl, c)
      hl.WinSeparator = {
        fg = c.blue,
        bold = true,
      }

      hl.NormalFloat = { bg = "NONE" }
      hl.FloatBorder = { bg = "NONE" }
      -- 透過設定の場合、デフォルトでかなり薄いのでテーマカラーを適用
      hl.LineNr = { fg = c.fg_dark }
    end,
  })
  vim.cmd.colorscheme('tokyonight')
end)

safely('later', function()
  vim.pack.add({ 'https://github.com/vim-jp/vimdoc-ja' })
  vim.opt.helplang:prepend('ja')
end)

