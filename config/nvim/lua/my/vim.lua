-- cache init.lua
vim.loader.enable()

-- vim
vim.opt.number = true
vim.cmd('syntax enable')
-- share clipboard with OS
vim.opt.clipboard:append('unnamedplus,unnamed')

-- use 2-spaces indent
vim.opt.expandtab = true
vim.opt.shiftround = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2

-- scroll offset as 3 lines
vim.opt.scrolloff = 3

-- move the cursor to the previous/next line across the first/last character
vim.opt.whichwrap = 'b,s,h,l,<,>,[,],~'

-- use rg for external-grep
vim.opt.grepprg = table.concat({
  'rg',
  '--vimgrep',
  '--trim',
  '--hidden',
  [[--glob='!.git']],
  [[--glob='!*.lock']],
  [[--glob='!*-lock.json']],
  [[--glob='!*generated*']],
}, ' ')
vim.opt.grepformat = '%f:%l:%c:%m'

-- ref: `:NewGrep` in `:help grep`
vim.api.nvim_create_user_command('Grep', function(arg)
  local grep_cmd = 'silent grep! '
    .. (arg.bang and '--fixed-strings -- ' or '')
    .. vim.fn.shellescape(arg.args, true)
  vim.cmd(grep_cmd)
  if vim.fn.getqflist({ size = true }).size > 0 then
    vim.cmd.copen()
  else
    vim.notify('no matches found', vim.log.levels.WARN)
    vim.cmd.cclose()
  end
end, { nargs = '+', bang = true, desc = 'Enhounced grep' })

vim.keymap.set('n', '<space>/', ':Grep ', { desc = 'Grep' })
vim.keymap.set('n', '<space>?', ':Grep <c-r><c-w>', { desc = 'Grep current word' })
