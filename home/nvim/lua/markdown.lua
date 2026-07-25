-- Markdown 系

local safely = MiniMisc.safely

-- 主なコマンド: :MarpWatch / :MarpStop / :MarpPreview / :MarpExport / :MarpTheme
safely('later', function()
  vim.pack.add({ 'https://github.com/nwiizo/marp.nvim' })
  require('marp').setup({
    marp_command = 'marp',
    server_mode = false,
    suggest_gitignore = false,
  })
end)
