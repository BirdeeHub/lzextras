---@class lzextras.MergePlugin: lze.Plugin
---@field merge? boolean

---@class lzextras.LspPlugin: lze.Plugin
---@field lsp? fun(plugin: lzextras.LspPlugin)|vim.lsp.ClientConfig|lspconfig.Config

---@class lzextras.Keymap
---@field set fun(mode:string|string[], lhs:string, rhs:string|function, opts:vim.keymap.set.Opts)

---@class lzextras.Debug
---Sets up a popup window that contains the input.
---hook runs in that window after creation.
---if input is a string, filetype defaults to nil
---if input is not a string, filetype defaults to "lua" and vim.inspect is called on it
---@field display fun(input, hook: fun(buf: integer, win: integer))
---Uses display to display the current state of lze
---@field show_state fun()

---@class lzextras.Loaders
---calls packadd on both name and name .. "/after"
---for lazily loading plugins that rely on their after directory being sourced.
---@field with_after fun(name: string)
---packadd, but accepts a list.
---@field multi fun(names: string|string[])
---Same as with_after, but also accepts a list!
---@field multi_w_after fun(names: string|string[])
---For debugging your setup.
---set vim.g.lze.load = require("lzextras").loaders.debug_load
---And it will warn if the plugin was not found and added to the runtimepath,
---even when the plugin was not loaded at startup.
---@field debug_load fun(name: string)

---@class lzextras
---converts the normal vim.keymap.set arguments into a lze.KeysSpec
---@field key2spec fun(mode:string|string[], lhs:string, rhs:string|function, opts:vim.keymap.set.Opts): lze.KeysSpec
---Returns { set = function(mode, lhs, rhs, opts) }
---For adding key triggers to an already registered lze plugin spec
---from anywhere in your configuration using the normal keymap syntax
---@field keymap fun(plugin: string|lze.PluginSpec): lzextras.Keymap
---Contains a few useful loading functions to use to replace the default vim.g.lze.load = vim.cmd.packadd
---@field loaders lzextras.Loaders
---A function which takes a module name and returns a list of import specs.
---The return value is a valid spec you can pass to lze
---@field mod_dir_to_spec fun(modname: string, filter?: fun(name: string):boolean): lze.SpecImport[]
---A handler that allows loading lsps within lze specs
---@field lsp lze.Handler
---A handler that allows for specs to be merged until you decide to trigger them to be added to lze
---@field merge lze.Handler
---Useful debug display functions
---@field debug lzextras.Debug
---You probably dont need this function and would be better off using one from lzextras.loaders
---Allows forcefully loading your choice of after directories of plugins
---@field make_load_with_afters (fun(dirs: string|string[]|fun(afterpath: string, name: string):string[]): fun(names: string|string[]))|(fun(dirs: (string|string[]|fun(afterpath: string, name: string):string[]), load: fun(name: string):string|nil): fun(names: string|string[]))

---@type lzextras
---@diagnostic disable-next-line
local lzextras = {}
setmetatable(lzextras, {
    __index = function(t, k)
        local mod = require("lzextras.src." .. k)
        rawset(t, k, mod)
        return mod
    end,
})
return lzextras
