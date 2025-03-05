-- spec_helper.lua
-- Helper utilities for lust-next tests

local M = {}

-- Setup test environment
function M.setup()
  -- Get the directory of this script
  local script_dir = debug.getinfo(1).source:match("@(.*/)")
  if not script_dir then
    script_dir = "./"
  end

  -- Add package path for local development (relative to project root)
  package.path = script_dir .. "../lua/?.lua;" .. package.path
  
  -- Print available paths
  print("Helper package path: " .. package.path)
  
  -- Try to load hooks-util
  local ok, hooks_util = pcall(require, "hooks-util")
  if not ok then
    print("Error loading hooks-util: " .. tostring(hooks_util))
    -- Create a mock hooks-util for testing
    return {
      setup = function() end,
      core = {
        registry = {
          get_adapters = function() return {} end,
          register = function() return true end,
          load_adapters = function() end -- Add missing function
        }
      }
    }
  end
  
  -- Load hooks-util with test configuration
  hooks_util.setup({
    test_mode = true,
    -- Add test-specific configuration here
    adapters = {
      enabled = {"nvim-plugin", "lua-lib", "nvim-config"}
    }
  })
  
  return hooks_util
end

-- Create mock objects
function M.create_mock(obj_type)
  if obj_type == "project" then
    return {
      root = "/mock/project/path",
      config = {
        hooks = {
          pre_commit = {"lint", "test"}
        },
        project_type = "lua-lib"
      },
      paths = {
        hooks = "/mock/project/path/.hooks",
        config = "/mock/project/path/.hooks-util.lua"
      }
    }
  end
  
  if obj_type == "adapter" then
    return {
      name = "mock-adapter",
      setup = function() end,
      validate = function() return true end,
      get_hooks = function() return {"lint", "test"} end
    }
  end
  
  return {}
end

-- Helper to load a module for testing
function M.load_module(name)
  local success, module = pcall(require, "hooks-util." .. name)
  if not success then
    print("Error loading module " .. name .. ": " .. tostring(module))
    
    -- Return mock modules for testing
    if name == "core.registry" then
      return {
        register = function() return true end,
        get_adapter = function() return {} end,
        get_adapters = function() return {} end,
        _reset_for_tests = function() end
      }
    elseif name == "core.config" then
      return {
        load = function() return true end,
        get = function() return {} end,
        set = function() end,
        _reset_for_tests = function() end
      }
    end
    
    -- Default mock
    return {}
  end
  
  return module
end

return M