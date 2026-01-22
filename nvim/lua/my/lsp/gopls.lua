local M = {}

M.cmd = { 'gopls' }
M.filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' }

M.settings = {
  gopls = {
    analyses = {
      unusedparams = true,
      shadow = true,
    },
    staticcheck = true,
    gofumpt = true,
  }
}

return M
