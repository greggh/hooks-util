-- hooks-util registry module
-- A test placeholder for the lust-next integration

local M = {}

-- Registry storage
local adapters = {}

-- Register an adapter
function M.register(adapter)
  if not adapter or not adapter.name then
    return false, "Invalid adapter"
  end
  
  adapters[adapter.name] = adapter
  return true
end

-- Get a specific adapter
function M.get_adapter(name)
  return adapters[name]
end

-- Get all adapters
function M.get_adapters()
  local result = {}
  for _, adapter in pairs(adapters) do
    table.insert(result, adapter)
  end
  return result
end

-- Load all available adapters
function M.load_adapters()
  local success, config = pcall(require, "hooks-util.core.config")
  if not success then
    return false, "Failed to load config module"
  end
  
  local enabled_adapters = config.get("adapters.enabled") or {}
  
  for _, adapter_name in ipairs(enabled_adapters) do
    local success, adapter = pcall(require, "hooks-util.adapters." .. adapter_name)
    if success and adapter then
      M.register(adapter)
    end
  end
  
  return true
end

-- Detect adapter for a project
function M.detect_adapter(project_path)
  for _, adapter in pairs(adapters) do
    if adapter.validate and adapter.validate({ root = project_path }) then
      return adapter
    end
  end
  return nil
end

-- For testing only
function M._reset_for_tests()
  adapters = {}
end

return M