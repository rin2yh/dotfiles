vim.loader.enable()

-- mini.deps は最新の mini.nvim で開発が凍結されたため、プラグイン管理は
-- Neovim 組み込みの vim.pack に移行。mini.nvim 本体も vim.pack で入れる。
vim.pack.add({ 'https://github.com/echasnovski/mini.nvim' })

-- 各モジュールは MiniDeps.now/later の代わりに MiniMisc.safely を使う。
-- MiniMisc グローバルは require('mini.misc').setup() で生成されるため、
-- 他モジュールを読み込む前にここでセットアップしておく。
require('mini.misc').setup()

require('config.nvim')
require('config.mini')

-- プラグイン設定は対象名で読み込む。
for _, name in ipairs({ 'tokyonight', 'treesitter', 'ts-comments', 'marp', 'toggleterm', 'lsp' }) do
  require('config.' .. name)
end
