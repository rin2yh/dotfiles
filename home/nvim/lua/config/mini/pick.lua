local safely = MiniMisc.safely

-- pick
safely('later', function()
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

  vim.keymap.set('n', '<space>d', vim.diagnostic.setloclist,
    { desc = 'Diagnostics (current buffer)' })
  vim.keymap.set('n', '<space>D', vim.diagnostic.setqflist,
    { desc = 'Diagnostics (all buffers)' })
end)
