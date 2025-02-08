---@type table<string, fun(plugin: lzextras.LspPlugin)>
local states = {}

local handler = {
    spec_field = "lsp",
    ft_fallback = function(name)
        local ok, lspconfig = pcall(require, "lspconfig")
        if ok then
            return lspconfig[name].config_def.default_config.filetypes
        else
            return nil
        end
    end,
}
---@param plugin lzextras.LspPlugin
function handler.modify(plugin)
    local lspfield = plugin.lsp
    if type(lspfield) == "function" then
        states[plugin.name] = lspfield
        return plugin
    elseif type(lspfield) ~= "table" then
        return plugin
    end
    local oldload = plugin.load or function(_) end
    plugin.load = function(name)
        require("lze").trigger_load(vim.tbl_keys(states))
        oldload(name)
    end
    local oldafter = plugin.after or function(_) end
    plugin.after = function(p)
        for _, f in ipairs(vim.tbl_values(states)) do
            f(p)
        end
        oldafter(p)
    end
    ---@diagnostic disable-next-line: undefined-field
    local newftlist = type(lspfield.filetypes) == "string" and { lspfield.filetypes }
        ---@diagnostic disable-next-line: undefined-field
        or type(lspfield.filetypes) == "table" and lspfield.filetypes
        or nil
    local oldftlist = type(plugin.ft) == "string" and { plugin.ft } or type(plugin.ft) == "table" and plugin.ft or nil
    if newftlist or oldftlist then
        ---@diagnostic disable-next-line: param-type-mismatch
        plugin.ft = vim.list_extend(newftlist or {}, oldftlist or {})
    else
        plugin.ft = handler.ft_fallback(plugin.name)
    end
    return plugin
end
return handler
