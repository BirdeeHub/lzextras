---@type table<string, string[]>
local states = {}
---@type table<string, string[]|(fun(name: string):string[])|false|nil>
local pending = {}
---@type { priority: number, hook: fun(p: lzextras.LspPlugin), name: string }[]
local hooks = {}
local augroup = nil
---@type lze.Handler
local event = nil
local ft_fallback = nil
---@type lze.Handler
local handler = {
    spec_field = "lsp",
    lib = {
        ---@return nil|(fun(name: string):string[]?)
        get_ft_fallback = function()
            return ft_fallback
        end,
        ---@param f nil|(fun(name: string):string[]?)
        set_ft_fallback = function(f)
            ft_fallback = f
        end,
    },
    init = function()
        event = require("lze.h.event")
        augroup = vim.api.nvim_create_augroup("lzextras_handler_lsp", { clear = true })
    end,
    cleanup = function()
        for name, _ in pairs(states) do
            event.before(name)
        end
        states = {}
        pending = {}
        hooks = {}
        if augroup then
            vim.api.nvim_del_augroup_by_id(augroup)
        end
    end,
    before = function(name)
        if states[name] then
            event.before(name)
            states[name] = nil
        end
        pending[name] = nil
    end,
}
---@param plugin lzextras.LspPlugin
function handler.modify(plugin)
    local trigger_load = require("lze").trigger_load
    if plugin.enabled == false or (type(plugin.enabled) == "function" and not plugin.enabled()) then
        return plugin
    end
    local field = plugin.lsp
    local fieldtype = type(field)
    if fieldtype == "function" then
        local default_priority = (vim.g.lze or {}).default_priority or 50
        local pp = plugin.priority or default_priority
        for i, v in ipairs(hooks) do
            if (v.priority or default_priority) < pp then
                table.insert(
                    hooks,
                    i,
                    { priority = plugin.priority or default_priority, hook = plugin.lsp, name = plugin.name }
                )
                return plugin
            end
        end
        table.insert(hooks, { priority = plugin.priority or default_priority, hook = plugin.lsp, name = plugin.name })
        return plugin
    elseif fieldtype ~= "table" then
        return plugin
    end
    local oldload = plugin.load or function(_) end
    local oldbefore = plugin.before or function(_) end
    ---@param p lzextras.LspPlugin
    plugin.before = function(p)
        local maybepending = pending[p.name]
        local state
        local pending_type = type(maybepending)
        if pending_type == "function" then
            local ok, v = pcall(maybepending, p.name)
            if ok then
                state = v
            else
                vim.schedule(function()
                    vim.notify(
                        "Error running ft_fallback function:\n" .. tostring(v),
                        vim.log.levels.WARN,
                        { title = "lzextras.lsp" }
                    )
                end)
            end
        elseif pending_type == "table" then
            state = maybepending
        else
            state = states[p.name]
        end
        pending[p.name] = nil
        states[p.name] = nil
        p.lsp.filetypes = state
        oldbefore(p)
    end
    plugin.load = function(name)
        local to_load = {}
        for _, v in ipairs(hooks) do
            table.insert(to_load, v.name)
        end
        trigger_load(to_load)
        oldload(name)
    end
    local oldafter = plugin.after or function(_) end
    ---@param p lzextras.LspPlugin
    plugin.after = function(p)
        local fns = {}
        for _, v in ipairs(hooks) do
            table.insert(fns, v.hook)
        end
        for _, f in ipairs(fns) do
            f(p)
        end
        oldafter(p)
    end
    fieldtype = type(plugin.ft)
    local oldftlist = fieldtype == "string" and { plugin.ft } or fieldtype == "table" and plugin.ft or nil
    plugin.ft = nil
    ---@diagnostic disable-next-line: undefined-field, cast-local-type
    field = field.filetypes
    fieldtype = type(field)
    local newftlist = fieldtype == "string" and { field } or fieldtype == "table" and field or nil
    if newftlist or oldftlist then
        ---@diagnostic disable-next-line: param-type-mismatch
        local final = vim.list_extend(newftlist or {}, oldftlist or {})
        pending[plugin.name] = final
        plugin.lsp.filetypes = final
    else
        pending[plugin.name] = fieldtype == "function" and field or (ft_fallback or false)
    end
    return plugin
end

handler.post_def = function()
    local trigger_load = require("lze").trigger_load
    local no_ft = {}
    for name, val in pairs(pending) do
        local ftlist = nil
        if type(val) == "function" then
            local ok, ret = pcall(val, name)
            if ok then
                ftlist = ret
            else
                vim.schedule(function()
                    vim.notify(
                        "Error running ft_fallback function:\n" .. tostring(ret),
                        vim.log.levels.WARN,
                        { title = "lzextras.lsp" }
                    )
                end)
            end
        else
            ftlist = type(val) == "table" and val or nil
        end
        pending[name] = nil
        if type(ftlist) == "table" then
            states[name] = ftlist
            ftlist = vim.deepcopy(ftlist)
            for k, ft in ipairs(ftlist) do
                ---@diagnostic disable-next-line: assign-type-mismatch
                ftlist[k] = {
                    id = ft,
                    event = "FileType",
                    pattern = ft,
                    augroup = augroup,
                }
            end
            local p = { name = name, event = ftlist }
            event.add(p)
        else
            table.insert(no_ft, name)
        end
    end
    if next(no_ft) then
        vim.schedule(function()
            trigger_load(no_ft)
        end)
    end
end
return handler
