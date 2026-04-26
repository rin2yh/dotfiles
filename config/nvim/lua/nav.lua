-- 探索系

local now, later = MiniDeps.now, MiniDeps.later

-- starter
now(require('mini.starter').setup)

-- misc
now(function()
  require('mini.misc').setup()

  MiniMisc.setup_restore_cursor()
  vim.api.nvim_create_user_command('Zoom', function()
    MiniMisc.zoom(0, {})
  end, { desc = 'Zoom current buffer' })
  vim.keymap.set('n', 'mz', '<cmd>Zoom<cr>', { desc = 'Zoom current buffer' })
end)

-- files
now(function()
  require('mini.files').setup()

  -- mini.files.setup() がハイライトを上書きするため、setup() 後に再設定
  local function set_hl()
    vim.api.nvim_set_hl(0, 'MiniFilesNormal', { bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'MiniFilesBorder', { bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'MiniFilesBorderModified', { bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'MiniFilesTitle', { bg = 'NONE' })
    vim.api.nvim_set_hl(0, 'MiniFilesTitleFocused', { bg = 'NONE' })
  end
  set_hl()
  vim.api.nvim_create_autocmd('ColorScheme', { callback = set_hl })

  vim.api.nvim_create_user_command(
    'Files',
    function()
      MiniFiles.open()
    end,
    { desc = 'Open file exproler' }
  )
  -- command+bでFilesを実行する
  vim.keymap.set('n', '<D-b>', ':Files<CR>', { silent = true, desc = 'Toggle files' })
end)

-- pick
later(function()
  local prev_paste = vim.paste
  require('mini.pick').setup()

  vim.paste = function(lines, phase)
    if not MiniPick.is_picker_active() then
      return prev_paste(lines, phase)
    end
    local query = MiniPick.get_picker_query() or {}
    vim.list_extend(query, vim.fn.split(table.concat(lines, ' '), '\\zs'))
    MiniPick.set_picker_query(query)
    return true
  end

  vim.ui.select = MiniPick.ui_select

  vim.keymap.set('n', '<leader>f', function()
    MiniPick.builtin.files({ tool = 'git' })
  end, { desc = 'mini.pick.files' })
  vim.keymap.set('n', '<space>b', MiniPick.builtin.buffers)

  local MiniExtra = require('mini.extra')
  vim.keymap.set('n', '<space>d', function()
    MiniExtra.pickers.diagnostic({ scope = 'current' })
  end, { desc = 'Diagnostics (current buffer)' })
  vim.keymap.set('n', '<space>D', function()
    MiniExtra.pickers.diagnostic({ scope = 'all' })
  end, { desc = 'Diagnostics (all buffers)' })
end)
