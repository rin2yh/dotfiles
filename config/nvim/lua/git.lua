-- Git系

local add, later = MiniDeps.add, MiniDeps.later

later(require('mini.diff').setup)

later(function()
  require('mini.git').setup()

  vim.keymap.set({ 'n', 'x' }, '<space>gs', MiniGit.show_at_cursor, { desc = 'Show at cursor' })
end)

later(function()
  add({ source = 'https://github.com/kdheepak/lazygit.nvim' })
  vim.keymap.set('n', '<leader>lg', '<cmd>LazyGit<cr>', { desc = 'Lazygit' })
end)

-- octo.nvim のpickerとしてtelescopeを使うため、octoより先にロード
later(function()
  add({
    source = 'nvim-telescope/telescope.nvim',
    depends = { 'nvim-lua/plenary.nvim' },
  })
  require('telescope').setup({
    defaults = {
      initial_mode = 'normal',
      mappings = {
        n = {
          ['q'] = 'close',
        },
      },
    },
  })
end)

later(function()
  add({
    source = 'pwntester/octo.nvim',
    depends = { 'nvim-telescope/telescope.nvim' },
  })

  require('octo').setup({
    picker = 'telescope',
    enable_builtin = true,
  })

  vim.keymap.set('n', '<leader>oi', '<CMD>Octo issue list<CR>', { desc = 'List GitHub Issues' })
  vim.keymap.set('n', '<leader>op', '<CMD>Octo pr list<CR>', { desc = 'List GitHub PullRequests' })
  vim.keymap.set('n', '<leader>od', '<CMD>Octo discussion list<CR>', { desc = 'List GitHub Discussions' })
  vim.keymap.set('n', '<leader>on', '<CMD>Octo notification list<CR>', { desc = 'List GitHub Notifications' })
  vim.keymap.set('n', '<leader>os', function()
    require('octo.utils').create_base_search_command({ include_current_repo = true })
  end, { desc = 'Search GitHub' })
end)
