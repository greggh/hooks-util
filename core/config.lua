-- hooks-util/core/config.lua
-- Configuration management for hooks-util
local M = {}

-- Default configuration
M.default_config = {
  -- Core settings
  project_type = nil, -- Will be auto-detected if not specified
  
  -- Linting
  linting = {
    enabled = true,
    stylua = {
      enabled = true,
      config_file = ".stylua.toml",
      args = "--check",
    },
    luacheck = {
      enabled = true,
      config_file = ".luacheckrc",
    },
    shellcheck = {
      enabled = true,
    },
  },
  
  -- Testing
  testing = {
    enabled = true,
    framework = "lust-next", -- Default testing framework
    timeout = 60000, -- 60 seconds
  },
  
  -- CI settings
  ci = {
    primary_platform = "github",
    additional_platforms = {},
    config = {
      github = {
        workflows_dir = ".github/workflows",
        enable_matrix_testing = true,
      },
      gitlab = {
        config_path = ".gitlab-ci.yml",
      },
      azure = {
        config_path = "azure-pipelines.yml",
      },
    },
  },
  
  -- Version management
  version = {
    enabled = true,
    check_consistency = true,
    version_file = "lua/version.lua",
  },
  
  -- Hooks
  hooks = {
    pre_commit = {
      enabled = true,
      run_linters = true,
      run_tests = true,
      check_version = true,
    },
    pre_push = {
      enabled = false,
      run_tests = true,
    },
  },
}

-- Current configuration (initialized with defaults)
M.config = vim.deepcopy(M.default_config)

-- Load config from file
function M.load_config(file_path)
  file_path = file_path or "hooks-util.config.lua"
  
  -- Try to load configuration file
  local ok, user_config = pcall(dofile, file_path)
  if not ok or type(user_config) ~= "table" then
    return false, "Failed to load configuration from " .. file_path
  end
  
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("force", M.default_config, user_config)
  
  return true
end

-- Save config to file
function M.save_config(file_path)
  file_path = file_path or "hooks-util.config.lua"
  
  -- Convert config to lua code
  local config_lines = {"-- hooks-util configuration", "return {"}
  
  -- Helper function to serialize a table
  local function serialize_table(tbl, indent)
    indent = indent or "  "
    local lines = {}
    
    for k, v in pairs(tbl) do
      if type(v) == "table" then
        table.insert(lines, indent .. k .. " = {")
        local nested_lines = serialize_table(v, indent .. "  ")
        for _, line in ipairs(nested_lines) do
          table.insert(lines, line)
        end
        table.insert(lines, indent .. "},")
      elseif type(v) == "string" then
        table.insert(lines, indent .. k .. ' = "' .. v .. '",')
      elseif type(v) == "boolean" or type(v) == "number" then
        table.insert(lines, indent .. k .. " = " .. tostring(v) .. ",")
      elseif v == nil then
        table.insert(lines, indent .. k .. " = nil,")
      end
    end
    
    return lines
  end
  
  -- Serialize config
  local config_body = serialize_table(M.config)
  for _, line in ipairs(config_body) do
    table.insert(config_lines, line)
  end
  
  table.insert(config_lines, "}")
  
  -- Write to file
  local file = io.open(file_path, "w")
  if not file then
    return false, "Failed to open file for writing: " .. file_path
  end
  
  file:write(table.concat(config_lines, "\n"))
  file:close()
  
  return true
end

-- Generate config based on project type
function M.generate_config(project_root, project_type)
  local registry = require("hooks-util.core.registry")
  
  -- Get adapter
  local adapter
  if project_type then
    adapter = registry.get_adapter_by_name(project_type)
  else
    adapter = registry.detect_adapter(project_root)
  end
  
  if not adapter then
    return false, "Could not find appropriate adapter for project"
  end
  
  -- Generate config based on adapter
  local linter_config = adapter:get_linter_config(project_root)
  local test_config = adapter:get_test_config(project_root)
  local version_config = adapter:get_version_config(project_root)
  
  -- Create new config
  local new_config = vim.deepcopy(M.default_config)
  new_config.project_type = adapter.name
  
  -- Apply adapter-specific settings
  if linter_config then
    new_config.linting = vim.tbl_deep_extend("force", new_config.linting, linter_config)
  end
  
  if test_config then
    new_config.testing = vim.tbl_deep_extend("force", new_config.testing, test_config)
  end
  
  if version_config then
    new_config.version = vim.tbl_deep_extend("force", new_config.version, version_config)
  end
  
  -- Set the config
  M.config = new_config
  
  -- Save the config
  local success, err = M.save_config(project_root .. "/hooks-util.config.lua")
  if not success then
    return false, err
  end
  
  return true
end

return M