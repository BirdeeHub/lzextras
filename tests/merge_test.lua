---@diagnostic disable: invisible
vim.g.lze = {
    load = function() end,
}
local lze = require("lze")
local merge = require("lzextras").merge
local test = ...
lze.register_handlers(merge)

test("bounces new additions", function()
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
    ok(nil == lze.state("merge_target"), "plugin not added to state after merge bounce")
end)
test("can be triggered by passing merge = false", function()
    lze.load({
        "merge_target",
        merge = false,
    })
    ok(true == lze.state("merge_target"), "plugin added to state with merge = false")
end)
test("has expected contents of merge", function()
    ok(
        eq({
            name = "merge_target",
            dep_of = { "not_lspconfig" },
            lazy = true,
            lsp = {
                settings = {},
                filetypes = {},
            },
        }, lze.state.merge_target),
        "merged plugin has expected state"
    )
end)
test("can be triggered by trigger function", function()
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
    ok(
        eq({
            name = "merge_target_2",
            dep_of = { "not_lspconfig" },
            lazy = true,
            lsp = {
                settings = {},
                filetypes = {},
            },
        }, lze.state.merge_target_2),
        "triggered merge has expected state for target_2"
    )
    ok(
        eq({
            name = "merge_target_3",
            lazy = true,
            ft = { "go" },
        }, lze.state.merge_target_3),
        "triggered merge has expected state for target_3"
    )
end)

lze.remove_handlers("merge")
