return {
  capabilities = {
    textDocument = {
      completion = {
        completionItem = { snippetSupport = true },
      },
    },
  },
  settings = {
    css = {
      lint = {
        compatibleVendorPrefixes = 'ignore',
        vendorPrefix = 'warning',
        duplicateProperties = 'warning',
      },
    },
    scss = {
      lint = { idSelector = 'warning' },
    },
  },
  init_options = { provideFormatter = false },
}
