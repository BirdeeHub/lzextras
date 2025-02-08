---@class lzextras.LspHandler: lze.Handler
---@field states table<string, fun(plugin: lzextras.LspPlugin)>

---@type lzextras.LspHandler
return {
    states = {},
    spec_field = "lsp",
    ---@param plugin lzextras.LspPlugin
    modify = function(plugin)
        local lspfield = plugin.lsp
        if not lspfield then
            return plugin
        end
        if type(lspfield) == "function" then
            ---Deal with disabling so that it stays "private"
            ---@diagnostic disable-next-line: undefined-field
            require("lzextras").lsp.states[plugin.name] = lspfield
            return plugin
        end
        local oldload = plugin.load or function(_) end
        plugin.load = function(name)
            ---@diagnostic disable-next-line: undefined-field
            require("lze").trigger_load(vim.tbl_keys(require("lzextras").lsp.states))
            oldload(name)
        end
        local oldafter = plugin.after or function(_) end
        plugin.after = function(p)
            ---@diagnostic disable-next-line: undefined-field
            for _, f in ipairs(vim.tbl_values(require("lzextras").lsp.states)) do
                f(p)
            end
            oldafter(p)
        end
        ---@diagnostic disable-next-line: undefined-field
        local newftlist = type(lspfield.filetypes) == "string" and { lspfield.filetypes }
            ---@diagnostic disable-next-line: undefined-field
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
