-- core/markdown.lua
-- Markdown linting and fixing functionality for hooks-util

local M = {}

-- Default configuration
M.config = {
  enabled = true,
  fix_on_save = true,
  lint_tool = "markdownlint",
  config_file = ".markdownlint.json",
  fix_scripts = {
    comprehensive = true,
    list_numbering = true,
    heading_levels = true,
    code_blocks = true,
    newlines = true
  }
}

-- Setup markdown linting and fixing
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

-- Run markdown linting
function M.lint(files)
  if not M.config.enabled then
    return true
  end
  
  local cmd = M.config.lint_tool .. " "
  
  -- Add config file if specified
  if M.config.config_file and M.config.config_file ~= "" then
    cmd = cmd .. "--config " .. M.config.config_file .. " "
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

-- Fix markdown issues
function M.fix(files)
  if not M.config.enabled or not M.config.fix_on_save then
    return true
  end
  
  local success = true
  
  -- Get the absolute path to the script directory
  local script_dir = debug.getinfo(1, "S").source:match("^@(.+)/core/.+$")
  if not script_dir then
    script_dir = ".."  -- Fallback to relative path if detection fails
  end
  
  local scripts_dir = script_dir .. "/scripts/markdown"
  
  -- Apply fix scripts based on configuration
  if M.config.fix_scripts.comprehensive then
    success = success and os.execute(scripts_dir .. "/fix_markdown_comprehensive.sh " .. files)
  else
    -- Apply individual fix scripts if comprehensive is disabled
    if M.config.fix_scripts.list_numbering then
      success = success and os.execute(scripts_dir .. "/fix_list_numbering.sh " .. files)
    end
    
    if M.config.fix_scripts.heading_levels then
      success = success and os.execute(scripts_dir .. "/fix_heading_levels.sh " .. files)
    end
    
    if M.config.fix_scripts.code_blocks then
      success = success and os.execute(scripts_dir .. "/fix_code_blocks.sh " .. files)
    end
    
    if M.config.fix_scripts.newlines then
      success = success and os.execute(scripts_dir .. "/fix_newlines.sh " .. files)
    end
  end
  
  return success
end

-- Install markdown configuration and scripts
function M.install_config(target_dir)
  target_dir = target_dir or "."
  
  -- Create target directory if it doesn't exist
  os.execute("mkdir -p " .. target_dir)
  
  -- Get the absolute path to the script directory
  local script_dir = debug.getinfo(1, "S").source:match("^@(.+)/core/.+$")
  if not script_dir then
    script_dir = ".."  -- Fallback to relative path if detection fails
  end
  
  -- Copy markdownlint configuration
  local config_source = script_dir .. "/templates/markdownlint.json"
  local config_dest = target_dir .. "/" .. M.config.config_file
  os.execute("cp " .. config_source .. " " .. config_dest)
  
  return true
end

return M