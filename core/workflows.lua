-- core/workflows.lua
-- GitHub workflow management system for hooks-util

local M = {}

-- Default configuration
M.config = {
  enabled = true,
  workflows = {
    ci = true,
    markdown_lint = true,
    yaml_lint = true,
    scripts_lint = true,
    docs = true,
    release = true,
    dependency_updates = false
  },
  workflow_dir = ".github/workflows",
  preserve_custom = true -- Preserve custom workflow content where possible
}

-- The default workflows available - to be used for lookup
M.available_workflows = {
  ci = "ci.yml",
  markdown_lint = "markdown-lint.yml",
  yaml_lint = "yaml-lint.yml",
  scripts_lint = "scripts-lint.yml",
  docs = "docs.yml",
  release = "release.yml",
  dependency_updates = "dependency-updates.yml"
}

-- Setup workflow management
function M.setup(opts)
  opts = opts or {}
  
  -- Merge configuration with defaults
  for k, v in pairs(opts) do
    if type(v) == "table" and type(M.config[k]) == "table" then
      -- For nested tables, merge instead of replace
      for k2, v2 in pairs(v) do
        M.config[k][k2] = v2
      end
    else
      M.config[k] = v
    end
  end
  
  return M
end

-- Get base workflow template path
function M.get_base_workflow_path(workflow_name)
  -- Path to base workflow templates
  local base_path = "../ci/github/workflows/"
  return base_path .. workflow_name
end

-- Get adapter configuration path for a workflow
function M.get_adapter_config_path(adapter_name, workflow_name)
  -- Path to adapter-specific workflow configurations
  local adapter_path = "../ci/github/configs/" .. adapter_name .. "/"
  
  -- Convert workflow.yml to workflow.config.yml pattern
  local config_name = workflow_name:gsub("%.yml$", ".config.yml")
  
  return adapter_path .. config_name
end

-- Merge base workflow with adapter configuration
function M.merge_workflow(base_workflow, adapter_config)
  local yaml_util_path = "../lib/yaml_util.lua"
  local yaml_util = dofile(yaml_util_path)
  
  -- Parse the base workflow YAML
  local base = yaml_util.read(base_workflow)
  
  -- If no adapter config, just return the base
  if not adapter_config then
    return base
  end
  
  -- Parse the adapter config YAML
  local adapter = yaml_util.read(adapter_config)
  
  -- Merge adapter config into base workflow
  local merged = yaml_util.merge(base, adapter)
  
  return merged
end

-- Install workflow for a project
function M.install_workflow(workflow_name, target_dir, adapter_name)
  if not M.config.enabled then
    return true
  end
  
  target_dir = target_dir or "."
  local workflow_dir = target_dir .. "/" .. M.config.workflow_dir
  
  -- Create workflow directory if it doesn't exist
  os.execute("mkdir -p " .. workflow_dir)
  
  -- Get base workflow path
  local base_workflow_path = M.get_base_workflow_path(workflow_name)
  
  -- Get adapter configuration path if adapter specified
  local adapter_config_path = nil
  if adapter_name then
    adapter_config_path = M.get_adapter_config_path(adapter_name, workflow_name)
    
    -- Check if the adapter config exists
    local adapter_config_exists = os.execute("test -f " .. adapter_config_path)
    if adapter_config_exists ~= 0 then
      adapter_config_path = nil
    end
  end
  
  -- Output path for the workflow
  local output_workflow_path = workflow_dir .. "/" .. workflow_name
  
  -- Check if the workflow already exists
  local workflow_exists = os.execute("test -f " .. output_workflow_path)
  
  if workflow_exists == 0 and M.config.preserve_custom then
    -- If preserving custom content, we need to merge with existing
    -- This requires more sophisticated merging logic
    -- For now, backup the existing file and install new one
    os.execute("cp " .. output_workflow_path .. " " .. output_workflow_path .. ".bak")
  end
  
  -- Merge base workflow with adapter configuration
  local merged_workflow = M.merge_workflow(base_workflow_path, adapter_config_path)
  
  -- Write the merged workflow to the target location
  local yaml_util_path = "../lib/yaml_util.lua"
  local yaml_util = dofile(yaml_util_path)
  yaml_util.write(merged_workflow, output_workflow_path)
  
  return true
end

-- Install all applicable workflows for a project
function M.install_workflows(target_dir, adapter_name)
  if not M.config.enabled then
    return true
  end
  
  local success = true
  
  -- Install each enabled workflow
  for workflow_key, enabled in pairs(M.config.workflows) do
    if enabled then
      local workflow_name = M.available_workflows[workflow_key]
      if workflow_name then
        success = success and M.install_workflow(workflow_name, target_dir, adapter_name)
      end
    end
  end
  
  return success
end

return M