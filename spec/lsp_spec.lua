---@diagnostic disable: invisible
vim.g.lze = {
    load = function() end,
}
local lze = require("lze")
local lsp_handler = require("lzextras").lsp
local old_ft_fallback = lsp_handler.ft_fallback
local spy = require("luassert.spy")

describe("lzextras.lsp", function()
    it("calls fallback function if no filetypes are provided", function()
        local plugin = {
            name = "fallback_foo_ls",
            lsp = {},
        }
        lze.register_handlers(lsp_handler)
        lsp_handler.ft_fallback = function(_)
            return {}
        end
        local fallback_spy = spy.on(lsp_handler, "ft_fallback")
        lze.load(plugin)
        assert.spy(fallback_spy).was.called(1)
        lsp_handler.ft_fallback = old_ft_fallback
        lze.remove_handlers("lsp")
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
        lze.register_handlers(lsp_handler)
        lsp_handler.ft_fallback = function(_)
            return {}
        end
        lze.load(plugins)
        lze.trigger_load("foo_ls")
        assert.spy(lspfun_spy).was.called(1)
        lze.trigger_load("bar_ls")
        assert.spy(lspfun_spy).was.called(2)
        lsp_handler.ft_fallback = old_ft_fallback
        lze.remove_handlers("lsp")
    end)
end)
