for _, name in ipairs(require("servernames")) do
    local fts = require("lspconfig.configs." .. name).default_config.filetypes
    if fts then
        local file = io.open(vim.g.server_gen_out_path .. "/" .. name .. ".lua", "w")
        assert(file ~= nil, "Could not open output file")
        file:write("return " .. vim.inspect(fts))
        file:close()
    end
end
