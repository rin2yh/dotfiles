local safely = MiniMisc.safely

-- files
safely('now', function()
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

