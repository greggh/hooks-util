-- lib/yaml_util.lua
-- YAML utilities for reading, writing, and merging YAML files

local M = {}

-- We'll use luaYAML as the default library, but could be configured
local yaml_lib_path = "yaml"

-- Helper function to deeply merge tables
local function deep_merge(target, source)
  -- If source is not a table, return it to overwrite target
  if type(source) ~= "table" then
    return source
  end
  
  -- If target is not a table, make it one
  if type(target) ~= "table" then
    target = {}
  end
  
  -- Merge source into target
  for k, v in pairs(source) do
    if type(v) == "table" and type(target[k]) == "table" then
      -- Recursively merge nested tables
      target[k] = deep_merge(target[k], v)
    else
      -- Overwrite or add values
      target[k] = v
    end
  end
  
  return target
end

-- Read a YAML file and return its contents as a Lua table
function M.read(file_path)
  -- Check if file exists
  local f = io.open(file_path, "r")
  if not f then
    return nil
  end
  
  -- Read file contents
  local content = f:read("*all")
  f:close()
  
  -- Load the YAML library
  local yaml = require(yaml_lib_path)
  
  -- Parse YAML content
  local success, result = pcall(function() return yaml.load(content) end)
  
  if not success then
    return nil
  end
  
  return result
end

-- Write a Lua table to a YAML file
function M.write(data, file_path)
  -- Load the YAML library
  local yaml = require(yaml_lib_path)
  
  -- Convert table to YAML
  local success, yaml_str = pcall(function() return yaml.dump(data) end)
  
  if not success then
    return false
  end
  
  -- Write YAML to file
  local f = io.open(file_path, "w")
  if not f then
    return false
  end
  
  f:write(yaml_str)
  f:close()
  
  return true
end

-- Merge two YAML structures (as Lua tables)
function M.merge(base, extension)
  -- If either is nil, return the other
  if not base then
    return extension
  end
  
  if not extension then
    return base
  end
  
  -- Perform a deep merge
  return deep_merge(base, extension)
end

-- Merge two YAML files and write the result to a new file
function M.merge_files(base_file, extension_file, output_file)
  -- Read the base YAML file
  local base = M.read(base_file)
  
  -- Read the extension YAML file
  local extension = M.read(extension_file)
  
  -- Merge the two
  local merged = M.merge(base, extension)
  
  -- Write the merged result
  return M.write(merged, output_file)
end

return M