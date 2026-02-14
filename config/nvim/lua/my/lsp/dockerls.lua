local M = {}

M.cmd = { 'docker-language-server', '--stdio' }
M.filetypes = { 'dockerfile' }
M.root_markers = { 'Dockerfile', '.git' }

return M
