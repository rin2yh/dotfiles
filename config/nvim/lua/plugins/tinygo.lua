local add, later = MiniDeps.add, MiniDeps.later

later(function()
  add("pcolladosoto/tinygo.nvim")
  require("tinygo").setup({})
end)
