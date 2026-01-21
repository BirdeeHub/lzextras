local M = {}

---@param input any
---@param hook fun(buf: integer, win: integer))
function M.display(input, hook)
    local filetype = type(input) ~= "string" and "lua" or nil
    input = filetype and vim.inspect(input) or input
    local function mk_popup(text)
        local contents = vim.split(text, "\n", { plain = true })
        local bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
        vim.bo[bufnr].modifiable = false
        vim.bo[bufnr].readonly = true
        if filetype then
            vim.bo[bufnr].filetype = filetype
        end

        -- Get maximum width of text
        local width = 0
        for _, line in ipairs(contents) do
            width = math.max(width, #line)
        end

        -- cap to screen size with margin
        local height = #contents
        local win_width = math.min(width + 2, vim.o.columns - 4)
        local win_height = math.min(height + 2, vim.o.lines - 4)
        local popopts = {
            relative = "editor",
            width = win_width,
            height = win_height,
            row = (vim.o.lines - win_height) / 2,
            col = (vim.o.columns - win_width) / 2,
            style = "minimal",
            border = "rounded",
        }

        -- make the window
        local win_id = vim.api.nvim_open_win(bufnr, true, popopts)
        vim.wo[win_id].signcolumn = "no"
        vim.wo[win_id].number = false
        vim.wo[win_id].relativenumber = false

        vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "<Cmd>close<CR>", { noremap = true, silent = true })
        vim.api.nvim_buf_set_keymap(bufnr, "n", "<Esc>", "<Cmd>close<CR>", { noremap = true, silent = true })

        vim.api.nvim_create_autocmd("BufLeave", {
            buffer = bufnr,
            once = true,
            callback = function()
                vim.api.nvim_win_close(win_id, true)
            end,
        })

        if hook then
            vim.api.nvim_win_call(win_id, function()
                local ok, err = pcall(hook, bufnr, win_id)
                if not ok then
                    vim.schedule(function()
                        vim.notify(
                            "Error running hook argument:\n" .. tostring(err),
                            vim.log.levels.ERROR,
                            { title = "lzextras.debug.display" }
                        )
                    end)
                end
            end)
        end
    end
    local ok, err = pcall(mk_popup, input)
    if not ok then
        vim.schedule(function()
            vim.notify(
                "Popup failed to open due to error:\n" .. tostring(err),
                vim.log.levels.ERROR,
                { title = "lzextras.debug.display" }
            )
        end)
        print(input)
    end
end

function M.show_state()
    local splitres = { deferred = {}, loaded = {} }
    ---@diagnostic disable-next-line: param-type-mismatch
    for key, value in pairs(-require("lze").state) do
        splitres[value and "deferred" or "loaded"][key] = value
    end
    M.display(
        "-- LZE STATE DISPLAY\n\nloaded = "
            .. vim.inspect(splitres.loaded)
            .. "\n\ndeferred = "
            .. vim.inspect(splitres.deferred),
        function(buf)
            vim.bo[buf].filetype = "lua"
        end
    )
end

return M
