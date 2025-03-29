---@class lzextras.MergePlugin: lze.Plugin
---@field merge? boolean

---@class lzextras.LspPlugin: lze.Plugin
---@field lsp? fun(plugin: lzextras.LspPlugin)|vim.lsp.ClientConfig|lspconfig.Config

---@class lzextras.Keymap
---@field set fun(mode:string|string[], lhs:string, rhs:string|function, opts:vim.keymap.set.Opts)

---@class lzextras.Loaders
---@field with_after fun(name: string)
---@field multi fun(names: string|string[])
---@field multi_w_after fun(names: string|string[])

---@class lzextras
---@field key2spec fun(mode:string|string[], lhs:string, rhs:string|function, opts:vim.keymap.set.Opts): lze.KeysSpec
---@field keymap fun(plugin: string|lze.PluginSpec): lzextras.Keymap
---@field loaders lzextras.Loaders
---@field make_load_with_afters (fun(dirs: string|string[]|fun(afterpath: string, name: string):string[]): fun(names: string|string[]))|(fun(dirs: (string|string[]|fun(afterpath: string, name: string):string[]), load: fun(name: string):string|nil): fun(names: string|string[]))
---@field lsp lze.Handler
---@field merge lze.Handler

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
