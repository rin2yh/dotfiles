local M = {}

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

return M
