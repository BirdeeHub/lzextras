---@diagnostic disable: invisible
vim.g.lze = {
    load = function() end,
}
local lze = require("lze")
local lzextras = require("lzextras")
local test = ...

test("works when provided a spec", function()
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
    ok(true == lze.state(name), "plugin added to state")
    local feed = vim.api.nvim_replace_termcodes("<Ignore>" .. lhs, true, true, true)
    vim.api.nvim_feedkeys(feed, "ix", false)
    ok(true == called, "keymap callback was triggered")
    ok(false == lze.state(name), "plugin removed from state after keymap triggered")
end)
test("works when provided a name", function()
    local lhs = "<c-2>"
    local name = "key_test_2"
    local called = false
    lze.load({
        name,
        lazy = true,
    })
    ok(true == lze.state(name), "plugin added to state")
    local keymap = lzextras.keymap(name)
    keymap.set("n", lhs, function()
        called = true
    end, {})
    local feed = vim.api.nvim_replace_termcodes("<Ignore>" .. lhs, true, true, true)
    vim.api.nvim_feedkeys(feed, "ix", false)
    ok(true == called, "keymap callback was triggered")
    ok(false == lze.state(name), "plugin removed from state after keymap triggered")
end)
test("works when plugin was already loaded", function()
    local lhs = "<c-3>"
    local name = "key_test_3"
    local called = false
    lze.load({
        name,
        lazy = true,
    })
    lze.trigger_load(name)
    ok(false == lze.state(name), "plugin not in state after trigger_load")
    local keymap = lzextras.keymap(name)
    keymap.set("n", lhs, function()
        called = true
    end, {})
    local feed = vim.api.nvim_replace_termcodes("<Ignore>" .. lhs, true, true, true)
    vim.api.nvim_feedkeys(feed, "ix", false)
    ok(true == called, "keymap callback was triggered")
end)
