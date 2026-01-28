---@module 'lze'

---@param modname string
---@param filter? fun(name: string):boolean
---@return lze.SpecImport[]
return function(modname, filter)
    local modpath = vim.fs.joinpath(unpack(vim.split(modname, ".", { plain = true })))
    local import_dir = vim.api.nvim_get_runtime_file(vim.fs.joinpath("lua", modpath), true)
    local result = {}
    if #import_dir > 0 then
        local dir = import_dir[1]
        local handle = vim.uv.fs_scandir(dir)
        while handle do
            local name, ty = vim.uv.fs_scandir_next(handle)
            local path = vim.fs.joinpath(dir, name)
            ty = ty or (vim.uv.fs_stat(path) or {}).type
            if not name then
                break
            -- XXX: "link" is required to support Nix.
            -- It seems to break in tests with with local symlinks
            elseif (ty == "file" or ty == "link") and name:sub(-4) == ".lua" then
                local submodname = name:sub(1, -5)
                if not filter or filter(submodname) then
                    table.insert(result, { import = modname .. "." .. submodname })
                end
            elseif ty == "directory" and vim.uv.fs_stat(vim.fs.joinpath(path, "init.lua")) then
                if not filter or filter(name) then
                    table.insert(result, { import = modname .. "." .. name })
                end
            end
        end
    end
    return result
end
