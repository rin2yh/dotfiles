local M = {}

M.cmd = { 'terraform-ls', 'serve'}

M.filetypes = { 'terraform', 'hcl' }
M.root_markers = { '.terraform', '.git', 'main.tf' }

return M
