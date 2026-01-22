# lzextras

This repository contains extensions for [`lze`](https://github.com/BirdeeHub/lze#electric_plug-api)

See there for more info on how to use the things here.

This repository contains some custom handlers you may register,
and some utilities you can use to make your life easier,
(or harder but more exciting, in the case of the merge handler)

## Installation

This plugin is `lua` only!

Any way you can add it to your `vim.o.runtimepath` will work!
<!-- markdownlint-disable -->
```lua
vim.pack.add({
  'https://github.com/BirdeeHub/lze',
  'https://github.com/BirdeeHub/lzextras',
})
setmetatable(require('lze'), getmetatable(require('lzextras')))
---@type lzextras | lze
local lze = require('lze')
-- register any handlers from lzextras you want
lze.register_handlers(lze.lsp)
-- or call functions!
lze.debug.display(-lze.state)
-- you can of course still use it directly
require('lzextras').debug.display(-lze.state)
```
<!-- markdownlint-restore -->
It also lazily loads itself.

## loaders

`lzextras` offers a few alternate load functions that
you can use instead of the `vim.cmd.packadd`
function that `lze` uses as the default loading function

```lua
require('lzextras').loaders
```

contains the following functions:

```lua
---Calls `packadd` on `name` and on `name .. "/after"`
---@type fun(name: string)
require('lzextras').loaders.with_after
---calls packadd on a list of names
---@type fun(names: string|string[])
require('lzextras').loaders.multi
---calls packadd on a list of names and their "after" directories
---@type fun(string|string[])
require('lzextras').loaders.multi_w_after
---For debugging your setup.
---set vim.g.lze.load = require("lzextras").loaders.debug_load
---And it will warn if the plugin was not found and added to the runtimepath,
---even when the plugin was not loaded at startup
---Will only run for specs that do not replace their default load function
---@type fun(name: string)
require('lzextras').loaders.debug_load
```

Usage:

```lua
require("lze").load {
  "cmp-buffer",
  on_plugin = { "nvim-cmp" },
  load = require("lzextras").loaders.with_after,
}
```

```lua
require("lze").load {
  "nvim-treesitter",
  event = "DeferredUIEnter",
  dep_of = { "treesj", "otter.nvim", "render-markdown", "neorg" },
  load = function(name)
    require("lzextras").loaders.multi {
      name,
      "nvim-treesitter-textobjects",
    }
  end,
  after = function (_)
    -- treesitter config here...
  end,
}
```

## debug

`debug.display` is a general purpose display function

It sets up a popup window that contains the input.

If input is a string, filetype defaults to `nil`.

If it is not, filetype defaults to `lua` and `vim.inspect` is called on it.

The hook argument runs in that window after creation.

It is mostly for use in the `neovim` command line.

```lua
---@type fun(input, hook: fun(buf: integer, win: integer))
local display = require("lzextras").debug.display
display({ "some", "lua", "value")
display("some string value")
```

`debug.show_state` uses display to display the current state of `lze`

```lua
function M.show_state()
    local splitres = { deferred = {}, loaded = {} }
    for key, value in pairs(-require("lze").state) do
        splitres[value and "deferred" or "loaded"][key] = value
    end
    M.display(
        "-- LZE STATE DISPLAY\n\nloaded = "
            .. vim.inspect(splitres.loaded)
            .. "\n\ndeferred = "
            .. vim.inspect(splitres.deferred),
        function(buf)
            vim.bo[buf].filetype = "lua"
        end
    )
end
```

## key2spec

Converts the normal `vim.keymap.set` syntax into an item
to put in the list of keys in a lze spec

```lua
require("lze").load {
    name = plugin_name,
    keys = {
        require("lzextras").key2spec(mode, lhs, rhs, opts),
    },
}
```

## keymap

Allows you to add keymap triggers to plugins from outside of their specs,
after the spec has been added to `lze`. Useful for if you have a lot of keymaps
that involve plugins but you don't want to rewrite them all.

```lua
local keymap = require("lzextras").keymap {
    name = plugin_name,
    lazy = true,
}

-- The normal keymap.set syntax
keymap.set("n", "<leader>l", function()end, { desc = "Lazy" })

-- OR

-- if the spec has already been loaded into state
require("lze").load {
    name = plugin_name,
    lazy = true,
}

local keymap = require("lzextras").keymap(plugin_name)

-- The normal keymap.set syntax
keymap.set("n", "<leader>l", function()end, { desc = "Lazy" })
```

## LSP handler

In the `lsp` field you can declare:

- A function to run for all LSP specs,
  that receives the plugin object, (mostly for `lspconfig`)
  - `priority`, while normally not doing anything for
    lazy plugins, affects the order these functions are called

OR

- A table of LSP settings for the LSP implementations.
  It makes sure the above function type specs load first,
  and the function type spec will run for all table type LSP specs

It auto populates file types from `lspconfig` if you don't include any under `plugin.lsp.filetypes`

It will make sure all specs with functions load before the specs with tables.

The reason this is included, is that calling enable
on a lot of LSP implementations on startup
has a fairly reasonable startup time performance impact.

This allows you to only call enable for the configurations
pertaining to the filetypes you open.

- Example usage:

<!-- markdownlint-disable MD013 -->
```lua
require('lze').register_handlers(require('lzextras').lsp)
require('lze').load {
  {
    "mason.nvim",
    -- priority also affects the order the functions are called in.
    -- make sure this runs before the function from nvim-lspconfig's spec
    priority = 55,
    on_plugin = { "nvim-lspconfig" },
    lsp = function(plugin)
      vim.cmd.MasonInstall(plugin.name)
    end,
  },
  {
    "nvim-lspconfig",
    priority = 50,
    lsp = function(plugin)
      vim.lsp.config(plugin.name, plugin.lsp or {})
      vim.lsp.enable(plugin.name)
    end,
    before = function(plugin)
      vim.lsp.config('*', {
        -- capabilities = capabilities,
        on_attach = function(client, bufnr)
          -- Your on_attach function should set buffer-local lsp related settings
          local nmap = function(keys, func, desc)
            if desc then desc = 'LSP: ' .. desc end
            vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
          end
          nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
          -- etc...
        end,
      })
    end,
  },
  {
    "lua_ls",
    lsp = {
      -- if you include a filetype, it doesnt call lspconfig for the list of filetypes (faster)
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
    -- can fall back to using the regular method to find filetypes
    -- but at a performance cost
    lsp = { },
  },
  {
    "pylsp",
    lsp = {
      -- these lsp "specs" are ran by that function above in the nvim-lspconfig spec
      -- only the filetype trigger is handled by the handler.
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
<!-- markdownlint-enable MD013 -->

The default fallback for getting filetypes calls
the slow thing we are trying to avoid,
`vim.lsp.configs[name].filetypes`, but you can change it.

This means if you want to see any startup time benefit from this handler,
you must provide a filetype for the item, and/or redefine this fallback function,

You can get the current fallback function for getting filetypes using:

```lua
  ---@type fun():(fun(name: string):string[])
  require('lze').h.lsp.get_ft_fallback()
```

And you may set the fallback function for getting filetypes using:

```lua
  ---@type fun(f: fun(name: string):string[])
  require('lze').h.lsp.set_ft_fallback(your_new_function)
```

In addition, you may provide a function instead of a list to `lsp.filetypes`
and it will be the fallback function for that LSP only

> [!TIP]
>
> For ensuring maximum performance, you may want to change
> the filetype fallback function to throw an error instead!
> This will ensure you provide filetypes for each server!

```lua
  require('lze').h.lsp.set_ft_fallback(function(name)
    error("No filetypes provided for " .. name)
  end)
  return {
    -- your specs here
  }
```

## merge

```lua
-- vim.g.lze = vim.g.lze or {}
-- vim.g.lze.injects = vim.g.lze.injects or {}
-- vim.g.lze.injects.merge = true
require("lze").register_handlers(require("lzextras").merge)
```

> [!WARNING]
>
> Must be registered BEFORE all other handlers with a `modify` hook
> such as the `lsp` handler

Collects and merges all plugins added with truthy `plugin.merge`
until triggered to load it into lze's state

can be triggered for a single plugin by explicitly passing `merge = false`
for a plugin, or by calling `require("lze").h.merge.trigger()`:

```lua
require("lze").load {
  "merge_target",
  merge = false,
}
-- OR
require("lze").h.merge.trigger()
```

In other words, doing the following would not queue it to be triggered yet,
but rather cause the merge handler to collect and merge them.

```lua
require("lze").load({
  {
    "merge_target",
    merge = true,
    dep_of = { "lspconfig" },
    lsp = { filetypes = {} },
  },
  {
    "merge_target",
    merge = true,
    dep_of = { "not_lspconfig" },
    lsp = { settings = {} },
  },
})
```

Then, to enter the merged plugin into `lze`,
you may either use `require("lze").h.merge.trigger()`
to finalize all plugins currently collected by the merge handler,
or you may finalize them individually by passing a spec with `merge = false`
explicitly like so:

```lua
require("lze").load({
  {
    "merge_target",
    merge = false,
  }
})
```

the resulting plugin `merge_target` from these examples entered into state will be:

```lua
{
  name = "merge_target",
  dep_of = { "not_lspconfig" },
  lsp = {
    settings = {},
    filetypes = {},
  },
}
```

If you enter a plugin with no merge field into `lze` that
shares the name of one currently held in the merge handler,
it will refuse the duplicate plugin when you
trigger the merge handler to add it to `lze`.

So be sure to know which plugins
you allow to be merged and which ones you do not!

## make_load_with_afters

This is useful for FORCING specific after directories or files
of plugins to be sourced when `packadd`ing a plugin

> [!WARNING]
>
> This function is somewhat complicated and in almost every situation
> you will be better off using one of the load functions
> provided by:

```lua
require('lzextras').loaders
--such as
---@type fun(name: string)
require('lzextras').loaders.with_after
-- or
---@type fun(names: string|string[])
require('lzextras').loaders.multi_w_after
```

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
local load_with_after_plugin = require('lzextras').make_load_with_afters({ 'plugin', 'ftplugin', })
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

--- dirs can also be a function that takes the path to the after directory and name of the plugin and returns a list of files to load.
---@overload fun(dirs: fun(afterpath: string, name: string):string[]): fun(names: string|string[])
---@overload fun(dirs: fun(afterpath: string, name: string):string[], load: fun(name: string):string|nil): fun(names: string|string[])
```
