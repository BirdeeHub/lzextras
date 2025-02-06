---@class lzextras.LspPlugin: lze.Plugin
---@field lsp? any

-- TODO: this sux
-- this will have to change
return function(auto_ft, default_args)
    ---@type lze.Handler
    local handler = {
        spec_field = "lsp",
        ---@param plugin lzextras.LspPlugin
        modify = function(plugin)
            local lspfield = plugin.lsp
            if not lspfield then
                return plugin
            end
            if type(lspfield) ~= "table" then
                vim.notify(
                    'lsp spec for "' .. plugin.name .. '" failed, lsp field must be a table',
                    vim.log.levels.ERROR,
                    { title = "lzextras.lsp" }
                )
                return plugin
            end
            lspfield = vim.tbl_deep_extend("force", default_args, lspfield)
            plugin.load = function(name)
                require("lspconfig")[name].setup(lspfield)
            end
            local newftlist = type(lspfield.filetypes) == "string" and { lspfield.filetypes }
                or lspfield.filetypes
                or {}
            local oldftlist = type(plugin.ft) == "string" and { plugin.ft } or plugin.ft or {}
            ---@diagnostic disable-next-line: param-type-mismatch
            local usrft = vim.list_extend(newftlist, oldftlist)
            if auto_ft then
                plugin.ft = vim.list_extend(usrft, require("lspconfig")[plugin.name].filetypes)
            else
                plugin.ft = usrft
            end
            return plugin
        end,
    }
    return handler
end
