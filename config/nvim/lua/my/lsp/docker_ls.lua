local M = {}

M.cmd = { 'docker-language-server', 'start', '--stdio' }
M.filetypes = { 'dockerfile', 'yaml.docker-compose' }
M.root_markers = { 'Dockerfile', 'docker-compose.yml', 'docker-compose.yaml', 'compose.yml', 'compose.yaml', '.git' }

return M
