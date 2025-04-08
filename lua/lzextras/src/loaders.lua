local M = {}

---@param name string
function M.with_after(name)
    vim.cmd.packadd(name)
    vim.cmd.packadd(name .. "/after")
end

---@param names string|string[]
function M.multi(names)
    names = type(names) == "table" and names or { names }
    for _, name in ipairs(names) do
        vim.cmd.packadd(name)
    end
end

---@param names string|string[]
function M.multi_w_after(names)
    names = type(names) == "table" and names or { names }
    for _, name in ipairs(names) do
        vim.cmd.packadd(name)
        vim.cmd.packadd(name .. "/after")
    end
end

---@param name string
function M.debug_load(name)
    local prertp = vim.o.runtimepath
    vim.cmd.packadd(name)
    if prertp == vim.o.runtimepath then
        vim.schedule(function()
            vim.notify(
                [[lze:Vim:E919: Already loaded, or directory not found in 'packpath': "pack/*/opt/]] .. name .. [["]],
                vim.log.levels.WARN,
                { title = "lzextras.debug_load" }
            )
        end)
    end
end

return M
