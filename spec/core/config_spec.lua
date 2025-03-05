-- Tests for the configuration module
local helper = require("spec_helper")

describe("configuration", function()
  local config
  
  before(function()
    -- Load the config module
    config = helper.load_module("core.config")
  end)
  
  it("exists and has expected interface", function()
    assert(config, "Config module should exist")
    assert(type(config.load) == "function", "Should have load function")
    assert(type(config.get) == "function", "Should have get function")
    assert(type(config.set) == "function", "Should have set function")
  end)
  
  it("has default configuration", function()
    -- Reset config to defaults if possible
    if config._reset_for_tests then
      config._reset_for_tests()
    end
    
    local defaults = config.get()
    assert(type(defaults) == "table", "Should return a table of defaults")
    
    -- Check that essential defaults exist
    assert(defaults.adapters, "Should have adapters section")
    assert(defaults.hooks, "Should have hooks section")
  end)
  
  it("can set and get configuration values", function()
    -- Set a test value
    config.set("test_key", "test_value")
    
    -- Get the value
    local value = config.get("test_key")
    assert(value == "test_value", "Should retrieve the set value")
  end)
  
  it("can handle nested configuration values", function()
    -- Set a nested test value
    config.set("nested.key.value", 42)
    
    -- Get the nested value
    local value = config.get("nested.key.value")
    assert(value == 42, "Should retrieve the nested value")
    
    -- Get the parent table
    local parent = config.get("nested.key")
    assert(type(parent) == "table", "Parent should be a table")
    assert(parent.value == 42, "Parent table should contain the value")
  end)
  
  it("returns nil for non-existent configuration keys", function()
    local value = config.get("non_existent_key")
    assert(value == nil, "Should return nil for non-existent keys")
  end)
  
  it("can load configuration from a file", function()
    -- Mock the load function to simulate loading from a file
    local original_loadfile = loadfile
    
    -- Replace loadfile with a mock
    _G.loadfile = function()
      return function()
        return {
          test_config_key = "from_file",
          adapters = {
            enabled = {"test-adapter"}
          }
        }
      end
    end
    
    -- Call load with a mock file path
    local success = config.load("/mock/path/to/config.lua")
    
    -- Reset loadfile to original
    _G.loadfile = original_loadfile
    
    -- Verify the config was loaded
    assert(success, "Should successfully load configuration")
    assert(config.get("test_config_key") == "from_file", "Should load value from file")
    assert(config.get("adapters.enabled")[1] == "test-adapter", "Should load nested values")
  end)
end)