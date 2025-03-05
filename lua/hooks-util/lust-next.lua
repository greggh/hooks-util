-- hooks-util/lua/hooks-util/lust-next.lua
-- Integration with lust-next testing framework
local M = {}

-- Cache the lust-next availability check
local has_lust_next, lust_next = pcall(require, "lust-next")

-- Get lust-next module, loading it if necessary
function M.get_lust_next()
  if not has_lust_next then
    -- Try to load from different paths
    local paths = {
      -- Try local lust-next in project
      "./deps/lust-next/?.lua;",
      -- Try sibling directory (typical development setup)
      "../lust-next/?.lua;",
    }
    
    -- Add these paths to package.path temporarily
    local original_path = package.path
    package.path = table.concat(paths) .. original_path
    
    -- Try loading again
    has_lust_next, lust_next = pcall(require, "lust-next")
    
    -- Restore original path
    package.path = original_path
  end
  
  return has_lust_next, lust_next
end

-- Set up project for lust-next testing
function M.setup_project(project_root, options)
  options = options or {}
  
  -- Create file system operations that work with or without Neovim
  local fs = {}
  
  if vim and vim.fn then
    -- Use Neovim's API if available
    fs.mkdir = function(dir) return vim.fn.mkdir(dir, "p") end
    fs.is_dir = function(dir) return vim.fn.isdirectory(dir) == 1 end
    fs.is_file = function(file) return vim.fn.filereadable(file) == 1 end
    fs.glob = function(pattern) return vim.fn.globpath(project_root, pattern, true) ~= "" end
  else
    -- Use Lua standard library (limited functionality)
    fs.mkdir = function(dir) 
      return os.execute("mkdir -p " .. dir) == 0 
    end
    fs.is_dir = function(dir)
      local attr = lfs.attributes(dir)
      return attr and attr.mode == "directory"
    end
    fs.is_file = function(file)
      local f = io.open(file, "r")
      if f then
        f:close()
        return true
      end
      return false
    end
    fs.glob = function(pattern)
      -- Basic implementation, not as robust as Neovim's
      local result = os.execute("ls " .. project_root .. "/" .. pattern .. " 2>/dev/null")
      return result == 0
    end
  end
  
  -- Check if lust-next is available
  local has_ln, _ = M.get_lust_next()
  if not has_ln then
    return false, "lust-next is not available. Please install it first (e.g., luarocks install lust-next)"
  end
  
  -- Create spec directory if it doesn't exist
  local spec_dir = project_root .. "/spec"
  if not fs.is_dir(spec_dir) then
    if not fs.mkdir(spec_dir) then
      return false, "Failed to create spec directory: " .. spec_dir
    end
  end
  
  -- Create subdirectories for organization
  local subdirs = {"core", "adapters", "ci", "utils"}
  for _, subdir in ipairs(subdirs) do
    local dir = spec_dir .. "/" .. subdir
    if not fs.is_dir(dir) then
      fs.mkdir(dir)
    end
  end
  
  -- Create spec_helper.lua
  local helper_path = spec_dir .. "/spec_helper.lua"
  if not fs.is_file(helper_path) then
    local helper_file = io.open(helper_path, "w")
    if helper_file then
      helper_file:write([[
-- spec_helper.lua
-- Helper utilities for lust-next tests

local M = {}

-- Setup test environment
function M.setup()
  -- Add package path for local development
  package.path = "./lua/?.lua;" .. package.path
  
  -- Load hooks-util with test configuration
  local hooks_util = require("hooks-util")
  hooks_util.setup({
    test_mode = true,
    -- Add test-specific configuration here
    adapters = {
      enabled = {"nvim-plugin", "lua-lib", "nvim-config"}
    }
  })
  
  return hooks_util
end

-- Create mock objects
function M.create_mock(obj_type)
  if obj_type == "project" then
    return {
      root = "/mock/project/path",
      config = {
        hooks = {
          pre_commit = {"lint", "test"}
        },
        project_type = "lua-lib"
      },
      paths = {
        hooks = "/mock/project/path/.hooks",
        config = "/mock/project/path/.hooks-util.lua"
      }
    }
  end
  
  return {}
end

-- Helper to load a module for testing
function M.load_module(name)
  return require("hooks-util." .. name)
end

return M
]])
      helper_file:close()
    else
      return false, "Failed to create spec helper file: " .. helper_path
    end
  end
  
  -- Create runner.lua
  local runner_path = spec_dir .. "/runner.lua"
  if not fs.is_file(runner_path) then
    local runner_file = io.open(runner_path, "w")
    if runner_file then
      runner_file:write([[
#!/usr/bin/env lua
-- Test runner for hooks-util using lust-next

-- Add lust-next to package path
-- We need to handle both local development and CI environments
local function setup_paths()
  local paths = {
    -- Try local lust-next in project
    "./deps/lust-next/?.lua;",
    -- Try sibling directory (typical development setup)
    "../lust-next/?.lua;",
    -- Try from luarocks or global install
    package.path
  }
  
  package.path = table.concat(paths)
end

setup_paths()

-- Load lust-next
local lust_next, err = pcall(require, "lust-next")
if not lust_next then
  print("Error loading lust-next: " .. (err or "unknown error"))
  print("Make sure lust-next is installed or available in the package path.")
  os.exit(1)
end

-- Configure lust_next
lust_next = require("lust-next")
lust_next.format({
  use_color = true,
  show_trace = true,
})

-- Parse command line arguments
local args = {...}
local filter = args[1]
local tags = args[2]

-- Run all tests in spec directory
local success = lust_next.run_discovered("spec", "**/*_spec.lua", {
  filter = filter,
  tags = tags
})

-- Exit with success/failure code for CI
os.exit(success and 0 or 1)
]])
      runner_file:close()
      
      -- Make runner executable
      os.execute("chmod +x " .. runner_path)
    else
      return false, "Failed to create runner file: " .. runner_path
    end
  end
  
  -- Create a sample test file if none exists
  local has_test_files = fs.glob("spec/**/*_spec.lua")
  if not has_test_files then
    local project_name = project_root:match("([^/]+)$") or "hooks-util"
    local test_path = spec_dir .. "/core/core_spec.lua"
    local test_file = io.open(test_path, "w")
    if test_file then
      test_file:write(string.format([[
-- Basic tests for %s core functionality
local helper = require("spec.spec_helper")

describe("core", function()
  local hooks_util
  
  before_each(function()
    -- Set up test environment
    hooks_util = helper.setup()
  end)
  
  it("loads successfully", function()
    assert(hooks_util, "hooks-util loaded")
    assert(hooks_util.setup, "setup function exists")
  end)
  
  it("has adapter registry", function()
    local registry = helper.load_module("core.registry")
    assert(registry, "registry module exists")
    assert(registry.register, "register function exists")
  end)
  
  -- Add more tests as needed
end)
]], project_name))
      test_file:close()
    else
      return false, "Failed to create test file: " .. test_path
    end
  end
  
  -- Add .luacheckrc for tests if it doesn't exist
  local luacheckrc_path = project_root .. "/.luacheckrc"
  if not fs.is_file(luacheckrc_path) then
    local luacheckrc_file = io.open(luacheckrc_path, "w")
    if luacheckrc_file then
      luacheckrc_file:write([[
-- vim: ft=lua tw=80

std = "lua51"

-- Add lust-next globals for spec files
files["spec/**/*.lua"] = {
  globals = {
    -- lust-next globals
    "describe",
    "it",
    "before_each",
    "after_each",
    "before_all",
    "after_all",
    "pending",
    "spy",
    "mock",
    "stub",
    -- commonly used testing globals
    "assert",
  }
}
]])
      luacheckrc_file:close()
    end
  else
    -- Append lust-next globals to existing .luacheckrc if needed
    local luacheckrc_file = io.open(luacheckrc_path, "r")
    if luacheckrc_file then
      local content = luacheckrc_file:read("*a")
      luacheckrc_file:close()
      
      -- Check if lust-next globals are already defined
      if not content:match("files%[\"spec/%*%*/.*%.lua\"%]") then
        -- Append to file
        luacheckrc_file = io.open(luacheckrc_path, "a")
        if luacheckrc_file then
          luacheckrc_file:write([=[

-- Add lust-next globals for spec files
files["spec/**/*.lua"] = {
  globals = {
    -- lust-next globals
    "describe",
    "it",
    "before_each",
    "after_each",
    "before_all",
    "after_all",
    "pending",
    "spy",
    "mock",
    "stub",
    -- commonly used testing globals
    "assert",
  }
}
]=])
          luacheckrc_file:close()
        end
      end
    end
  end
  
  return true, "Successfully set up lust-next for project: " .. project_root
end

-- Generate a CI workflow for lust-next
function M.generate_workflow(project_root, platform)
  platform = platform or "github"
  
  -- GitHub workflow
  if platform == "github" then
    local workflow_dir = project_root .. "/.github/workflows"
    local mkdir_cmd = "mkdir -p " .. workflow_dir
    os.execute(mkdir_cmd)
    
    local workflow_path = workflow_dir .. "/test.yml"
    local workflow_file = io.open(workflow_path, "w")
    if workflow_file then
      workflow_file:write([[
name: Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  test:
    name: Run tests
    runs-on: ubuntu-latest
    strategy:
      matrix:
        lua_version: ['5.1', 'luajit']
      fail-fast: false
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Lua
        uses: leafo/gh-actions-lua@v9
        with:
          luaVersion: ${{ matrix.lua_version }}
      
      - name: Setup Luarocks
        uses: leafo/gh-actions-luarocks@v4
      
      - name: Install lust-next
        run: |
          if [ ${{ matrix.lua_version }} == "5.1" ]; then
            # Install from repository directly for better compatibility
            git clone https://github.com/greggh/lust-next.git
            cd lust-next
            luarocks make
            cd ..
          else
            # Use LuaRocks
            luarocks install --server=https://luarocks.org/dev lust-next
          fi
      
      - name: Install dependencies
        run: |
          if [ -f "*.rockspec" ]; then
            # Extract dependencies from rockspec
            ROCKSPEC=$(ls -1 *.rockspec | head -1)
            echo "Using rockspec: $ROCKSPEC"
            
            # Install dependencies
            luarocks install --only-deps $ROCKSPEC
          else
            echo "No rockspec found, skipping dependency installation"
          fi
      
      - name: Run tests
        run: |
          chmod +x spec/runner.lua
          ./spec/runner.lua
]])
      workflow_file:close()
      return true, "Created GitHub workflow for lust-next tests: " .. workflow_path
    else
      return false, "Failed to create GitHub workflow"
    end
  elseif platform == "gitlab" then
    local gitlab_ci_path = project_root .. "/.gitlab-ci.yml"
    local gitlab_ci_file = io.open(gitlab_ci_path, "w")
    if gitlab_ci_file then
      gitlab_ci_file:write([[
# GitLab CI configuration for lust-next tests

stages:
  - test

# Test with Lua 5.1
test:lua51:
  stage: test
  image: alpinelinux/build-base:latest
  variables:
    LUA_VERSION: "5.1"
  before_script:
    - apk add --no-cache lua5.1 lua5.1-dev luarocks5.1 git
    - luarocks-5.1 install luafilesystem
    - git clone https://github.com/greggh/lust-next.git
    - cd lust-next && luarocks-5.1 make && cd ..
  script:
    - chmod +x spec/runner.lua
    - ./spec/runner.lua

# Test with LuaJIT
test:luajit:
  stage: test
  image: alpinelinux/build-base:latest
  variables:
    LUA_VERSION: "luajit"
  before_script:
    - apk add --no-cache luajit luajit-dev luarocks git
    - luarocks install luafilesystem
    - luarocks install --server=https://luarocks.org/dev lust-next
  script:
    - chmod +x spec/runner.lua
    - ./spec/runner.lua
]])
      gitlab_ci_file:close()
      return true, "Created GitLab CI configuration for lust-next tests: " .. gitlab_ci_path
    else
      return false, "Failed to create GitLab CI configuration"
    end
  else
    return false, "CI platform not yet supported: " .. platform
  end
end

-- Run tests with lust-next
function M.run_tests(project_root, options)
  options = options or {}
  
  -- Check if lust-next is available
  local has_ln, ln = M.get_lust_next()
  if not has_ln then
    return false, "lust-next is not available. Please install it first"
  end
  
  -- Check if spec directory exists
  local spec_dir = project_root .. "/spec"
  local is_dir = function(dir)
    return os.execute("test -d " .. dir) == 0
  end
  
  if not is_dir(spec_dir) then
    return false, "spec directory not found: " .. spec_dir
  end
  
  -- Check if runner file exists
  local runner_path = spec_dir .. "/runner.lua"
  local is_file = function(file)
    return os.execute("test -f " .. file) == 0
  end
  
  if not is_file(runner_path) then
    return false, "runner file not found: " .. runner_path
  end
  
  -- Make sure the runner is executable
  os.execute("chmod +x " .. runner_path)
  
  -- Run tests
  local cmd = "cd " .. project_root .. " && "
  
  if options.filter and options.tags then
    cmd = cmd .. string.format('./spec/runner.lua "%s" "%s"', options.filter, options.tags)
  elseif options.filter then
    cmd = cmd .. string.format('./spec/runner.lua "%s"', options.filter)
  elseif options.tags then
    cmd = cmd .. string.format('./spec/runner.lua "" "%s"', options.tags)
  else
    cmd = cmd .. "./spec/runner.lua"
  end
  
  local exit_code = os.execute(cmd)
  if exit_code == 0 then
    return true, "Tests passed"
  else
    return false, "Tests failed"
  end
end

-- Add lust-next as a dependency to a project
function M.add_as_dependency(project_root, options)
  options = options or {}
  local method = options.method or "git"
  
  if method == "git" then
    -- Add as git submodule
    local submodule_path = options.path or "deps/lust-next"
    local cmd = string.format(
      "cd %s && git submodule add https://github.com/greggh/lust-next.git %s",
      project_root,
      submodule_path
    )
    
    local result = os.execute(cmd)
    if result == 0 then
      return true, "Added lust-next as git submodule to: " .. submodule_path
    else
      return false, "Failed to add lust-next as git submodule"
    end
  elseif method == "rockspec" then
    -- Add to rockspec dependencies
    local rockspec_files = {}
    local find_cmd = string.format("find %s -name '*.rockspec'", project_root)
    local find_handle = io.popen(find_cmd)
    
    if find_handle then
      for line in find_handle:lines() do
        table.insert(rockspec_files, line)
      end
      find_handle:close()
    end
    
    if #rockspec_files == 0 then
      return false, "No rockspec file found in project"
    end
    
    -- Update the first rockspec file found
    local rockspec_path = rockspec_files[1]
    local rockspec_file = io.open(rockspec_path, "r")
    if not rockspec_file then
      return false, "Failed to open rockspec file: " .. rockspec_path
    end
    
    local content = rockspec_file:read("*a")
    rockspec_file:close()
    
    -- Check if lust-next is already a dependency
    if content:match("lust%-next") then
      return true, "lust-next is already a dependency in rockspec"
    end
    
    -- Find the dependencies section and add lust-next
    local updated_content = content:gsub(
      "(dependencies%s*=%s*{[^}]*)",
      "%1\n    \"lust-next >= 0.7.0\","
    )
    
    -- If no change was made, the dependencies section might have a different format
    if updated_content == content then
      return false, "Failed to update rockspec, dependencies section not found or has unexpected format"
    end
    
    -- Write updated content back to file
    rockspec_file = io.open(rockspec_path, "w")
    if not rockspec_file then
      return false, "Failed to write to rockspec file: " .. rockspec_path
    end
    
    rockspec_file:write(updated_content)
    rockspec_file:close()
    
    return true, "Added lust-next as a dependency to rockspec file: " .. rockspec_path
  else
    return false, "Unsupported dependency method: " .. method
  end
end

return M