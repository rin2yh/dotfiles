-- 編集系

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
vim.opt.autoread = true

-- IME auto-off
vim.api.nvim_create_autocmd("InsertLeave", {
  pattern = "*",
  callback = function()
    vim.fn.system("im-select com.apple.keylayout.ABC")
  end,
})

vim.api.nvim_create_user_command(
  'InitLua',
  function()
    vim.cmd.edit(vim.fn.stdpath('config') .. '/init.lua')
  end,
  { desc = 'Open init.lua' }
)

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
  local fixed_strings_opt = ''
  if arg.bang then
    fixed_strings_opt = '--fixed-strings -- '
  end
  local grep_cmd = 'silent grep! '
      .. fixed_strings_opt
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

vim.api.nvim_create_user_command('CopyPath', function()
  local path = vim.fn.expand('%')
  vim.fn.setreg('+', path)
  print("Copied: " .. path)
end, {})

local safely = MiniMisc.safely

-- treesitter
safely('now', function()
  -- mini.deps の hooks.post_checkout 相当: install/update 時に parser を更新
  vim.api.nvim_create_autocmd('PackChanged', {
    callback = function(ev)
      if ev.data.spec.name == 'nvim-treesitter'
          and (ev.data.kind == 'install' or ev.data.kind == 'update') then
        vim.cmd.TSUpdate()
      end
    end,
  })
  vim.pack.add({ 'https://github.com/nvim-treesitter/nvim-treesitter' })
  require('nvim-treesitter').install({
    'lua', 'vim', 'markdown', 'markdown_inline', 'bash', 'yaml', 'zsh',
    'tsx', 'typescript', 'html',
    'go', 'rust', 'ocaml', 'ocaml_interface',
    'terraform', 'dockerfile', 'nix'
  })
  -- tree-sitterとfiletypeが違う罠
  -- tsx:typescriptreact, bash:sh
  local reinstalled = {}
  vim.api.nvim_create_autocmd('FileType', {
    pattern = {
      'lua', 'vim', 'markdown', 'sh', 'yaml', 'zsh',
      'typescriptreact', 'typescript', 'html',
      'go', 'rust',
      'terraform', 'dockerfile', 'nix'
    },
    callback = function(ev)
      if pcall(vim.treesitter.start, ev.buf) then return end
      local ft = vim.bo[ev.buf].filetype
      local lang = vim.treesitter.language.get_lang(ft) or ft
      if reinstalled[lang] then return end
      reinstalled[lang] = true
      vim.notify(('treesitter %s: reinstalling parser...'):format(lang), vim.log.levels.WARN)
      require('nvim-treesitter').install({ lang }, { force = true }):await(function()
        vim.schedule(function() pcall(vim.treesitter.start, ev.buf) end)
      end)
    end,
  })
  -- ocaml は上のループに入れられない: .ml と .mli は同じ filetype 'ocaml' なのに
  -- parser は別 (signature 側は ocaml_interface) で、filetype からは判別できないため。
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'ocaml',
    callback = function(ev)
      local ext = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ev.buf), ':e')
      pcall(vim.treesitter.start, ev.buf, ext == 'mli' and 'ocaml_interface' or 'ocaml')
    end,
  })
end)

safely('later', function()
  -- nvim-treesitter は treesitter ブロックで既に追加済み (depends 相当)
  vim.pack.add({ 'https://github.com/folke/ts-comments.nvim' })
  require('ts-comments').setup()
end)

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99

-- Simple plugins
for _, name in ipairs({ 'pairs', 'surround', 'move', 'bracketed', 'jump2d' }) do
  safely('later', require('mini.' .. name).setup)
end

-- basics
safely('now', require('mini.basics').setup)
