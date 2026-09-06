local M = {}

M.settings = {
  nixd = {
    nixpkgs = {
      expr = 'import <nixpkgs> { }',
    },
    formatting = {
      command = { 'nixfmt' },
    },
  },
}

return M
