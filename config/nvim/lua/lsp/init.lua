-- config of lsp

local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

now(function()
  add("pcolladosoto/tinygo.nvim")
  local tinygo = require("tinygo")
  tinygo.setup({})

  -- tinygo.nvim の applyConfigFile は .tinygo.json を相対パスで開くため、
  -- nvim の cwd がプロジェクト外だと検出漏れする。バッファから上向き探索し
  -- 絶対パスで読み取って TinyGoSetTarget を直接呼ぶ。
  tinygo.applyConfigFile = function()
    local bufname = vim.api.nvim_buf_get_name(0)
    local found = vim.fs.find(tinygo.config_file, {
      upward = true,
      path = bufname ~= "" and vim.fs.dirname(bufname) or nil,
    })
    if #found == 0 then return end
    local f = io.open(found[1], "r")
    if not f then return end
    local raw = f:read("a")
    f:close()
    local ok, cfg = pcall(vim.json.decode, raw)
    if not ok or type(cfg) ~= "table" or not cfg.target then return end
    vim.cmd.TinyGoSetTarget(cfg.target)
  end

  -- applyConfigFile は vim.lsp.enable(lsp_names) より後に走らせる必要がある。
  -- tinygo.setup() で登録される LspAttach autocmd が gopls attach 時に拾って
  -- くれるが、取りこぼし保険として main 完了後にも明示実行する。
  vim.schedule(function() pcall(tinygo.applyConfigFile) end)
end)

vim.diagnostic.config({
  virtual_text = true,
})

vim.api.nvim_create_user_command(
  'LspHealth',
  'checkhealth vim.lsp',
  { desc = 'LSP health check' })

-- augroup for this config file
local augroup = vim.api.nvim_create_augroup('lsp/init.lua', {})

-- format
vim.api.nvim_create_autocmd('LspAttach', {
  group = augroup,
  callback = function(args)
    vim.keymap.set('n', 'grd', function()
      vim.lsp.buf.definition()
    end, { buffer = args.buf, desc = 'vim.lsp.buf.definition()' })

    vim.keymap.set('n', '<M-f>', function()
      vim.lsp.buf.format({ bufnr = args.buf })
    end, { buffer = args.buf, desc = 'Format buffer' })

    vim.keymap.set('n', '<space>w', vim.lsp.buf.code_action,
      { buffer = args.buf, desc = 'LSP code action' })
  end,
})

vim.lsp.config('*', {
  root_markers = { '.git' },
})

vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'LSP hover information' })
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local opts = { buffer = args.buf }

    -- hoverを実行する時に直接UI設定を渡す
    vim.keymap.set('n', 'K', function()
      vim.lsp.buf.hover({ border = "rounded" })
    end, opts)
  end,
})
-- load lsp/lua_ls.lua
local dirname = vim.fn.stdpath('config') .. '/lua/lsp'

-- 設定したlspを保存する配列
local lsp_names = {}

-- 同一ディレクトリのファイルをループ
for file, ftype in vim.fs.dir(dirname) do
  if ftype == 'file' and vim.endswith(file, '.lua') and file ~= 'init.lua' then
    local lsp_name = file:sub(1, -5)
    local ok, result = pcall(require, 'lsp/' .. lsp_name)
    if ok then
      vim.lsp.config(lsp_name, result)
      table.insert(lsp_names, lsp_name)
    else
      vim.notify('Error loading LSP: ' .. lsp_name .. '\n' .. result, vim.log.levels.WARN)
    end
  end
end

vim.lsp.enable(lsp_names)
