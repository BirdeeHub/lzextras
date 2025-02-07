---@class lzextras.LspPlugin: lze.Plugin
---@field lsp? any

---@param spec lze.PluginSpec|lze.PluginSpec[]
return function(spec)
    --TODO: replace with:
    -- spec = lze.c.parse(type(spec) == "string" and { import = spec } or spec)
    ---@diagnostic disable-next-line: undefined-field
    spec = type(spec.name or spec[1]) == "string" and { spec } or spec

    if type(spec) == "table" and #spec == 0 then
        vim.notify("no spec provided, exiting", vim.log.levels.ERROR, { title = "lzextras.keymap.set" })
        return
    end

    local to_load = {}
    local funclist = {}
    for _, s in ipairs(spec) do
        ---@diagnostic disable-next-line: undefined-field
        table.insert(to_load, s.name or s[1])
        if s.lsp then
            ---@diagnostic disable-next-line: undefined-field
            table.insert(funclist, s.lsp)
        end
        ---@diagnostic disable-next-line: inject-field
        s.lsp = nil
    end

    require("lze").load(spec)

    ---@type lze.Handler
    local handler = {
        spec_field = "lsp",
        ---@param plugin lzextras.LspPlugin
        modify = function(plugin)
            local lspfield = plugin.lsp
            if type(lspfield) ~= "table" then
                return plugin
            end
            local oldload = plugin.load or function(_) end
            plugin.load = function(name)
                require("lze").trigger_load(to_load)
                oldload(name)
            end
            local oldafter = plugin.after or function(_) end
            plugin.after = function(p)
                for _, f in ipairs(funclist) do
                    f(p)
                end
                oldafter(p)
            end
            local newftlist = type(lspfield.filetypes) == "string" and { lspfield.filetypes }
                or type(lspfield.filetypes) == "table" and lspfield.filetypes
                or nil
            local oldftlist = type(plugin.ft) == "string" and { plugin.ft }
                or type(plugin.ft) == "table" and plugin.ft
                or nil
            if newftlist or oldftlist then
                ---@diagnostic disable-next-line: param-type-mismatch
                plugin.ft = vim.list_extend(newftlist or {}, oldftlist or {})
            else
                plugin.ft = require("lspconfig")[plugin.name].filetypes
            end
            return plugin
        end,
    }
    return handler
end
