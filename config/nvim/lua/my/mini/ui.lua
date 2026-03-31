-- 表示系

-- Simple plugins
MiniDeps.now(require('mini.icons').setup)
for _, name in ipairs({ 'indentscope', 'diff' }) do
  MiniDeps.later(require('mini.' .. name).setup)
end

-- statusline
MiniDeps.now(function()
  require('mini.statusline').setup()
  vim.opt.laststatus = 3
  vim.opt.cmdheight = 0
end)

-- notify
MiniDeps.now(function()
  require('mini.notify').setup()
  vim.notify = require('mini.notify').make_notify({})
end)

-- hipatterns
MiniDeps.later(function()
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

-- git
MiniDeps.later(function()
  require('mini.git').setup()

  vim.keymap.set({ 'n', 'x' }, '<space>gs', MiniGit.show_at_cursor, { desc = 'Show at cursor' })
end)

-- trailspace
MiniDeps.later(function()
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
