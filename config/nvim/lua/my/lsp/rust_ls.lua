local M = {}

M.cmd = { 'rust-analyzer' }
M.filetypes = { 'rust' }

M.root_dir = vim.fs.root(0, { 'Cargo.toml', 'rust-project.json', '.git' })

M.settings = {
  ['rust-analyzer'] = {
    -- 保存時のチェックはlinterにしたいので、checkでない
    checkOnSave = true,
    check = {
      command = "clippy",
    },
    -- 補完・インポート関連
    completion = {
      autoimport = { enable = true },
      postfix = { enable = true }, -- .if や .match などの後置補完
    },
    -- 型ヒント (Goのhints設定に近いもの)
    hover = {
      actions = {
        references = { enable = true },
      },
    },
    inlayHints = {
      bindingModeHints = { enable = false },
      chainingHints = { enable = true },      -- メソッドチェーンの型表示
      closingBraceHints = { enable = true },  -- 閉じ括弧の後のヒント
      parameterHints = { enable = true },     -- 引数名の表示
      typeHints = { enable = true },          -- 変数型の表示
    },
    -- マクロ展開やビルドスクリプトの解析（重要）
    procMacro = {
      enable = true,
    },
    cargo = {
      buildScripts = {
        enable = true,
      },
      features = "all", -- 全てのfeatureを有効化して解析
    },
  }
}

return M
