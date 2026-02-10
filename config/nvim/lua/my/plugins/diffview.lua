local add, later = MiniDeps.add, MiniDeps.later

later(function()
  add('sindrets/diffview.nvim')
  require('diffview').setup({
    enhanced_diff_hl = true,
    view = {
      merge_tool = {
        layout = "diff3_mixed",
      },
    },
  })

  vim.keymap.set('n', '<leader>gm', '<cmd>DiffviewOpen<cr>', { desc = 'Open Diffview (Merge)' })
  vim.keymap.set('n', '<leader>gx', '<cmd>DiffviewClose<cr>', { desc = 'Close Diffview' })
end)
