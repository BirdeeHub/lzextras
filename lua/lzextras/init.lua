---@class lzextras.MergePlugin: lze.Plugin
---@field merge? boolean

---merge handler must be registered
---before all other handlers with modify hooks
---@class lzextras.MergeHandler: lze.Handler
---
---add all the collected merged specs to lze
---@field trigger fun()

---@class lzextras.LspPlugin: lze.Plugin
---@field lsp? fun(plugin: lzextras.LspPlugin)|vim.lsp.ClientConfig|lspconfig.Config

---@class lzextras.LspHandler: lze.Handler
---@field ft_fallback fun(name: string): string[]

---@class lzextras.Keymap
---@field set fun(mode:string|string[], lhs:string, rhs:string|function, opts:vim.keymap.set.Opts)

---@class lzextras
---@field key2spec fun(mode:string|string[], lhs:string, rhs:string|function, opts:vim.keymap.set.Opts): lze.KeysSpec
---@field keymap fun(plugin: string|lze.PluginSpec): lzextras.Keymap
---@field make_load_with_afters (fun(dirs: string|string[]|fun(afterpath: string, name: string):string[]): fun(names: string|string[]))|(fun(dirs: (string|string[]|fun(afterpath: string, name: string):string[]), load: fun(name: string):string|nil): fun(names: string|string[]))
---@field lsp lzextras.LspHandler
---@field merge lzextras.MergeHandler

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
