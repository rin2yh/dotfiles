-- Neovim操作ログ記録モジュール
-- ログファイル: ~/.local/state/nvim/oplog.log
-- フォーマット(TSV): UNIX_TIMESTAMP\tMODE\tKEYS\tFILENAME\tFILETYPE

local M = {}

local log_path = vim.fn.stdpath('state') .. '/oplog.log'
local max_size = 1024 * 1024 -- 1MB

local buf = {}
local flush_timer = nil
local FLUSH_DELAY = 500   -- ms
local FLUSH_COUNT = 50    -- 件数

-- インサートモードで記録する特殊キーのパターン
local insert_special_keys = {
  '\27',        -- <Esc>
  '\t',         -- <Tab>
  '\r',         -- <CR>
  '\8',         -- <BS>
  '\127',       -- <Del>
}
for i = 1, 26 do
  insert_special_keys[#insert_special_keys + 1] = string.char(i) -- <C-a> .. <C-z>
end
local insert_special_set = {}
for _, k in ipairs(insert_special_keys) do
  insert_special_set[k] = true
end

local function get_mode_char()
  local m = vim.api.nvim_get_mode().mode
  local c = m:sub(1, 1)
  if c == 'n' then return 'n'
  elseif c == 'v' or c == 'V' or m == '\22' then return 'v'
  elseif c == 'i' then return 'i'
  elseif c == 'c' then return 'c'
  else return c
  end
end

local function escape_key(key)
  return vim.fn.strtrans(key)
end

local function rotate_if_needed()
  local stat = vim.uv.fs_stat(log_path)
  if stat and stat.size > max_size then
    local f = io.open(log_path, 'r')
    if not f then return end
    local content = f:read('*a')
    f:close()
    -- 先頭半分を切り捨てて後半を残す
    local half = math.floor(#content / 2)
    local newline_pos = content:find('\n', half)
    if newline_pos then
      content = content:sub(newline_pos + 1)
    end
    local wf = io.open(log_path, 'w')
    if wf then
      wf:write(content)
      wf:close()
    end
  end
end

local function flush()
  if #buf == 0 then return end
  local lines = buf
  buf = {}
  rotate_if_needed()
  local f = io.open(log_path, 'a')
  if not f then return end
  for _, line in ipairs(lines) do
    f:write(line .. '\n')
  end
  f:close()
end

local function cancel_timer()
  if flush_timer then
    flush_timer:stop()
    flush_timer:close()
    flush_timer = nil
  end
end

local function schedule_flush()
  cancel_timer()
  flush_timer = vim.defer_fn(function()
    flush_timer = nil
    flush()
  end, FLUSH_DELAY)
end

local function record(mode, keys)
  local ts = os.time()
  local filename = vim.fn.expand('%:p')
  local filetype = vim.bo.filetype or ''
  local entry = table.concat({ tostring(ts), mode, escape_key(keys), filename, filetype }, '\t')
  buf[#buf + 1] = entry
  if #buf >= FLUSH_COUNT then
    cancel_timer()
    flush()
  else
    schedule_flush()
  end
end

-- ノーマル・ビジュアルモードのキー記録
vim.on_key(function(key)
  local mode = get_mode_char()
  if mode == 'n' or mode == 'v' then
    if key ~= '' then
      record(mode, key)
    end
  elseif mode == 'i' then
    if insert_special_set[key] then
      record(mode, key)
    end
  end
end)

-- コマンドモードの記録
local group = vim.api.nvim_create_augroup('oplog', { clear = true })
vim.api.nvim_create_autocmd('CmdlineLeave', {
  group = group,
  callback = function()
    local cmdline = vim.fn.getcmdline()
    if cmdline ~= '' then
      record('c', cmdline)
    end
  end,
})

-- 終了時に確実にフラッシュ
vim.api.nvim_create_autocmd('VimLeave', {
  group = group,
  callback = function()
    cancel_timer()
    flush()
  end,
})

return M
