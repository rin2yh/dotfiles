-- Terminal系

local later = MiniDeps.later

vim.pack.add({ 'https://github.com/akinsho/toggleterm.nvim' })

later(function()
  require('toggleterm').setup({
    open_mapping = [[<C-\>]],
    direction = 'horizontal',
    size = function(term)
      if term.direction == 'horizontal' then
        return 15
      elseif term.direction == 'vertical' then
        return math.floor(vim.o.columns * 0.4)
      end
    end,
    start_in_insert = true,
    persist_mode = false,
    shade_terminals = true,
    float_opts = { border = 'curved' },
  })

  local Terminal = require('toggleterm.terminal').Terminal

  vim.keymap.set('n', '<leader>th', function() vim.cmd('ToggleTerm direction=horizontal') end,
    { desc = 'Terminal horizontal' })
  vim.keymap.set('n', '<leader>tv', function() vim.cmd('ToggleTerm direction=vertical') end,
    { desc = 'Terminal vertical' })
  vim.keymap.set('n', '<leader>tf', function() vim.cmd('ToggleTerm direction=float') end,
    { desc = 'Terminal float' })

  for i = 1, 5 do
    vim.keymap.set('n', '<leader>' .. i, function() vim.cmd(string.format('%dToggleTerm', i)) end,
      { desc = 'Toggle terminal ' .. i })
  end

  vim.api.nvim_create_autocmd('TermOpen', {
    pattern = 'term://*toggleterm#*',
    callback = function(args)
      local opts = { buffer = args.buf, silent = true }
      local is_float = vim.api.nvim_win_get_config(0).relative ~= ''
      if not is_float then
        vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
        vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], opts)
      end
      vim.keymap.set('t', '<C-h>', [[<cmd>wincmd h<cr>]], opts)
      vim.keymap.set('t', '<C-j>', [[<cmd>wincmd j<cr>]], opts)
      vim.keymap.set('t', '<C-k>', [[<cmd>wincmd k<cr>]], opts)
      vim.keymap.set('t', '<C-l>', [[<cmd>wincmd l<cr>]], opts)
    end,
  })

  local lazygit = Terminal:new({
    cmd = 'lazygit',
    direction = 'float',
    hidden = true,
    float_opts = { border = 'rounded' },
  })

  local lazydocker = Terminal:new({
    cmd = 'lazydocker',
    direction = 'float',
    hidden = true,
    float_opts = { border = 'rounded' },
  })

  vim.keymap.set('n', '<leader>lg', function() lazygit:toggle() end, { desc = 'Lazygit' })
  vim.keymap.set('n', '<leader>ld', function() lazydocker:toggle() end, { desc = 'Lazydocker' })
end)
