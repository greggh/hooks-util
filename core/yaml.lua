-- core/yaml.lua
-- YAML linting functionality for hooks-util

local M = {}

-- Default configuration
M.config = {
  enabled = true,
  lint_tool = "yamllint",
  config_file = ".yamllint.yml",
  strict = false
}

-- Setup YAML linting
function M.setup(opts)
  opts = opts or {}
  
  -- Merge configuration with defaults
  for k, v in pairs(opts) do
    M.config[k] = v
  end
  
  return M
end

-- Run YAML linting
function M.lint(files)
  if not M.config.enabled then
    return true
  end
  
  local cmd = M.config.lint_tool .. " "
  
  -- Add config file if specified
  if M.config.config_file and M.config.config_file ~= "" then
    cmd = cmd .. "-c " .. M.config.config_file .. " "
  end
  
  -- Add strict mode if enabled
  if M.config.strict then
    cmd = cmd .. "-s "
  end
  
  -- Add files to the command
  if type(files) == "table" then
    cmd = cmd .. table.concat(files, " ")
  else
    cmd = cmd .. files
  end
  
  -- Execute the command
  local result = os.execute(cmd)
  
  return result == 0
end

-- Install YAML configuration
function M.install_config(target_dir)
  target_dir = target_dir or "."
  
  -- Create target directory if it doesn't exist
  os.execute("mkdir -p " .. target_dir)
  
  -- Get the absolute path to the script directory
  local script_dir = debug.getinfo(1, "S").source:match("^@(.+)/core/.+$")
  if not script_dir then
    script_dir = ".."  -- Fallback to relative path if detection fails
  end
  
  -- Copy yamllint configuration
  local config_source = script_dir .. "/templates/yamllint.yml"
  local config_dest = target_dir .. "/" .. M.config.config_file
  os.execute("cp " .. config_source .. " " .. config_dest)
  
  return true
end

return M