local now, add = MiniDeps.now, MiniDeps.add

now(function()
  add({ source = 'https://github.com/folke/tokyonight.nvim' })
  require('tokyonight').setup({
    style = 'storm',
    transparent = true,
    on_highlights = function(hl, c)
      hl.WinSeparator = {
        fg = c.blue,
        bold = true,
      }

      -- 透過設定の場合、デフォルトでかなり薄いのでテーマカラーを適用
      hl.LineNr = { fg = c.fg_dark }

      -- mini.filesの背景も透過させる
      hl.MiniFilesNormal = { bg = 'NONE' }
      hl.MiniFilesBorder = { bg = 'NONE' }
      hl.MiniFilesBorderModified = { bg = 'NONE' }
      hl.MiniFilesTitle = { bg = 'NONE' }
      hl.MiniFilesTitleFocused = { bg = 'NONE' }
    end,
  })
  vim.cmd.colorscheme('tokyonight')
end)
