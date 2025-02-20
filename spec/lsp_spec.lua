---@diagnostic disable: invisible
vim.g.lze = {
    load = function() end,
}
local lze = require("lze")
local lsp_handler = require("lzextras").lsp
local spy = require("luassert.spy")
local load_spy = spy.new(function(_)
    return {}
end)

describe("lzextras.lsp", function()
    lze.register_handlers(lsp_handler)
    local old_fallback = lze.h.lsp.get_ft_fallback()
    lze.h.lsp.set_ft_fallback(function(name)
        return load_spy(name)
    end)
    it("calls fallback function if no filetypes are provided", function()
        local plugin = {
            name = "fallback_foo_ls",
            lsp = {},
        }
        lze.load(plugin)
        assert.spy(load_spy).was.called(1)
    end)
    it("calls lsp functions per spec with lsp table", function()
        local lspfun_spy = spy.new(function(_) end)
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
        assert.spy(lspfun_spy).was.called(1)
        lze.trigger_load("bar_ls")
        assert.spy(lspfun_spy).was.called(2)
        lze.trigger_load("fallback_foo_ls")
        assert.spy(lspfun_spy).was.called(3)
        lze.h.lsp.set_ft_fallback(old_fallback)
        lze.remove_handlers("lsp")
    end)
end)
