# lzextras

## ATTENTION: THIS REPO IS IN EARLY DEVELOPMENT

This repository contains extensions for [`lze`](https://github.com/BirdeeHub/lze#electric_plug-api)

See there for more info on how to use the things here,
there are some custom handlers you may register,
and some utilities you can use to make your life easier.

---

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

---

### key2spec

converts the normal `vim.keymap.set` syntax into an item
to put in the list of keys in a lze spec

```lua
require("lze").load {
    name = plugin_name,
    keys = {
        require("lzextras").key2spec(mode, lhs, rhs, opts),
    },
}
```

---

### keymap

```lua
local keymap = require("lze").keymap {
    name = plugin_name,
    lazy = true,
}

keymap.set("n", "<leader>l", function()end, { desc = "Lazy" })

-- OR

-- if the spec has already been loaded into state
require("lze").load {
    name = plugin_name,
    lazy = true,
}

local keymap = require("lze").keymap(plugin_name)

keymap.set("n", "<leader>l", function()end, { desc = "Lazy" })
```

---

### make_load_with_afters

This is primarily useful for lazily loading nvim-cmp sources,
as they often rely on the after directory to work

> [!NOTE]:
> if you use [nixCats](https://github.com/BirdeeHub/nixCats-nvim),
> you should keep using the one from the luaUtils
> template as nixCats provides it information that allows it to be faster.

`vim.cmd.packadd(plugin_name)` does not load the after directory of plugins
but we can replace the load function used by our specs!

This function receives the names of directories
from a plugin's after directory
that you wish to source files from.

Will return load function that can take a name, or list of names,
and will load a plugin and its after directories.
The function returned is a suitable substitute for the load field of a plugin spec.

e.g. in the following example:
load_with_after_plugin will load the plugin names it is given,
along with their `after/plugin` and `after/ftplugin` directories.

<!-- markdownlint-disable MD013 -->
```lua
local load_with_after_plugin = require('lzextras').make_load_with_after({ 'plugin', 'ftplugin', })
require("lze").load {
    name = plugin_name,
    lazy = true,
    load = load_with_after_plugin,
}
require("lze").trigger_load(plugin_name)
```
<!-- markdownlint-enable MD013 -->

- signature:

It is a function that returns a customized load function.

<!-- markdownlint-disable MD013 -->
```lua
---@overload fun(dirs: string[]|string): fun(names: string|string[])
---It also optionally recieves a function that should load a plugin and return its path
---for if the plugin is not on the packpath, or return nil
---to load from the packpath as normal
---@overload fun(dirs: string[]|string, load: fun(name: string):string|nil): fun(names: string|string[])
```
<!-- markdownlint-enable MD013 -->
---

### merge

#### EXPERIMENTAL

```lua
require("lze").register_handlers(require("lzextras").merge)
```

collects and merges all plugins added with truthy `plugin.merge`
until triggered to load it into lze's state

can be triggered for a single plugin by explicitly passing `merge = false`
for a plugin, or by calling `require("lzextras").merge.trigger()`
