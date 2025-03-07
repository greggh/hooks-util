-- hooks-util/spec/adapters/nvim_plugin_spec.lua
-- Tests for the Neovim plugin adapter

local lust = require("hooks-util.lust-next")
local describe, it, expect = lust.describe, lust.it, lust.expect
local mock = require("lust-mock")

-- Mock the file system functions
local lfs_mock = mock.new()
mock.register("lfs", lfs_mock)

-- Mock io.open function
local io_mock = mock.new()
io_mock.open = function(path, mode)
  if path:match("/lua/plugin_name/health.lua$") then
    return {
      read = function() 
        return [[
local M = {}

function M.check()
  vim.health.report_start("plugin_name")
  vim.health.report_ok("Everything is fine")
end

return M
]]
      end,
      close = function() end
    }
  elseif path:match("/lua/plugin_name/init.lua$") then
    return {
      read = function() return "-- Plugin init file" end,
      close = function() end
    }
  elseif path:match("/README.md$") then
    return {
      read = function() return "# Plugin Name" end,
      close = function() end
    }
  elseif path:match("/.luacheckrc$") then
    return {
      read = function() return "-- Luacheck config" end,
      close = function() end
    }
  end
  
  return nil
end
mock.register("io", io_mock)

-- Load the adapter
local adapter = require("hooks-util.adapters.nvim-plugin")

describe("nvim-plugin adapter", function()
  
  -- Create a mock project root for testing
  local project_root = "/mock/plugin_project"
  
  -- Mock necessary functions/components
  lfs_mock.attributes = function(path, attr)
    if path == project_root .. "/lua" and attr == "mode" then
      return "directory"
    elseif path == project_root .. "/plugin" and attr == "mode" then
      return "directory"
    elseif path == project_root .. "/doc" and attr == "mode" then
      return "directory"
    elseif path == project_root .. "/lua/plugin_name" and attr == "mode" then
      return "directory"
    elseif path == project_root .. "/tests" and attr == "mode" then
      return "directory"
    end
    
    return nil
  end
  
  lfs_mock.dir = function(path)
    if path == project_root .. "/lua" then
      local i = 0
      local items = {".", "..", "plugin_name"}
      return function()
        i = i + 1
        return items[i]
      end
    elseif path == project_root .. "/doc" then
      local i = 0
      local items = {".", "..", "plugin_name.txt"}
      return function()
        i = i + 1
        return items[i]
      end
    end
    
    return function() return nil end
  end
  
  describe("validate_health_check", function()
    it("should validate health check module", function()
      local success, errors, warnings = adapter:validate_health_check(project_root)
      expect(success).to.be(true)
      expect(#errors).to.be(0)
    end)
  end)
  
  describe("validate_runtime_paths", function()
    it("should validate plugin runtime paths", function()
      local success, errors, warnings = adapter:validate_runtime_paths(project_root)
      expect(success).to.be(true)
      expect(#errors).to.be(0)
    end)
  end)
  
  describe("validate_plugin_structure", function()
    it("should validate plugin structure", function()
      local success, errors, warnings = adapter:validate_plugin_structure(project_root)
      expect(success).to.be(true)
      expect(#errors).to.be(0)
    end)
  end)
  
  describe("get_plugin_name", function()
    it("should extract plugin name from directory structure", function()
      local name = adapter:get_plugin_name(project_root)
      expect(name).to.be("plugin_name")
    end)
  end)
  
  describe("get_workflow_configs", function()
    it("should return workflow configurations", function()
      local configs = adapter:get_workflow_configs()
      expect(#configs).to.be.at_least(1)
    end)
  end)
  
  describe("get_applicable_workflows", function()
    it("should return applicable workflows", function()
      local workflows = adapter:get_applicable_workflows()
      expect(#workflows).to.be.at_least(3)
    end)
  end)
end)