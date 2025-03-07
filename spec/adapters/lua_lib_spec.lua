-- hooks-util/spec/adapters/lua_lib_spec.lua
-- Tests for the Lua library adapter

local lust = require("hooks-util.lust-next")
local describe, it, expect = lust.describe, lust.it, lust.expect
local mock = require("lust-mock")

-- Mock the file system functions
local lfs_mock = mock.new()
mock.register("lfs", lfs_mock)

-- Mock io.open function
local io_mock = mock.new()
io_mock.open = function(path, mode)
  if path:match("/my_lib.rockspec$") then
    return {
      read = function() 
        return [[
package = "my_lib"
version = "0.1.0"
source = {
  url = "git://github.com/user/my_lib",
  tag = "v0.1.0"
}
description = {
  summary = "A sample library",
  detailed = "A more detailed description",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1"
}
build = {
  type = "builtin",
  modules = {
    ["my_lib"] = "lua/my_lib/init.lua",
    ["my_lib.utils"] = "lua/my_lib/utils.lua"
  }
}
]]
      end,
      close = function() end
    }
  elseif path:match("/.luacov$") then
    return {
      read = function() return "-- LuaCov config file" end,
      close = function() end
    }
  elseif path:match("/scripts/test_all_versions.sh$") then
    return {
      read = function() return "#!/bin/bash" end,
      close = function() end
    }
  end
  
  return nil
end
mock.register("io", io_mock)

-- Mock os.execute
local os_mock = mock.new()
os_mock.execute = function(cmd)
  return 0 -- Success
end
mock.register("os", os_mock)

-- Load the adapter
local adapter = require("hooks-util.adapters.lua-lib")

describe("lua-lib adapter", function()
  
  -- Create a mock project root for testing
  local project_root = "/mock/lua_lib_project"
  
  -- Mock necessary functions/components
  lfs_mock.attributes = function(path, attr)
    if path == project_root .. "/lua" and attr == "mode" then
      return "directory"
    elseif path == project_root .. "/spec" and attr == "mode" then
      return "directory"
    elseif path == project_root .. "/scripts" and attr == "mode" then
      return "directory"
    end
    
    return nil
  end
  
  lfs_mock.dir = function(path)
    if path == project_root then
      local i = 0
      local items = {".", "..", "my_lib.rockspec", "lua", "spec"}
      return function()
        i = i + 1
        return items[i]
      end
    end
    
    return function() return nil end
  end
  
  lfs_mock.mkdir = function(path)
    return true
  end
  
  describe("setup_coverage", function()
    it("should configure coverage tracking", function()
      local config = adapter:setup_coverage(project_root)
      expect(config).to.be.a("table")
      expect(config.enabled).to.be(true)
      expect(config.tool).to.be("luacov")
    end)
  end)
  
  describe("validate_rockspec", function()
    it("should validate rockspec file", function()
      local success, errors, warnings = adapter:validate_rockspec(project_root)
      expect(success).to.be(true)
      expect(#errors).to.be(0)
    end)
  end)
  
  describe("setup_multi_version_testing", function()
    it("should set up multi-version testing", function()
      local config = adapter:setup_multi_version_testing(project_root)
      expect(config).to.be.a("table")
      expect(config.enabled).to.be(true)
      expect(#config.versions).to.be.at_least(3)
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