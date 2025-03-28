---@type table<string, lzextras.MergePlugin>
local states = {}
local trigger = function()
    if states ~= {} then
        local all = vim.tbl_values(states)
        states = {}
        require("lze").load(all)
    end
end
---@type lze.Handler
return {
    spec_field = "merge",
    set_lazy = false,
    -- modify is only called when a plugin's field is not nil
    ---@param plugin lzextras.MergePlugin
    modify = function(plugin)
        if not plugin.merge then
            local state = states[plugin.name]
            if state then
                state = vim.tbl_deep_extend("force", state, plugin)
                states[plugin.name] = nil
                state.merge = nil
                return state
            end
            return plugin
        end
        local pname = plugin.name
        local pstate = require("lze").state(pname)
        if pstate then
            vim.notify(
                'Failed to merge: "' .. pname .. '". Immutable spec already exists',
                vim.log.levels.ERROR,
                { title = "lzextras.merge" }
            )
            return plugin
        elseif pstate == false and not (plugin.allow_again or states[pname].allow_again) then
            vim.notify(
                'Failed to merge: "' .. pname .. '". Spec already loaded',
                vim.log.levels.ERROR,
                { title = "lzextras.merge" }
            )
            return plugin
        end
        states[pname] = vim.tbl_deep_extend("force", states[pname] or {}, plugin)
        states[pname].merge = nil
        return { name = plugin.name, enabled = false }
    end,
    trigger = function()
        vim.notify(
            "`require('lzextras').merge.trigger` is deprecated, use `require('lze').h.merge.trigger` instead.",
            vim.log.levels.ERROR,
            { title = "lzextras.merge" }
        )
        return trigger()
    end,
    lib = {
        trigger = trigger,
    },
}
