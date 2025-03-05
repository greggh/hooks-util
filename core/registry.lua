-- hooks-util/core/registry.lua
-- Registry for adapter discovery and management
local M = {}

-- Available adapters (loaded dynamically)
M.adapters = {}

-- Project root detection helpers
local function find_file_upwards(file_name, start_dir)
  local path = start_dir or vim.fn.getcwd()
  local prev_path = nil
  
  while path ~= prev_path do
    local file_path = path .. "/" .. file_name
    -- Check if file exists
    local f = io.open(file_path, "r")
    if f then
      f:close()
      return file_path
    end
    
    -- Move up one directory
    prev_path = path
    path = vim.fn.fnamemodify(path, ":h")
  end
  
  return nil
end

-- Find project root based on common marker files
function M.find_project_root(start_dir)
  local marker_files = {
    ".git",
    "package.json",
    "init.lua",
    "rockspec",
    ".nvim.lua",
    ".stylua.toml",
  }
  
  for _, marker in ipairs(marker_files) do
    local file_path = find_file_upwards(marker, start_dir)
    if file_path then
      return vim.fn.fnamemodify(file_path, ":h")
    end
  end
  
  return nil
end

-- Load all adapters from the adapters directory
function M.load_adapters()
  local adapter_paths = {
    "/home/gregg/Projects/hooks-util/adapters/nvim-plugin/init.lua",
    "/home/gregg/Projects/hooks-util/adapters/nvim-config/init.lua",
    "/home/gregg/Projects/hooks-util/adapters/lua-lib/init.lua",
    -- Add more adapter paths as needed
  }
  
  for _, path in ipairs(adapter_paths) do
    local ok, adapter = pcall(dofile, path)
    if ok and adapter then
      table.insert(M.adapters, adapter)
    end
  end
end

-- Detect the most appropriate adapter for a project
function M.detect_adapter(project_root)
  project_root = project_root or M.find_project_root()
  if not project_root then
    return nil, "Could not determine project root"
  end
  
  -- Ensure adapters are loaded
  if #M.adapters == 0 then
    M.load_adapters()
  end
  
  -- Find the first compatible adapter
  for _, adapter in ipairs(M.adapters) do
    if adapter.is_compatible(project_root) then
      return adapter, nil
    end
  end
  
  return nil, "No compatible adapter found for project: " .. project_root
end

-- Get adapter by name
function M.get_adapter_by_name(name)
  -- Ensure adapters are loaded
  if #M.adapters == 0 then
    M.load_adapters()
  end
  
  for _, adapter in ipairs(M.adapters) do
    if adapter.name == name then
      return adapter
    end
  end
  
  return nil, "Adapter not found: " .. name
end

-- Get all available adapters
function M.get_all_adapters()
  -- Ensure adapters are loaded
  if #M.adapters == 0 then
    M.load_adapters()
  end
  
  return M.adapters
end

return M