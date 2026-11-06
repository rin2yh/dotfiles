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


-- keymaps

-- /検索のハイライトを消す
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { silent = true })

-- 一括置換 :s<Space>
vim.keymap.set('ca', 's', function()
  if vim.fn.getcmdtype() == ':' and vim.fn.getcmdline() == 's' then
    return '%s///g<Left><Left><Left>'
  end
  return 's'
end, { expr = true })

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99

-- completion (Neovim native)
vim.o.pumborder = 'rounded'
vim.opt.completeopt = { 'menu', 'menuone', 'noselect', 'fuzzy', 'popup' }
vim.opt.complete = { '.', 'w', 'k', 'b', 'u' }
vim.opt.dictionary:append('/usr/share/dict/words')

-- Vim API の 0/1 を素直な bool に変換するヘルパー
local function pum_visible()
  return vim.fn.pumvisible() == 1
end

local function in_insert_mode()
  return vim.fn.mode() == 'i'
end

local autotrigger_group = vim.api.nvim_create_augroup('lsp/completion', {})
local autotrigger_timer = vim.uv.new_timer()
local autotrigger_ms = 150

vim.api.nvim_create_autocmd('LspAttach', {
  group = autotrigger_group,
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client == nil or not client:supports_method('textDocument/completion') then
      return
    end
    vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })

    -- 単語途中でも LSP 補完を自動発火（triggerCharacters 以外もデバウンス付きで）
    vim.api.nvim_create_autocmd('TextChangedI', {
      group = autotrigger_group,
      buffer = ev.buf,
      callback = function()
        autotrigger_timer:stop()
        local col = vim.api.nvim_win_get_cursor(0)[2]
        local at_line_start = col == 0
        if at_line_start then return end
        if pum_visible() then return end
        local prev_char = vim.api.nvim_get_current_line():sub(col, col)
        if not prev_char:match('[%w_]') then return end
        local buf = ev.buf
        autotrigger_timer:start(autotrigger_ms, 0, vim.schedule_wrap(function()
          if vim.api.nvim_get_current_buf() ~= buf then return end
          if not in_insert_mode() or pum_visible() then return end
          vim.lsp.completion.get()
        end))
      end,
    })
  end,
})

-- 既存のキーマップは維持
local keys = {
  cn = vim.keycode('<c-n>'),
  cp = vim.keycode('<c-p>'),
  ct = vim.keycode('<c-t>'),
  cd = vim.keycode('<c-d>'),
  cr = vim.keycode('<cr>'),
  cy = vim.keycode('<c-y>'),
}

vim.keymap.set('i', '<tab>', function()
  if pum_visible() then
    return keys.cn
  end
  return keys.ct
end, { expr = true, desc = 'Select next item if popup is visible' })

vim.keymap.set('i', '<s-tab>', function()
  if pum_visible() then
    return keys.cp
  end
  return keys.cd
end, { expr = true, desc = 'Select previous item if popup is visible' })

vim.keymap.set('i', '<cr>', function()
  if not pum_visible() then
    return require('mini.pairs').cr()
  end
  -- complete_info().selected は未選択時に -1 を返す
  local item_selected = vim.fn.complete_info()['selected'] ~= -1
  if item_selected then
    return keys.cy
  end
  return keys.cy .. keys.cr
end, { expr = true, desc = 'Complete current item if item is selected' })

vim.api.nvim_create_user_command('PackUpdate', function(ctx)
  vim.pack.update(#ctx.fargs > 0 and ctx.fargs or nil)
end, {
  nargs = '*',
  -- info = false で git のブランチ・タグ取得を省く（有効にすると補完が 70ms 遅くなる）
  complete = function(arg)
    return vim.iter(vim.pack.get(nil, { info = false }))
      :map(function(plugin)
        return plugin.spec.name
      end)
      :filter(function(name)
        return vim.startswith(name, arg)
      end)
      :totable()
  end,
  desc = 'Update vim.pack plugins (no args = all)',
})
