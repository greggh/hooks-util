-- hooks-util/core/adapter.lua
-- Base adapter interface for project types
local M = {}

-- Adapter interface that all project type adapters must implement
M.AdapterInterface = {
  -- Basic information
  name = "base", -- Unique name for the adapter
  description = "Base adapter interface, not meant to be used directly",
  version = "0.1.0",
  
  -- Check if this adapter can be used for the current project
  -- Returns boolean indicating if adapter is compatible
  is_compatible = function(self, project_root)
    -- Base implementation always returns false
    return false
  end,
  
  -- Get linter configuration for this project type
  -- Returns linter configuration table
  get_linter_config = function(self, project_root)
    -- Base implementation returns empty config
    return {
      stylua = {
        enabled = true,
        config_file = ".stylua.toml",
      },
      luacheck = {
        enabled = true,
        config_file = ".luacheckrc",
      },
      shellcheck = {
        enabled = true,
      },
    }
  end,
  
  -- Get test configuration for this project type
  -- Returns test configuration table
  get_test_config = function(self, project_root)
    -- Base implementation returns empty config
    return {
      enabled = true,
      framework = "lust-next", -- Default to lust-next
      test_command = nil, -- Must be overridden by concrete adapters
      timeout = 60000, -- 60 second timeout
    }
  end,
  
  -- Get CI workflow templates for this project type
  -- Returns a list of applicable CI template paths
  get_ci_templates = function(self, project_root, platform)
    -- Base implementation returns empty list
    return {}
  end,
  
  -- Generate a configuration file for this project type
  -- Returns boolean indicating success and a message
  generate_config = function(self, project_root, options)
    -- Base implementation just returns not implemented
    return false, "Not implemented in base adapter"
  end,
  
  -- Hook into the pre-commit process for this project type
  -- Returns boolean indicating success
  pre_commit_hook = function(self, project_root, files)
    -- Base implementation just passes through
    return true
  end,
  
  -- Get version verification configuration
  -- Returns version verification configuration
  get_version_config = function(self, project_root)
    -- Base implementation returns standard version config
    return {
      enabled = true,
      version_file = "lua/version.lua",
      patterns = {
        -- Files that should contain version references
        {
          path = "README.md", 
          pattern = "Version: v(%d+%.%d+%.%d+)"
        },
        {
          path = "CHANGELOG.md",
          pattern = "## %[(%d+%.%d+%.%d+)%]"
        }
      }
    }
  end
}

-- Factory function to create a new adapter based on the interface
function M.create(adapter_impl)
  -- Create a new adapter that inherits from the interface
  local adapter = {}
  
  -- Copy all interface methods and properties
  for k, v in pairs(M.AdapterInterface) do
    adapter[k] = v
  end
  
  -- Override with implementation-specific methods and properties
  for k, v in pairs(adapter_impl or {}) do
    adapter[k] = v
  end
  
  return adapter
end

return M