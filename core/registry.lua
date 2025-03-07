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
  -- Get the directory of the current script
  local script_path = debug.getinfo(1, "S").source:sub(2)
  local script_dir = script_path:match("(.*/)")
  local adapters_dir = script_dir:gsub("/core/$", "/adapters/")
  
  -- Known adapter types
  local adapter_types = {
    "nvim-plugin",
    "nvim-config",
    "lua-lib",
    "docs"
  }
  
  -- Load each adapter
  for _, adapter_type in ipairs(adapter_types) do
    local adapter_path = adapters_dir .. adapter_type .. "/init.lua"
    local ok, adapter = pcall(dofile, adapter_path)
    if ok and adapter then
      table.insert(M.adapters, adapter)
    else
      print("Failed to load adapter: " .. adapter_type)
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