#!/usr/bin/env lua
-- Test runner for hooks-util using lust-next

-- Get the directory of this script
local script_dir = debug.getinfo(1).source:match("@(.*/)")
if not script_dir then
  script_dir = "./"
end

-- Setup paths for lust-next and hooks-util
package.path = script_dir .. "../deps/lust-next/?.lua;" 
             .. script_dir .. "../lua/?.lua;" 
             .. script_dir .. "?.lua;" -- Add current directory to find spec_helper
             .. package.path

print("Script directory: " .. script_dir)
print("Package path: " .. package.path)

-- Create mock vim object if needed for Neovim function compatibility
if not _G.vim then
  _G.vim = {
    tbl_deep_extend = function(behavior, ...)
      local result = {}
      for i = 1, select("#", ...) do
        local tbl = select(i, ...)
        for k, v in pairs(tbl) do
          if type(v) == "table" and type(result[k]) == "table" then
            result[k] = _G.vim.tbl_deep_extend(behavior, result[k], v)
          else
            result[k] = v
          end
        end
      end
      return result
    end,
    -- Add other required functions as needed
    fn = {
      stdpath = function(what)
        if what == "config" then
          return os.getenv("HOME") .. "/.config/nvim"
        elseif what == "data" then
          return os.getenv("HOME") .. "/.local/share/nvim"
        end
        return ""
      end
    }
  }
end

-- Try to load lust-next
local success, lust_next = pcall(require, "lust-next")
if not success then
  print("Error loading lust-next: " .. (lust_next or "unknown error"))
  print("Make sure lust-next is installed or available in the package path.")
  os.exit(1)
end

-- Make lust-next globals available
for k, v in pairs(lust_next) do
  if type(v) == "function" then
    print("Setting global: " .. k)
    _G[k] = v
  end
end

-- Set specific aliases for before_each/after_each
_G.before_each = lust_next.before
_G.after_each = lust_next.after

-- Format output
lust_next.format({
  use_color = true,
  show_trace = true,
})

-- Function to find test files
local function find_test_files(dir)
  local files = {}
  local cmd = "find " .. dir .. " -name '*_spec.lua' -type f"
  local handle = io.popen(cmd)
  
  if handle then
    for file in handle:lines() do
      table.insert(files, file)
    end
    handle:close()
  end
  
  return files
end

-- Parse command line arguments
local args = {...}
local filter = args[1]
local tags = args[2]

-- Find all test files
local test_files = find_test_files(script_dir)

-- Run minimal test to verify lust-next integration
local minimal_test = script_dir .. "minimal_spec.lua"
print("\nRunning minimal integration test: " .. minimal_test)
local minimal_result = lust_next.run_file(minimal_test)

if not minimal_result then
  print("Minimal test failed. Exiting.")
  os.exit(1)
end

-- Show test files
print("\nFound " .. #test_files .. " test files:")
for _, file in ipairs(test_files) do
  print("  " .. file)
end

-- Run each test file
local all_success = true
for _, file in ipairs(test_files) do
  if file ~= minimal_test then
    print("\nRunning test file: " .. file)
    
    local file_result = lust_next.run_file(file, {
      filter = filter,
      tags = tags
    })
    
    all_success = all_success and file_result
  end
end

-- Exit with success/failure code for CI
os.exit(all_success and 0 or 1)