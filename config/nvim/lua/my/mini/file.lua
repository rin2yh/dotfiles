local now, later = MiniDeps.now, MiniDeps.later

now(function()
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

later(function()
  require('mini.pick').setup()

  vim.ui.select = MiniPick.ui_select

  vim.keymap.set('n', '<space>f', function()
    MiniPick.builtin.files({ tool = 'git' })
  end, { desc = 'mini.pick.files' })
end)
