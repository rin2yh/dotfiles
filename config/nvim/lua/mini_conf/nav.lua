-- 探索系

-- Simple plugins
for _, name in ipairs({ 'basics', 'starter' }) do
  MiniDeps.now(require('mini.' .. name).setup)
end

-- misc
MiniDeps.now(function()
  require('mini.misc').setup()

  MiniMisc.setup_restore_cursor()
  vim.api.nvim_create_user_command('Zoom', function()
    MiniMisc.zoom(0, {})
  end, { desc = 'Zoom current buffer' })
  vim.keymap.set('n', 'mz', '<cmd>Zoom<cr>', { desc = 'Zoom current buffer' })
end)

-- files
MiniDeps.now(function()
  require('mini.files').setup()

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

