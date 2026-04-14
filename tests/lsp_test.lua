---@diagnostic disable: invisible
vim.g.lze = {
    load = function() end,
}
local lze = require("lze")
local lsp_handler = require("lzextras").lsp
local test = ...

lze.register_handlers(lsp_handler)
local old_fallback = lze.h.lsp.get_ft_fallback()

test("calls fallback function if no filetypes are provided", function()
    local load_spy = spy(function(_)
        return {}
    end)
    lze.h.lsp.set_ft_fallback(function(name)
        return load_spy(name)
    end)
    local plugin = {
        name = "fallback_foo_ls",
        lsp = {},
    }
    lze.load(plugin)
    ok(1 == #load_spy.called, "fallback function called once")
end)
test("calls lsp functions per spec with lsp table", function()
    local lspfun_spy = spy(function(_) end)
    local plugins = {
        {
            "lspcfg",
            lsp = function(plugin)
                lspfun_spy(plugin)
            end,
        },
        {
            name = "foo_ls",
            lsp = {},
        },
        {
            name = "bar_ls",
            lsp = {},
        },
    }
    lze.load(plugins)
    lze.trigger_load("foo_ls")
    ok(1 == #lspfun_spy.called, "lsp function called for foo_ls")
    lze.trigger_load("bar_ls")
    ok(2 == #lspfun_spy.called, "lsp function called for bar_ls")
    lze.trigger_load("fallback_foo_ls")
    ok(3 == #lspfun_spy.called, "lsp function called for fallback_foo_ls")
end)
lze.h.lsp.set_ft_fallback(old_fallback)
lze.remove_handlers("lsp")
