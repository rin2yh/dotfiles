-- MiniMisc.safely is used throughout and must exist before other modules load.
local safely = MiniMisc.safely

local gen_loader = require('mini.snippets').gen_loader
require('mini.snippets').setup({
  snippets = { gen_loader.from_lang() },
  mappings = { jump_prev = '<c-k>' },
})
MiniSnippets.start_lsp_server()

-- Simple plugins
safely('now', function()
  require('mini.icons').setup()
  MiniIcons.mock_nvim_web_devicons()
end)
safely('later', require('mini.indentscope').setup)

-- statusline
safely('now', function()
  require('mini.statusline').setup()
  vim.opt.laststatus = 3
  vim.opt.cmdheight = 0
end)

-- tabline (開いているバッファ一覧を上部に表示)
-- アイコンを出すため mini.icons のセットアップ後に読み込む
safely('now', function()
  require('mini.tabline').setup()
end)

-- notify
safely('now', function()
  require('mini.notify').setup()
  vim.notify = require('mini.notify').make_notify({})
end)

-- hipatterns
safely('later', function()
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
safely('later', function()
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


-- Simple plugins
for _, name in ipairs({ 'pairs', 'surround', 'move', 'bracketed', 'jump2d' }) do
  safely('later', require('mini.' .. name).setup)
end

-- basics
safely('now', require('mini.basics').setup)

-- starter
safely('now', require('mini.starter').setup)

-- misc (mini.misc.setup() は init.lua で実行済み)
safely('now', function()
  MiniMisc.setup_restore_cursor()
  vim.api.nvim_create_user_command('Zoom', function()
    MiniMisc.zoom(0, {})
  end, { desc = 'Zoom current buffer' })
  vim.keymap.set('n', 'mz', '<cmd>Zoom<cr>', { desc = 'Zoom current buffer' })
end)


-- Git系

local safely = MiniMisc.safely

safely('later', require('mini.diff').setup)

safely('later', function()
  require('mini.git').setup()

  vim.keymap.set({ 'n', 'x' }, '<space>gs', MiniGit.show_at_cursor, { desc = 'Show at cursor' })
end)

require('config.mini.files')
require('config.mini.pick')
require('config.mini.clue')

