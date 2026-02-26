local add, later = MiniDeps.add, MiniDeps.later

later(function()
  add("https://github.com/github/copilot.vim")
end)
