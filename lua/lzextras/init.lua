---@class lzextras.Merge
---merge handler must be registered
---before all other handlers with modify hooks
---@field handler lze.Handler
---add all the collected merged specs to lze
---@field trigger fun()

---@class lzextras.Keymap
---@field set fun(mode:string|string[], lhs:string, rhs:string|function, opts:vim.keymap.set.Opts)

---@class lzextras
---@field key2spec fun(mode:string|string[], lhs:string, rhs:string|function, opts:vim.keymap.set.Opts): lze.KeysSpec
---@field keymap fun(plugin: string|lze.PluginSpec): lzextras.Keymap
---@field make_load_with_afters (fun(dirs: string[]|string): fun(names: string|string[]))|(fun(dirs: string[]|string, load: fun(name: string):string|nil): fun(names: string|string[]))
---@field lsp lze.Handler
---@field merge lzextras.Merge

---@type lzextras
---@diagnostic disable-next-line
local lzextras = {}
setmetatable(lzextras, {
    __index = function(t, k)
        local mod = require("lzextras.src." .. k) -- Load the module
        rawset(t, k, mod) -- Store it directly in the table
        return mod -- Return the loaded module
    end,
})
return lzextras
