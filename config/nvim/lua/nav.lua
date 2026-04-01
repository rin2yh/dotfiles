-- 探索系

local now = MiniDeps.now

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
MiniDeps.later(function()
  require('mini.pick').setup()

  vim.ui.select = MiniPick.ui_select

  vim.keymap.set('n', '<space>f', function()
    MiniPick.builtin.files({ tool = 'git' })
  end, { desc = 'mini.pick.files' })
end)
