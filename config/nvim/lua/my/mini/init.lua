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

