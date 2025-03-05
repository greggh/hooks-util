-- hooks-util/lua/hooks-util/init.lua
-- Main entry point for hooks-util
local M = {}

-- Load version information
local version = require("version")
M.version = version

-- Import core modules
M.registry = require("hooks-util.core.registry")
M.config = require("hooks-util.core.config")
M.adapter = require("hooks-util.core.adapter")

-- Setup function
function M.setup(opts)
  -- Initialize with custom configuration if provided
  if opts then
    M.config.config = vim.tbl_deep_extend("force", M.config.default_config, opts)
  end
  
  -- Ensure adapters are loaded
  M.registry.load_adapters()
  
  return M
end

-- Get the appropriate adapter for the current project
function M.get_adapter(project_root, adapter_name)
  if adapter_name then
    return M.registry.get_adapter_by_name(adapter_name)
  else
    return M.registry.detect_adapter(project_root)
  end
end

-- Generate configuration for a project
function M.generate_config(project_root, adapter_name)
  return M.config.generate_config(project_root, adapter_name)
end

-- Install hooks for a project
function M.install_hooks(project_root, force)
  local adapter = M.get_adapter(project_root)
  if not adapter then
    return false, "Could not find appropriate adapter for project"
  end
  
  -- TODO: Implement hook installation logic
  -- For now, we'll just return success
  return true
end

-- Run pre-commit hook
function M.run_pre_commit(project_root, files)
  local adapter = M.get_adapter(project_root)
  if not adapter then
    return false, "Could not find appropriate adapter for project"
  end
  
  -- Run adapter-specific pre-commit hook
  local success = adapter:pre_commit_hook(project_root, files)
  
  return success
end

-- Get available CI workflow templates
function M.get_ci_templates(project_root, platform)
  local adapter = M.get_adapter(project_root)
  if not adapter then
    return {}
  end
  
  return adapter:get_ci_templates(project_root, platform)
end

-- Install CI workflow templates
function M.install_ci_templates(project_root, platform)
  local templates = M.get_ci_templates(project_root, platform)
  
  -- TODO: Implement CI template installation logic
  -- For now, we'll just return success
  return true
end

-- Setup wizard function (for CLI use)
function M.setup_wizard(project_root)
  -- Load setup module
  local setup = require('hooks-util.setup')
  
  -- Run the interactive setup wizard
  return setup.run_wizard(project_root)
end

-- Lust-Next integration
M.lust_next = require('hooks-util.lust-next')

return M