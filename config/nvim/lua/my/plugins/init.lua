local plugin_dir = vim.fn.stdpath('config') .. '/lua/my/plugins'

for _, file in ipairs(vim.fn.readdir(plugin_dir)) do
  local name = file:match('^(.+)%.lua$')
  if name and name ~= 'init' then
    require('my.plugins.' .. name)
  end
end
