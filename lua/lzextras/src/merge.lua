---@type table<string, lzextras.MergePlugin>
local states = {}

local M = {
    ---@type lze.Handler
    handler = {
        spec_field = "merge",
        -- modify is only called when a plugin's field is not nil
        ---@param plugin lzextras.MergePlugin
        modify = function(plugin)
            local mergevar = plugin.merge
            if mergevar ~= true or type(mergevar) ~= "string" then
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
            if type(mergevar) == "string" then
                plugin.after = plugin.after
                    or function(p)
                        require(p.merge).setup(p.opts)
                    end
            end
            states[pname] = vim.tbl_deep_extend("force", states[pname] or {}, plugin)
            states[pname].merge = nil
            return { name = plugin.name, enabled = false }
        end,
    },
    trigger = function()
        if states ~= {} then
            require("lze").load(vim.tbl_values(states))
        end
    end,
}

return M
