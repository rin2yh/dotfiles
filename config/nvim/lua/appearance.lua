-- 表示系

vim.o.winbar = " %m %f "

local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

-- colorscheme
now(function()
  add({ source = 'https://github.com/folke/tokyonight.nvim' })
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
      -- 補完ポップアップも透過（選択行は視認性のため残す）
      hl.Pmenu = { bg = "NONE" }
      hl.PmenuKind = { bg = "NONE" }
      hl.PmenuExtra = { bg = "NONE" }
      hl.PmenuSbar = { bg = "NONE" }
      -- 透過設定の場合、デフォルトでかなり薄いのでテーマカラーを適用
      hl.LineNr = { fg = c.fg_dark }

      -- telescope 透過
      for _, name in ipairs({
        'Normal', 'Border',
        'PromptNormal', 'PromptBorder', 'PromptTitle',
        'ResultsNormal', 'ResultsBorder', 'ResultsTitle',
        'PreviewNormal', 'PreviewBorder', 'PreviewTitle',
        'Title',
      }) do
        hl['Telescope' .. name] = { bg = 'NONE' }
      end
    end,
  })
  vim.cmd.colorscheme('tokyonight')
end)

later(function()
  add('https://github.com/vim-jp/vimdoc-ja')
  vim.opt.helplang:prepend('ja')
end)

-- Simple plugins
now(function()
  require('mini.icons').setup()
  MiniIcons.mock_nvim_web_devicons()
end)
later(require('mini.indentscope').setup)

-- statusline
now(function()
  require('mini.statusline').setup()
  vim.opt.laststatus = 3
  vim.opt.cmdheight = 0
end)

-- notify
now(function()
  require('mini.notify').setup()
  vim.notify = require('mini.notify').make_notify({})
end)

-- hipatterns
later(function()
  local hipatterns = require('mini.hipatterns')
  local hi_words = require('mini.extra').gen_highlighter.words
  hipatterns.setup({
    highlighters = {
      -- Highlight standalone 'TODO'
      todo = hi_words({ 'TODO' }, 'MiniHipatternsTodo'),
      -- Highlight hex color strings (`#rrggbb`) using that color
      hex_color = hipatterns.gen_highlighter.hex_color(),
    },
  })
end)

-- trailspace
later(function()
  require('mini.trailspace').setup()
  vim.api.nvim_create_user_command(
    'Trim',
    function()
      MiniTrailspace.trim()
      MiniTrailspace.trim_last_lines()
    end,
    { desc = 'Trim trailing space and last blank lines' }
  )
end)

-- clue (全体のキーバインドヒント)
later(function()
  local function mode_nx(keys)
    return { mode = 'n', keys = keys }, { mode = 'x', keys = keys }
  end

  local clue = require('mini.clue')
  clue.setup({
    triggers = {
      -- Leader triggers
      mode_nx('<leader>'),

      -- Built-in completion
      { mode = 'i', keys = '<c-x>' },

      -- `g` key
      mode_nx('g'),

      -- Marks
      mode_nx("'"),
      mode_nx('`'),

      -- Registers
      mode_nx('"'),
      { mode = 'i', keys = '<c-r>' },
      { mode = 'c', keys = '<c-r>' },

      -- Window commands
      { mode = 'n', keys = '<c-w>' },

      -- bracketed commands
      { mode = 'n', keys = '[' },
      { mode = 'n', keys = ']' },

      -- `z` key
      mode_nx('z'),

      -- surround
      mode_nx('s'),

      -- text object
      { mode = 'x', keys = 'i' },
      { mode = 'x', keys = 'a' },
      { mode = 'o', keys = 'i' },
      { mode = 'o', keys = 'a' },

      -- option toggle (mini.basics)
      { mode = 'n', keys = 'm' },
    },

    clues = {
      -- Enhance this by adding descriptions for <Leader> mapping groups
      clue.gen_clues.builtin_completion(),
      clue.gen_clues.g(),
      clue.gen_clues.marks(),
      clue.gen_clues.registers({ show_contents = true }),
      clue.gen_clues.windows({ submode_resize = true, submode_move = true }),
      clue.gen_clues.z(),
    },
  })
end)
