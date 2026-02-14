local M = {}

M.cmd = { 'docker-langserver', '--stdio' }
M.filetypes = { 'dockerfile' }
M.root_markers = { 'Dockerfile', '.git' }

return M
