vim.filetype.add({
  filename = {
    ['docker-compose.yml'] = 'yaml.docker-compose',
    ['docker-compose.yaml'] = 'yaml.docker-compose',
    ['compose.yml'] = 'yaml.docker-compose',
    ['compose.yaml'] = 'yaml.docker-compose',
  },
})

local M = {}

M.cmd = { 'docker-language-server', 'start', '--stdio' }
M.filetypes = { 'dockerfile', 'yaml.docker-compose' }
M.root_markers = { 'Dockerfile', 'docker-compose.yml', 'docker-compose.yaml', 'compose.yml', 'compose.yaml', '.git' }

M.get_language_id = function(_, filetype)
  local map = {
    ['yaml.docker-compose'] = 'dockercompose',
  }
  return map[filetype] or filetype
end

return M
