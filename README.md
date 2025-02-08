# lzextras

## ATTENTION: THIS REPO IS IN EARLY DEVELOPMENT

This repository contains additional utilities and handlers for lze

### LSP handler

in the lsp field you can declare:

- a function to run for all lsps that recieves the plugin object, (mostly for lspconfig)

OR

- a table of lsp settings which denotes that thing is an lsp,
  and it makes sure the function ones load first
  to be parsed within the functions provided in the first form above.

It auto populates file types from lspconfig if you dont include any under `plugin.lsp.filetypes`

It will make sure all specs with functions load before the specs with tables.

```lua
require('lze').register_handlers(require('lzextras').lsp)
require('lze').load {
  {
    "mason.nvim",
    enabled = not catUtils.isNixCats,
    dep_of = { "nvim-lspconfig" },
    load = function(name)
      require("birdee.utils").multi_packadd { name, "mason-lspconfig.nvim" }
      require('mason').setup()
      require('mason-lspconfig').setup { automatic_installation = true, }
    end,
  },
  {
    "nvim-lspconfig",
    for_cat = "general.core",
    on_require = { "lspconfig" },
    lsp = function(plugin)
      require('lspconfig')[plugin.name].setup(vim.tbl_extend("force",{
        capabilities = require('birdee.LSPs.caps_and_attach').get_capabilities(plugin.name),
        on_attach = require('birdee.LSPs.caps_and_attach').on_attach,
      }, plugin.lsp or {}))
    end,
  },
  {
    "lua_ls",
    enabled = nixCats('lua') or nixCats('neonixdev'),
    lsp = {
      settings = {
        Lua = {
          runtime = { version = 'LuaJIT' },
          formatters = {
            ignoreComments = true,
          },
          signatureHelp = { enabled = true },
          diagnostics = {
            globals = { "nixCats", "vim", "make_test" },
            disable = { 'missing-fields' },
          },
          workspace = {
            checkThirdParty = false,
            library = {
              -- '${3rd}/luv/library',
              -- unpack(vim.api.nvim_get_runtime_file('', true)),
            },
          },
          completion = {
            callSnippet = 'Replace',
          },
          telemetry = { enabled = false },
        },
      },
      filetypes = { 'lua' },
    },
  },
  {
    "bashls",
    lsp = { },
  },
  {
    "pylsp",
    lsp = {
      filetypes = { "python" },
      settings = {
        pylsp = {
          plugins = {
            -- formatter options
            black = { enabled = false },
            autopep8 = { enabled = false },
            yapf = { enabled = false },
            -- linter options
            pylint = { enabled = true, executable = "pylint" },
            pyflakes = { enabled = false },
            pycodestyle = { enabled = false },
            -- type checker
            pylsp_mypy = { enabled = true },
            -- auto-completion options
            jedi_completion = { fuzzy = true },
            -- import sorting
            pyls_isort = { enabled = true },
          },
        },
      },
    },
  },
}
```
