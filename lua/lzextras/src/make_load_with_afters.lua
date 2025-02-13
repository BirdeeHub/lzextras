---@overload fun(dirs: string[]|string): fun(names: string|string[])
---@overload fun(dirs: string[]|string, load: fun(name: string):string|nil): fun(names: string|string[])
---@overload fun(dirs: fun(afterpath: string, name: string):string[]): fun(names: string|string[])
---@overload fun(dirs: fun(afterpath: string, name: string):string[], load: fun(name: string):string|nil): fun(names: string|string[])
return function(dirs, load)
    dirs = ((type(dirs) == "table" or type(dirs) == "function") and dirs) or { dirs }
    local fromPackpath = function(name)
        for _, packpath in ipairs(vim.opt.packpath:get()) do
            local plugin_path = vim.fn.globpath(packpath, "pack/*/opt/" .. name, nil, true, true)
            if plugin_path[1] then
                return plugin_path[1]
            end
        end
        return nil
    end
    ---@param plugin_names string[]|string
    return function(plugin_names)
        local names = type(plugin_names) == "table" and plugin_names or { plugin_names }
        local to_source = {}
        for _, name in ipairs(names) do
            if type(name) == "string" then
                local path = (type(load) == "function" and load(name)) or nil
                if type(path) == "string" then
                    table.insert(to_source, { name = name, path = path })
                else
                    local ok, err = pcall(vim.cmd.packadd, name)
                    if ok then
                        table.insert(to_source, { name = name, path = nil })
                    else
                        vim.notify(
                            '"packadd '
                                .. name
                                .. '" failed, and path provided by custom load function (if provided) was not a string\n'
                                .. err,
                            vim.log.levels.WARN,
                            { title = "lzextras.make_load_with_afters" }
                        )
                    end
                end
            else
                vim.notify(
                    "plugin name was not a string and was instead of value:\n" .. vim.inspect(name),
                    vim.log.levels.WARN,
                    { title = "lzextras.make_load_with_afters" }
                )
            end
        end
        for _, info in ipairs(to_source) do
            local plugpath = info.path or fromPackpath(info.name)
            if type(plugpath) == "string" then
                local afterpath = plugpath .. "/after"
                if vim.fn.isdirectory(afterpath) == 1 then
                    if type(dirs) == "function" then
                        local targets = dirs(afterpath, info.name)
                        if type(targets) == "table" then
                            for _, file in ipairs(targets) do
                                if vim.fn.filereadable(file) == 1 then
                                    vim.cmd.source(file)
                                end
                            end
                        end
                    elseif type(dirs) == "table" then
                        for _, dir in ipairs(dirs) do
                            local plugin_dir = afterpath .. "/" .. dir
                            if vim.fn.isdirectory(plugin_dir) == 1 then
                                local files = vim.fn.glob(plugin_dir .. "/*", false, true)
                                for _, file in ipairs(files) do
                                    if vim.fn.filereadable(file) == 1 then
                                        vim.cmd.source(file)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
