-- Clone 'mini.nvim' manually in a way that it gets managed by 'mini.deps'
local path_package = vim.fn.stdpath('data') .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.nvim'
if not vim.uv.fs_stat(mini_path) then
  vim.cmd('echo "Installing `mini.nvim`" | redraw')
  local clone_cmd = {
    'git', 'clone', '--filter=blob:none',
    'https://github.com/echasnovski/mini.nvim', mini_path
  }
  vim.fn.system(clone_cmd)
  vim.cmd('packadd mini.nvim | helptags ALL')
  vim.cmd('echo "Installed `mini.nvim`" | redraw')
end

-- Set up 'mini.deps' (customize to your liking)
require('mini.deps').setup({ path = { package = path_package } })

-- Simple plugins (now)
for _, name in ipairs({ 'icons', 'basics', 'starter' }) do
  MiniDeps.now(require('mini.' .. name).setup)
end

-- Simple plugins (later)
for _, name in ipairs({ 'indentscope', 'pairs', 'diff', 'jump2d', 'bracketed' }) do
  MiniDeps.later(require('mini.' .. name).setup)
end

-- Plugins with custom settings
require('my.mini.statusline')
require('my.mini.notify')
require('my.mini.misc')
require('my.mini.hipatterns')
require('my.mini.files')
require('my.mini.pick')
require('my.mini.completion')
require('my.mini.snippets')
require('my.mini.trailspace')
require('my.mini.git')
require('my.mini.clue')

require('my.plugins')

-- disable unused plugin
MiniDeps.now(function()
  local default_rtp = vim.opt.runtimepath:get()
  vim.opt.runtimepath:remove(vim.env.VIMRUNTIME)
  vim.api.nvim_create_autocmd("SourcePre", {
    pattern = "*/plugin/*",
    once = true,
    callback = function()
      vim.opt.runtimepath = default_rtp
    end
  })
end)
