---@class lzextras.LspPlugin: lze.Plugin
---@field lsp? any

---@param spec string|lze.Spec
return function(spec)
    ---parse with only 1 argument will not call handler is_lazy or run_modify
    ---So this is performant to call without much duplicated work.
    ---It will also filter out disabled plugins for us
    ---@diagnostic disable-next-line: param-type-mismatch
    spec = require("lze.c.parse")(type(spec) == "string" and { import = spec } or spec)
    if spec == {} then
        vim.notify("no spec provided, exiting", vim.log.levels.ERROR, { title = "lzextras.keymap.set" })
        return
    end

    local to_load = {}
    local funclist = {}
    ---@param s lzextras.LspPlugin
    for _, s in ipairs(spec) do
        table.insert(to_load, s.name)
        if s.lsp then
            table.insert(funclist, s.lsp)
        end
        s.lsp = nil
    end

    require("lze").load(spec)

    ---@type lze.Handler
    local handler = {
        spec_field = "lsp",
        ---@param plugin lzextras.LspPlugin
        modify = function(plugin)
            local lspfield = plugin.lsp
            if not lspfield then
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
                local ok, lspconfig = pcall(require, "lspconfig")
                if ok then
                    plugin.ft = lspconfig[plugin.name].config_def.default_config.filetypes
                end
            end
            return plugin
        end,
    }
    return handler
end
