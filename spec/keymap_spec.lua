---@diagnostic disable: invisible
vim.g.lze = {
    load = function() end,
}
local lze = require("lze")
local lzextras = require("lzextras")

describe("lzextras.keymap", function()
    it("works when provided a spec", function()
        local lhs = "<c-1>"
        local name = "key_test"
        local called = false
        local keymap = lzextras.keymap({
            name,
            lazy = true,
        })
        keymap.set("n", lhs, function()
            called = true
        end, {})
        assert.is_true(lze.state(name))
        local feed = vim.api.nvim_replace_termcodes("<Ignore>" .. lhs, true, true, true)
        vim.api.nvim_feedkeys(feed, "ix", false)
        assert.is_true(called)
        assert.is_false(lze.state(name))
    end)
    it("works when provided a name", function()
        local lhs = "<c-2>"
        local name = "key_test_2"
        local called = false
        lze.load({
            name,
            lazy = true,
        })
        assert.is_true(lze.state(name))
        local keymap = lzextras.keymap(name)
        keymap.set("n", lhs, function()
            called = true
        end, {})
        local feed = vim.api.nvim_replace_termcodes("<Ignore>" .. lhs, true, true, true)
        vim.api.nvim_feedkeys(feed, "ix", false)
        assert.is_true(called)
        assert.is_false(lze.state(name))
    end)
    it("works when plugin was already loaded", function()
        local lhs = "<c-3>"
        local name = "key_test_3"
        local called = false
        lze.load({
            name,
            lazy = true,
        })
        lze.trigger_load(name)
        assert.is_false(lze.state(name))
        local keymap = lzextras.keymap(name)
        keymap.set("n", lhs, function()
            called = true
        end, {})
        local feed = vim.api.nvim_replace_termcodes("<Ignore>" .. lhs, true, true, true)
        vim.api.nvim_feedkeys(feed, "ix", false)
        assert.is_true(called)
    end)
end)
