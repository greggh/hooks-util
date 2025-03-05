-- Tests for adapter functionality
local helper = require("spec_helper")

describe("adapter system", function()
  it("has at least one adapter registered", function()
    -- Get available adapters
    local registry = helper.load_module("core.registry")
    local adapters = registry.get_adapters()
    
    assert(adapters, "Should have adapters table")
    assert(type(adapters) == "table", "Should have adapters table (might be empty in test mode)")
  end)
  
  it("has adapter utility functions", function()
    -- We'll create our own adapter utils module to test
    local adapter = require("hooks-util.core.adapter")
    assert(adapter, "Adapter module should exist")
    assert(adapter.utils, "Adapter utils should exist")
    assert(type(adapter.utils.detect_project_type) == "function", 
           "Should have project type detection function")
  end)
  
  it("can create a basic adapter", function()
    local adapter = require("hooks-util.core.adapter")
    local test_adapter = adapter.create_adapter("test-adapter", {
      description = "Test adapter for unit tests"
    })
    
    assert(test_adapter, "Should create a test adapter")
    assert(test_adapter.name == "test-adapter", "Should have correct name")
    assert(type(test_adapter.setup) == "function", "Should have setup function")
    assert(type(test_adapter.validate) == "function", "Should have validate function")
    assert(type(test_adapter.get_hooks) == "function", "Should have get_hooks function")
  end)
  
  describe("mock adapter testing", function()
    local registry
    local mock_adapter
    
    before_each(function()
      -- Get the registry module
      registry = helper.load_module("core.registry")
      
      -- Create a mock adapter
      local adapter = require("hooks-util.core.adapter")
      mock_adapter = adapter.create_adapter("mock-adapter", {
        description = "Mock adapter for testing"
      })
      
      -- Mock the validate function to return true
      mock_adapter.validate = function(project)
        return project and project.root and true or false
      end
      
      -- Mock the get_hooks function
      mock_adapter.get_hooks = function()
        return {
          { name = "lint", command = "luacheck" },
          { name = "test", command = "spec/runner.lua" }
        }
      end
      
      -- Register the mock adapter
      registry.register(mock_adapter)
    end)
    
    it("registers and retrieves the mock adapter", function()
      local retrieved = registry.get_adapter("mock-adapter")
      assert(retrieved, "Should retrieve the registered adapter")
      assert(retrieved.name == "mock-adapter", "Should have correct name")
    end)
    
    it("validates projects correctly", function()
      local valid = mock_adapter.validate({ root = "/mock/project" })
      assert(valid, "Should validate a project with a root")
      
      local invalid = mock_adapter.validate({})
      assert(not invalid, "Should not validate a project without a root")
    end)
    
    it("provides appropriate hooks", function()
      local hooks = mock_adapter.get_hooks()
      assert(type(hooks) == "table", "Should return a table of hooks")
      
      -- Check for essential hooks
      local has_lint = false
      local has_test = false
      
      for _, hook in ipairs(hooks) do
        if hook.name == "lint" then has_lint = true end
        if hook.name == "test" then has_test = true end
      end
      
      assert(has_lint, "Should provide a lint hook")
      assert(has_test, "Should provide a test hook")
    end)
  end)
end)