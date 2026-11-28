-- macOS の入力切り替えは Neovim のキー入力イベントでは検知できないため、
-- フォーカスのある normal mode 中だけ入力ソースを確認する。
if vim.fn.has('mac') == 0 or vim.fn.executable('im-alter') == 0 then
  return
end

local group = vim.api.nvim_create_augroup('ime-auto-off', { clear = true })
local timer = assert(vim.uv.new_timer())
local focused = #vim.api.nvim_list_uis() > 0
local running = false
local can_query = vim.fn.executable('im-select') == 1

local function should_reset()
  return focused and vim.api.nvim_get_mode().mode == 'n'
end

local function select_abc()
  vim.system({ 'im-alter', 'abc' }, {}, function()
    running = false
  end)
end

local function reset_ime()
  if not should_reset() or running then
    return
  end
  running = true
  if not can_query then
    select_abc()
    return
  end
  vim.system({ 'im-select' }, { text = true }, vim.schedule_wrap(function(result)
    -- 確認中に insert mode や別アプリへ移った場合は切り替えない。
    if not should_reset() or result.code ~= 0 or vim.trim(result.stdout or '') == ''
        or vim.trim(result.stdout) == 'com.apple.keylayout.ABC' then
      running = false
      return
    end
    select_abc()
  end))
end

local function update()
  timer:stop()
  if focused and vim.api.nvim_get_mode().mode == 'n' then
    reset_ime()
    -- 照会コマンドがない環境ではモード・フォーカス変更時だけ戻す。
    if can_query then
      timer:start(100, 100, vim.schedule_wrap(reset_ime))
    end
  end
end

vim.api.nvim_create_autocmd({ 'UIEnter', 'FocusGained' }, {
  group = group,
  callback = function()
    focused = true
    update()
  end,
})

vim.api.nvim_create_autocmd('FocusLost', {
  group = group,
  callback = function()
    focused = false
    timer:stop()
  end,
})

vim.api.nvim_create_autocmd('ModeChanged', {
  group = group,
  callback = update,
})

vim.api.nvim_create_autocmd('VimLeavePre', {
  group = group,
  callback = function()
    focused = false
    timer:stop()
    timer:close()
  end,
})

update()
