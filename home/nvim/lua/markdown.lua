-- Markdown 系

local safely = MiniMisc.safely

-- 主なコマンド: :MarpWatch / :MarpStop / :MarpPreview / :MarpExport / :MarpTheme
safely('later', function()
  vim.pack.add({ 'https://github.com/nwiizo/marp.nvim' })
  require('marp').setup({
    -- jobstart は stdin をパイプで開いたままにするため、--no-stdin を付けないと
    -- marp が標準入力待ちでハングして変換もプレビューも始まらない
    marp_command = 'marp',
    server_mode = false,
    suggest_gitignore = false,
  })
end)
