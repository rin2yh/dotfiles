local M = {}

vim.filetype.add({
  filename = {
    ['compose.yaml'] = 'yaml.compose',
    ['compose.yml'] = 'yaml.compose',
    ['docker-compose.yaml'] = 'yaml.compose',
    ['docker-compose.yml'] = 'yaml.compose',
  },
})

M.cmd = { 'docker-language-server', '--stdio' }
M.filetypes = { 'dockerfile', 'yaml.compose' }
M.root_markers = { 'compose.yaml', 'compose.yml', 'docker-compose.yml', 'Dockerfile', '.git' }

return M
