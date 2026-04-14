local make_load_with_afters = require("lzextras").make_load_with_afters
local tempdir = vim.fn.tempname()
local test_plugin_path = vim.fs.joinpath(tempdir, "pack", "test_plugins", "opt", "test_plugin")
vim.system({ "mkdir", "-p", vim.fs.joinpath(tempdir, "pack", "test_plugins", "opt", "test_plugin", "after", "plugin") })
    :wait()
local test = ...
local load_spy = test.spy(function(_) end)
local dirs_spy = test.spy(function(_, _) end)

test("calls optional load function", function()
    local newload = make_load_with_afters({ "plugin" }, function(name)
        load_spy(name)
        return "doesnt_exist"
    end)
    newload("test_plugin")
    ok(load_spy.called_with("test_plugin"), "load function called with test_plugin")
end)
test("doesnt call dirs function if after doesnt exist", function()
    local newload = make_load_with_afters(function(path, name)
        dirs_spy(path, name)
        return {}
    end, function(name)
        load_spy(name)
        return "doesnt_exist"
    end)
    newload("test_plugin")
    ok(2 == #load_spy.called, "load function called twice (cumulative)")
    ok(0 == #dirs_spy.called, "dirs function not called")
end)
test("calls dirs function if after does exist", function()
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
    ok(3 == #load_spy.called, "load function called 3 times (cumulative)")
    ok(1 == #dirs_spy.called, "dirs function called once")
    ok(true == vim.g.test_plugin_called, "plugin was executed")
    vim.system({ "rm", vim.fs.joinpath(test_plugin_path, "plugin", "test.lua") }):wait()
    vim.g.test_plugin_called = nil
end)
test("finds plugins from packpath", function()
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
    end)
    vim.opt.packpath:prepend(tempdir)
    newload("test_plugin")
    ok(2 == #dirs_spy.called, "dirs function called twice (cumulative)")
    ok(true == vim.g.test_plugin_called, "plugin was executed")
    vim.g.test_plugin_called = nil
end)
vim.system({ "rm", "-r", tempdir }):wait()
