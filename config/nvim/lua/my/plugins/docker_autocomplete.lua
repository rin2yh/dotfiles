local M = {}

local config = {
  filetypes = { 'dockerfile', 'compose-filetype' }, -- デフォルト
  min_word_length = 2,
}

-- filetype判定のみ
local function is_target_filetype(buf)
  local ft = vim.api.nvim_get_option_value('filetype', { buf = buf })
  for _, allowed in ipairs(config.filetypes) do
    if ft == allowed then
      return true
    end
  end
  return false
end

-- LSPが補完提供するか確認
local function has_completion_provider(buf)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    if client.server_capabilities
      and client.server_capabilities.completionProvider then
      return true
    end
  end
  return false
end

-- カーソル直前の単語取得
local function get_word_before_cursor(buf)
  local _, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ''
  local before_cursor = line:sub(1, col)
  return before_cursor:match('%w+$')
end

-- 補完トリガー
local function trigger_completion(buf)
  if vim.fn.pumvisible() == 1 then
    return
  end

  if not is_target_filetype(buf) then
    return
  end

  if not has_completion_provider(buf) then
    return
  end

  local word = get_word_before_cursor(buf)
  if not word or #word < config.min_word_length then
    return
  end

  vim.lsp.buf.completion()
end

-- 設定バリデーション
local function validate_config()
  if type(config.filetypes) ~= 'table' or #config.filetypes == 0 then
    error('[docker_autocomplete] filetypes must be a non-empty table')
  end

  if type(config.min_word_length) ~= 'number'
    or config.min_word_length < 1
    or config.min_word_length ~= math.floor(config.min_word_length) then
    error('[docker_autocomplete] min_word_length must be an integer >= 1')
  end
end

-- setup
function M.setup(opts)
  config = vim.tbl_deep_extend('force', config, opts or {})
  validate_config()

  vim.api.nvim_create_autocmd('TextChangedI', {
    callback = function(args)
      trigger_completion(args.buf)
    end,
  })
end

M.setup()

return M
