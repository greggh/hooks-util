-- core/json.lua
-- JSON linting functionality for hooks-util

local M = {}

-- Default configuration
M.config = {
  enabled = true,
  lint_tool = "jsonlint",
  config_file = ".jsonlintrc", -- Some tools use configuration files
  allow_comments = false,
  allow_trailing_commas = false
}

-- Setup JSON linting
function M.setup(opts)
  opts = opts or {}
  
  -- Merge configuration with defaults
  for k, v in pairs(opts) do
    M.config[k] = v
  end
  
  return M
end

-- Run JSON linting
function M.lint(files)
  if not M.config.enabled then
    return true
  end
  
  local cmd = M.config.lint_tool .. " "
  
  -- Add config file if specified and supported by the tool
  if M.config.config_file and M.config.config_file ~= "" then
    cmd = cmd .. "--config " .. M.config.config_file .. " "
  end
  
  -- Add common options if available for the selected tool
  -- Note: These flags are for jsonlint, might need to be adjusted for other tools
  if M.config.allow_comments then
    cmd = cmd .. "--allow-comments "
  end
  
  if M.config.allow_trailing_commas then
    cmd = cmd .. "--allow-trailing-commas "
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

-- Install JSON configuration if needed
function M.install_config(target_dir)
  target_dir = target_dir or "."
  
  -- Only install config if a config file is specified
  if not M.config.config_file or M.config.config_file == "" then
    return true
  end
  
  -- Create target directory if it doesn't exist
  os.execute("mkdir -p " .. target_dir)
  
  -- Get the absolute path to the script directory
  local script_dir = debug.getinfo(1, "S").source:match("^@(.+)/core/.+$")
  if not script_dir then
    script_dir = ".."  -- Fallback to relative path if detection fails
  end
  
  -- Copy jsonlint configuration if present
  local config_source = script_dir .. "/templates/jsonlint.json"
  local config_dest = target_dir .. "/" .. M.config.config_file
  os.execute("cp " .. config_source .. " " .. config_dest)
  
  return true
end

return M