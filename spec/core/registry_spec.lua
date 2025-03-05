-- Tests for the adapter registry module
local helper = require("spec_helper")

describe("adapter registry", function()
  local registry
  
  before(function()
    -- Load the registry module
    registry = helper.load_module("core.registry")
  end)
  
  it("exists and has expected interface", function()
    assert(registry, "Registry module should exist")
    assert(type(registry.register) == "function", "Should have register function")
    assert(type(registry.get_adapter) == "function", "Should have get_adapter function")
    assert(type(registry.get_adapters) == "function", "Should have get_adapters function")
  end)
  
  it("can register and retrieve an adapter", function()
    local mock_adapter = {
      name = "test-adapter",
      setup = function() end,
      validate = function() return true end
    }
    
    registry.register(mock_adapter)
    local retrieved = registry.get_adapter("test-adapter")
    
    assert(retrieved, "Should retrieve the registered adapter")
    assert(retrieved.name == "test-adapter", "Should have correct name")
    assert(type(retrieved.setup) == "function", "Should have setup function")
  end)
  
  it("returns nil for non-existent adapters", function()
    local non_existent = registry.get_adapter("non-existent-adapter")
    assert(non_existent == nil, "Should return nil for non-existent adapters")
  end)
  
  it("can get all registered adapters", function()
    -- Clear registry (if possible)
    if registry._reset_for_tests then
      registry._reset_for_tests()
    end
    
    -- Register test adapters
    registry.register({ name = "adapter1", setup = function() end })
    registry.register({ name = "adapter2", setup = function() end })
    
    local adapters = registry.get_adapters()
    assert(type(adapters) == "table", "Should return a table of adapters")
    assert(#adapters >= 2, "Should have at least the two registered adapters")
    
    -- Check if our adapters are in the returned list
    local found_adapter1 = false
    local found_adapter2 = false
    
    for _, adapter in ipairs(adapters) do
      if adapter.name == "adapter1" then found_adapter1 = true end
      if adapter.name == "adapter2" then found_adapter2 = true end
    end
    
    assert(found_adapter1, "Should find adapter1 in the list")
    assert(found_adapter2, "Should find adapter2 in the list")
  end)
end)