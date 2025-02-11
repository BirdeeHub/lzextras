local make_load_with_afters = require("lzextras").make_load_with_afters
local spy = require("luassert.spy")
local tempdir = vim.fn.tempname()
local test_plugin_path = vim.fs.joinpath(tempdir, "pack", "test_plugins", "opt", "test_plugin")
vim.system({ "rm", "-r", tempdir }):wait()
vim.system({ "mkdir", "-p", vim.fs.joinpath(tempdir, "pack", "test_plugins", "opt", "test_plugin", "after", "plugin") })
    :wait()
local load_spy = spy.new(function(_) end)
local dirs_spy = spy.new(function(_, _) end)

describe("lzextras.make_load_with_afters", function()
    it("calls optional load function", function()
        local newload = make_load_with_afters({ "plugin" }, function(name)
            load_spy(name)
            return "doesnt_exist"
        end)
        newload("test_plugin")
        assert.spy(load_spy).was.called_with("test_plugin")
    end)
    it("doesnt call dirs function if after doesnt exist", function()
        local newload = make_load_with_afters(function(path, name)
            dirs_spy(path, name)
            return {}
        end, function(name)
            load_spy(name)
            return "doesnt_exist"
        end)
        newload("test_plugin")
        assert.spy(load_spy).was.called(2)
        assert.spy(dirs_spy).was.called(0)
    end)
    it("calls dirs function if after does exist", function()
        local newload = make_load_with_afters(function(path, name)
            dirs_spy(path, name)
            local test_plug = vim.fs.joinpath(path, "plugin", "test.lua")
            local plugin_content = [[
                vim.g.test_plugin_called = true
            ]]
            local fh = assert(io.open(test_plug, "w"), "Could not open config file for writing")
            fh:write(plugin_content)
            fh:close()
            return { test_plug }
        end, function(name)
            load_spy(name)
            return test_plugin_path
        end)
        newload("test_plugin")
        assert.spy(load_spy).was.called(3)
        assert.spy(dirs_spy).was.called(1)
        assert.same(true, vim.g.test_plugin_called)
        vim.system({ "rm", vim.fs.joinpath(test_plugin_path, "plugin", "test.lua") }):wait()
        package.loaded["plugins"] = nil
        vim.g.test_plugin_called = nil
        vim.system({ "rm", "-r", tempdir }):wait()
    end)
end)
