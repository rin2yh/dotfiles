local add, later = MiniDeps.add, MiniDeps.later

-- vimjp doc
later(function()
  add('https://github.com/vim-jp/vimdoc-ja')
  -- Prefer Japanese as the help language
  vim.opt.helplang:prepend('ja')
end)

add({
  source = 'https://github.com/nvim-treesitter/nvim-treesitter',
  hooks = {
    post_checkout = function()
      vim.cmd.TSUpdate()
    end
  },
})

later(function()
  require('nvim-treesitter').install({ 'lua', 'vim', 'tsx', 'go', 'typescript', 'html', 'markdown', 'markdown_inline',
    'bash', 'terraform', 'hcl' })

  -- 全てのファイルタイプでハイライト有効化
  vim.api.nvim_create_autocmd('FileType', {
    pattern = '*',
    callback = function()
      pcall(vim.treesitter.start)
    end,
  })
end)

add("pcolladosoto/tinygo.nvim")

-- Git Conflict Resolution (VSCode-like 3-way merge)
later(function()
  add('sindrets/diffview.nvim') 
  require('diffview').setup({
    enhanced_diff_hl = true, -- 差分を詳細にハイライト
    view = {
      -- マージ時は自動的に3画面（自分/結果/相手）にする
      merge_tool = {
        layout = "diff3_mixed",
      },
    },
  })

  -- 使いやすいようにキーマップを設定
  -- <leader>gm (Git Merge) でコンフリクト解消画面を開く
  vim.keymap.set('n', '<leader>gm', '<cmd>DiffviewOpen<cr>', { desc = 'Open Diffview (Merge)' })
  -- <leader>gx で解消画面を閉じる
  vim.keymap.set('n', '<leader>gx', '<cmd>DiffviewClose<cr>', { desc = 'Close Diffview' })
end)
