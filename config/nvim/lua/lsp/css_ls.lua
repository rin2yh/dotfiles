local M = {}

M.cmd = { 'vscode-css-language-server', '--stdio' }
M.filetypes = { 'css', 'scss', 'less' }
M.root_markers = { 'package.json', '.git' }

M.capabilities = vim.lsp.protocol.make_client_capabilities()
M.capabilities.textDocument.completion.completionItem.snippetSupport = true

M.settings = {
  css = {
    validate = true,
    -- CSS固有の静的解析
    lint = {
      compatibleVendorPrefixes = "ignore",
      vendorPrefix = "warning",
      duplicateProperties = "warning",
    }
  },
  scss = {
    validate = true,
    lint = {
      idSelector = "warning",
    }
  },
  less = {
    validate = true,
  }
}

M.init_options = {
  provideFormatter = false
}

return M
