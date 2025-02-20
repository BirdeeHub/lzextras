---@diagnostic disable: invisible
vim.g.lze = {
    load = function() end,
}
local lze = require("lze")
local merge = require("lzextras").merge

describe("lzextras.merge", function()
    it("bounces new additions", function()
        lze.register_handlers(merge)
        lze.load({
            {
                "merge_target",
                merge = true,
                dep_of = { "lspconfig" },
                lsp = { filetypes = {} },
            },
            {
                "merge_target",
                merge = true,
                dep_of = { "not_lspconfig" },
                lsp = { settings = {} },
            },
        })
        assert.is_nil(lze.state("merge_target"))
    end)
    it("can be triggered by passing merge = false", function()
        lze.load({
            "merge_target",
            merge = false,
        })
        assert.is_true(lze.state("merge_target"))
    end)
    it("has expected contents of merge", function()
        assert.same({
            name = "merge_target",
            dep_of = { "not_lspconfig" },
            lazy = true,
            lsp = {
                settings = {},
                filetypes = {},
            },
        }, lze.state.merge_target)
    end)
    it("can be triggered by trigger function", function()
        lze.register_handlers(merge)
        lze.load({
            {
                "merge_target_2",
                merge = true,
                dep_of = { "lspconfig" },
                lsp = { filetypes = {} },
            },
            {
                "merge_target_2",
                merge = true,
                dep_of = { "not_lspconfig" },
                lsp = { settings = {} },
            },
            {
                "merge_target_3",
                merge = true,
            },
            {
                "merge_target_3",
                merge = true,
                ft = { "go" },
            },
        })
        lze.h.merge.trigger()
        assert.same({
            name = "merge_target_2",
            dep_of = { "not_lspconfig" },
            lazy = true,
            lsp = {
                settings = {},
                filetypes = {},
            },
        }, lze.state.merge_target_2)
        assert.same({
            name = "merge_target_3",
            lazy = true,
            ft = { "go" },
        }, lze.state.merge_target_3)
    end)
end)
