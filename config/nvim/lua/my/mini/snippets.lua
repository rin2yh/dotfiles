local gen_loader = require('mini.snippets').gen_loader
require('mini.snippets').setup({
  snippets = {
    gen_loader.from_lang(),
  },
  mappings = {
    jump_prev = '<c-k>',
  },
})

MiniSnippets.start_lsp_server({ match = false })
