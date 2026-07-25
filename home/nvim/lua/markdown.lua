-- Markdown 系

local safely = MiniMisc.safely

-- Marp (Markdown プレゼン) のライブプレビュー / エクスポート。
-- marp 本体は mise の `aqua:marp-team/marp-cli` で PATH に入る想定。
-- 主なコマンド: :MarpWatch / :MarpStop / :MarpPreview / :MarpExport / :MarpTheme
safely('later', function()
  vim.pack.add({ 'https://github.com/nwiizo/marp.nvim' })
  require('marp').setup({
    marp_command = 'marp',
    -- `-s` (server) ではなく `--watch` モード。保存すると HTML が再生成される。
    server_mode = false,
    -- エクスポート後に .gitignore への追加を促されるのは不要
    suggest_gitignore = false,
  })
end)
