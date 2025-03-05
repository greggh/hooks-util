-- hooks-util/core/adapter.lua
-- Core adapter interface module

local M = {}

-- Base adapter class
M.BaseAdapter = {}
M.BaseAdapter.__index = M.BaseAdapter

-- Create a new adapter instance
function M.new(name, opts)
  local self = setmetatable({}, M.BaseAdapter)
  self.name = name
  self.description = opts.description or "Generic adapter"
  self.options = opts or {}
  
  return self
end

-- Base methods that can be overridden by adapters
function M.BaseAdapter:setup() return true end
function M.BaseAdapter:validate(project) return false end
function M.BaseAdapter:get_hooks() return {} end
function M.BaseAdapter:get_ci_templates() return {} end
function M.BaseAdapter:pre_commit_hook() return true end

-- Utils for adapter creation
function M.create_adapter(name, opts)
  return M.new(name, opts)
end

-- Create utils namespace for adapters
M.utils = {}

-- Function to detect project type with support for override
M.utils.detect_project_type = function(project_path)
  -- Check for configuration file with project type override
  local config_path = project_path .. "/.hooks-util.lua"
  local config_file = io.open(config_path, "r")
  if config_file then
    config_file:close()
    
    -- Try to load configuration
    local success, config_data = pcall(function()
      local f = loadfile(config_path)
      if f then
        return f()
      end
      return nil
    end)
    
    -- Check if config has project_type override
    if success and type(config_data) == "table" and config_data.project_type then
      -- If project_type is set to "auto", skip override and proceed to auto-detection
      if config_data.project_type ~= "auto" then
        return config_data.project_type
      end
    end
  end
  
  -- Helper function to check if a file exists
  local function file_exists(path)
    local f = io.open(path, "r")
    if f then
      f:close()
      return true
    else
      return false
    end
  end

  -- Helper function to check if a directory exists
  local function dir_exists(path)
    local cmd = "test -d " .. path
    return os.execute(cmd .. " 2>/dev/null") == 0
  end

  -- Check for Neovim config specifics
  -- Neovim configs typically have init.lua in root plus plugin directory or ftplugin directory
  if file_exists(project_path .. "/init.lua") then
    if dir_exists(project_path .. "/plugin") or 
       dir_exists(project_path .. "/ftplugin") or
       dir_exists(project_path .. "/after") or
       dir_exists(project_path .. "/lua/plugins") or
       file_exists(project_path .. "/lazy-lock.json") or
       file_exists(project_path .. "/packer_compiled.lua") then
      return "neovim-config"
    end
  end

  -- Check for Neovim plugin
  if file_exists(project_path .. "/plugin/init.vim") or
     file_exists(project_path .. "/lua/plugin/init.lua") then
    return "neovim-plugin"
  end

  -- Check for Neovim plugin with namespace pattern
  local cmd = "find " .. project_path .. " -path '" .. project_path .. "/lua/*/init.lua' -type f"
  local handle = io.popen(cmd .. " 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result and result ~= "" then
      return "neovim-plugin"
    end
  end

  -- Check for Lua library
  if dir_exists(project_path .. "/lua") then
    -- If has rockspec, it's definitely a Lua library
    local rockspec_cmd = "find " .. project_path .. " -name '*.rockspec' -type f"
    local rockspec_handle = io.popen(rockspec_cmd .. " 2>/dev/null")
    if rockspec_handle then
      local result = rockspec_handle:read("*a")
      rockspec_handle:close()
      if result and result ~= "" then
        return "lua-lib"
      end
    end
    
    -- If it has init.lua in root but no Neovim-specific directories, probably a Lua library
    if file_exists(project_path .. "/init.lua") then
      return "lua-lib"
    end
    
    -- Generic Lua project
    return "lua-project"
  end

  -- If it has .luacheckrc but none of the above, probably a generic Lua project
  if file_exists(project_path .. "/.luacheckrc") then
    return "lua-project"
  end
  
  return "unknown"
end

return M