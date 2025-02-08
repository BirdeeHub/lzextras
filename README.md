# lzextras

## ATTENTION: THIS REPO IS IN EARLY DEVELOPMENT

This repository contains additional utilities and handlers for lze

### LSP handler

in the lsp field you can declare:

- a function to run for all LSP specs,
  that recieves the plugin object, (mostly for lspconfig)

OR

- a table of LSP settings which denotes that thing fulfills the LSP,
  and it makes sure the function ones load first
  to be parsed within the functions provided in the first form above.

It auto populates file types from lspconfig if you dont include any under `plugin.lsp.filetypes`

It will make sure all specs with functions load before the specs with tables.

```lua
require('lze').register_handlers(require('lzextras').lsp)
require('lze').load {
  {
    "nvim-lspconfig",
    -- the on require handler will be needed if you want to use the
    -- fallback method of getting filetypes if you don't provide any
    on_require = { "lspconfig" },
    -- define a function to run over all type(plugin.lsp) == table
    -- when their filetype trigger loads them
    lsp = function(plugin)
      require('lspconfig')[plugin.name].setup(vim.tbl_extend("force",{
        capabilities = GET_YOUR_SERVER_CAPABILITIES(plugin.name),
        on_attach = YOUR_ON_ATTACH,
      }, plugin.lsp or {}))
    end,
  },
  {
    "mason.nvim",
    -- dep_of handler ensures we have mason-lspconfig set up before nvim-lspconfig
    dep_of = { "nvim-lspconfig" },
    load = function(name)
      require("birdee.utils").multi_packadd { name, "mason-lspconfig.nvim" }
      require('mason').setup()
      -- auto install will make it install servers when lspconfig is called on them.
      require('mason-lspconfig').setup { automatic_installation = true, }
    end,
  },
  {
    "lua_ls",
    lsp = {
      -- if you include a filetype, it doesnt call lspconfig for the list
      filetypes = { 'lua' },
      settings = {
        Lua = {
          runtime = { version = 'LuaJIT' },
          formatters = {
            ignoreComments = true,
          },
          signatureHelp = { enabled = true },
          diagnostics = {
            globals = { "vim", },
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
    },
  },
  {
    "bashls",
    -- can fall back to using lspconfig to find filetypes
    -- as long as it can be required
    lsp = { },
  },
  {
    "pylsp",
    lsp = {
      -- this lsp "spec" is parsed by that function above in the nvim-lspconfig spec
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
