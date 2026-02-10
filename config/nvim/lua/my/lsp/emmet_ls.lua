local M = {}

M.name = 'emmet-language-server'
M.cmd = { 'emmet-language-server', '--stdio' }

M.init_options = {
  showAbbreviationSuggestions = true,
  showExpandedAbbreviation = "always",
  includeLanguages = {
    typescriptreact = "html",
    javascriptreact = "html",
  },
  preferences = {
    ["jsx.enabled"] = true,
    ["markup.attributes"] = {
      class = "className",
      ["for"] = "htmlFor",
    },
  },
}

M.root_patterns = { 'package.json', '.git' }
M.filetypes = { 'typescriptreact', 'javascriptreact', 'html', 'css' }

return M
