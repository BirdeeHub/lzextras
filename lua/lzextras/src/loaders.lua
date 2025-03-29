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

return M
