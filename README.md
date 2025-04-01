# lzextras

This repository contains extensions for [`lze`](https://github.com/BirdeeHub/lze#electric_plug-api)

See there for more info on how to use the things here.

This repository contains some custom handlers you may register,
and some utilities you can use to make your life easier,
(or harder but more exciting, in the case of the merge handler)

## Downloading

via [paq-nvim](https://github.com/savq/paq-nvim):

```lua
require "paq" {
    { "BirdeeHub/lzextras" }
}
```

<!-- markdownlint-disable -->
<details>
  <summary>
    <b><a href="https://wiki.nixos.org/wiki/Neovim">Nix examples</a></b>
  </summary>

  - Home Manager:

  ```nix
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins [
      {
        plugin = lze;
        config = /*lua*/''
          -- optional, add extra handlers
          require("lze").register_handlers(require("lzextras").lsp)
        '';
        type = "lua";
      }
      lzextras
    ];
  };
  ```

  - Not on nixpkgs-unstable?

  If your neovim is not on the `nixpkgs-unstable` channel,
  `vimPlugins.lzextras` may not yet be in nixpkgs for you.
  You may instead get it from this flake!
  ```nix
  # in your flake inputs:
  inputs = {
    lzextras.url = "github:BirdeeHub/lzextras";
  };
  ```
  Then, pass your config your inputs from your flake,
  and retrieve `lzextras` with:
  ```nix
  inputs.lzextras.packages.${pkgs.system}.default`:
  ```

</details>
<!-- markdownlint-restore -->

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
```

Useage:

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

## key2spec

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

OR

- A table of LSP settings for the LSP implementations.
  It makes sure the above function type specs load first,
  and the function type spec will run for all table type LSP specs

It auto populates file types from `lspconfig` if you don't include any under `plugin.lsp.filetypes`

It will make sure all specs with functions load before the specs with tables.

- Example useage:

<!-- markdownlint-disable MD013 -->
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
    on_plugin = { "nvim-lspconfig" },
    load = function(name)
      vim.cmd.packadd(name)
      vim.cmd.packadd("mason-lspconfig.nvim")
      require('mason').setup()
      -- auto install will make it install servers when lspconfig is called on them.
      require('mason-lspconfig').setup { automatic_installation = true, }
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
    -- can fall back to using lspconfig to find filetypes
    -- as long as it can be required
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
lspconfig for the list of filetypes, but you can change it.

You can get the current fallback function for getting filetypes using:

```lua
  ---@type fun():(fun(name: string):string[])
  require('lze').h.lsp.get_ft_fallback()
```

and you may set the fallback function for getting filetypes using:

```lua
  ---@type fun(f: fun(name: string):string[])
  require('lze').h.lsp.set_ft_fallback(your_new_function)
```

In addition, you may provide a function instead of a list to `lsp.filetypes`
and it will be the fallback function for that lsp only

## merge

```lua
-- vim.g.lze = vim.g.lze or {}
-- vim.g.lze.injects = vim.g.lze.injects or {}
-- vim.g.lze.injects.merge = true
require("lze").register_handlers(require("lzextras").merge)
```

> [!WARNING]
>
> must be registered before all other handlers with a modify hook
> such as the lsp handler

collects and merges all plugins added with truthy `plugin.merge`
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

> [!NOTE]
>
> If you use [nixCats](https://github.com/BirdeeHub/nixCats-nvim),
> you should provide the following load function as the second argument for better performance
> because `nixCats` provides us information that allows us to avoid searching the whole packpath

```lua
local function faster_get_path(name)
  local path = vim.tbl_get(package.loaded, "nixCats", "pawsible", "allPlugins", "opt", name)
  if path then
    vim.cmd.packadd(name)
    return path
  end
  return nil -- nil will make it default to normal behavior
end
local load_with_after_plugin = require('lzextras').make_load_with_afters({ 'plugin' }, faster_get_path)
```
<!-- markdownlint-enable MD013 -->
