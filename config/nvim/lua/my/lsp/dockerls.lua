local M = {}

M.cmd = { 'docker-language-server', '--stdio' }
M.filetypes = { 'dockerfile', 'yaml.compose' }
M.root_markers = { 'compose.yaml', 'compose.yml', 'docker-compose.yml', 'Dockerfile', '.git' }

return M
