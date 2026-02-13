local add, later = MiniDeps.add, MiniDeps.later

add({
  source = 'nvim-treesitter/nvim-treesitter',
  hooks = {
    post_checkout = function()
      vim.cmd.TSUpdate()
    end
  },
})

later(function()
  local status, configs = pcall(require, 'nvim-treesitter.configs')
  if not status then return end

  configs.setup({
    ensure_installed = {
      'lua', 'vim', 'vimdoc', 'query', 'tsx', 'go', 'typescript',
      'html', 'markdown', 'markdown_inline', 'bash', 'terraform',
      'hcl', 'dockerfile'
    },
    auto_install = true,
    highlight = {
      enable = true,
    },
  })
end)
