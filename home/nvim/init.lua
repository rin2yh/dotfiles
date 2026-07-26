vim.loader.enable()

-- mini.deps は最新の mini.nvim で開発が凍結されたため、プラグイン管理は
-- Neovim 組み込みの vim.pack に移行。mini.nvim 本体も vim.pack で入れる。
vim.pack.add({ 'https://github.com/echasnovski/mini.nvim' })

-- 各モジュールは MiniDeps.now/later の代わりに MiniMisc.safely を使う。
-- MiniMisc グローバルは require('mini.misc').setup() で生成されるため、
-- 他モジュールを読み込む前にここでセットアップしておく。
require('mini.misc').setup()

-- keymaps
-- jkで抜ける系
vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("v", "jk", "<Esc>")

-- /検索のハイライトを消す
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { silent = true })

-- 一括置換 :s<Space>
vim.keymap.set('ca', 's', function()
  if vim.fn.getcmdtype() == ':' and vim.fn.getcmdline() == 's' then
    return '%s///g<Left><Left><Left>'
  end
  return 's'
end, { expr = true })

require('appearance')
require('edit')
require('completion')
require('nav')
require('git')
require('markdown')
require('terminal')
require('lsp')

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
