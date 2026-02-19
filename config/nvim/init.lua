vim.loader.enable()

-- editor options
vim.opt.number = true
vim.cmd('syntax enable')
vim.opt.clipboard:append('unnamedplus,unnamed')
vim.opt.expandtab = true
vim.opt.shiftround = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.opt.scrolloff = 3
vim.opt.whichwrap = 'b,s,h,l,<,>,[,],~'
vim.opt.inccommand = "split"

-- IME auto-off
vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*",
  callback = function()
    vim.fn.system("im-select com.apple.keylayout.ABC")
  end,
})

vim.keymap.set('t', '<Esc><Esc>', [[<C-\><C-n>]], { noremap = true })

require('my/user_command')
require('my/mini')

-- miniを内部で使用するため、mini以降に配置
require('my/lsp')
