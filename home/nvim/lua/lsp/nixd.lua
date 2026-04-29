local M = {}

M.cmd = { 'nixd' }
M.filetypes = { 'nix' }
M.root_markers = { 'flake.nix', '.git' }

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
