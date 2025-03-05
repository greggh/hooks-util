-- hooks-util/lua/hooks-util/lust-next.lua
-- Integration with lust-next testing framework
local M = {}

-- Check if lust-next is available
local has_lust_next = pcall(require, "lust-next")

-- Set up project for lust-next testing
function M.setup_project(project_root, options)
  options = options or {}
  
  -- If lust-next is not available, we can't set up the project
  if not has_lust_next then
    return false, "lust-next is not available. Please install it first (e.g., luarocks install lust-next)"
  end
  
  -- Create spec directory if it doesn't exist
  local spec_dir = project_root .. "/spec"
  if vim.fn.isdirectory(spec_dir) ~= 1 then
    vim.fn.mkdir(spec_dir, "p")
  end
  
  -- Create runner file if it doesn't exist
  local runner_path = spec_dir .. "/runner.lua"
  if vim.fn.filereadable(runner_path) ~= 1 then
    local runner_file = io.open(runner_path, "w")
    if runner_file then
      runner_file:write([[
-- Test runner for lust-next
local lust_next = require("lust-next")
local results = lust_next.run_tests({
  paths = { "spec" },        -- Run all tests in spec directory
  filter = arg[1],           -- Allow filtering from command line
  verbose = true,            -- Detailed output
  stop_on_first_failure = false
})

-- Exit with appropriate status code
os.exit(results.failures > 0 and 1 or 0)
]])
      runner_file:close()
    else
      return false, "Failed to create runner file: " .. runner_path
    end
  end
  
  -- Create a basic test file if none exists
  local has_test_files = vim.fn.globpath(spec_dir, "*.lua", true) ~= ""
  if not has_test_files then
    local project_name = vim.fn.fnamemodify(project_root, ":t")
    local test_path = spec_dir .. "/basic_test.lua"
    local test_file = io.open(test_path, "w")
    if test_file then
      test_file:write(string.format([[
-- Basic tests for %s
describe("%s", function()
  -- Add setup code here if needed
  
  it("has tests", function()
    -- This test always passes, replace with actual tests
    assert(true, "Tests are running")
  end)
  
  -- Add more tests here
end)
]], project_name, project_name))
      test_file:close()
    else
      return false, "Failed to create test file: " .. test_path
    end
  end
  
  -- Add .luacheckrc for tests if it doesn't exist
  local luacheckrc_path = project_root .. "/.luacheckrc"
  if vim.fn.filereadable(luacheckrc_path) ~= 1 then
    local luacheckrc_file = io.open(luacheckrc_path, "w")
    if luacheckrc_file then
      luacheckrc_file:write([[
-- vim: ft=lua tw=80

std = "lua51"

-- Add lust-next globals for spec files
files["spec/**/*.lua"] = {
  globals = {
    "describe",
    "it",
    "before_each",
    "after_each",
    "pending",
    "setup",
    "teardown",
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
    "describe",
    "it",
    "before_each",
    "after_each",
    "pending",
    "setup",
    "teardown",
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
  -- GitHub workflow
  if platform == "github" then
    local workflow_dir = project_root .. "/.github/workflows"
    if vim.fn.isdirectory(workflow_dir) ~= 1 then
      vim.fn.mkdir(workflow_dir, "p")
    end
    
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
        lua_version: ['5.1', '5.2', '5.3', '5.4', 'luajit']
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
        run: luarocks install --server=https://luarocks.org/dev lust-next
      
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
        run: lua spec/runner.lua
]])
      workflow_file:close()
      return true, "Created GitHub workflow for lust-next tests: " .. workflow_path
    else
      return false, "Failed to create GitHub workflow"
    end
  else
    return false, "CI platform not yet supported: " .. (platform or "unknown")
  end
end

-- Run tests with lust-next
function M.run_tests(project_root, options)
  options = options or {}
  
  -- Check if lust-next is available
  if not has_lust_next then
    return false, "lust-next is not available. Please install it first"
  end
  
  -- Check if spec directory exists
  local spec_dir = project_root .. "/spec"
  if vim.fn.isdirectory(spec_dir) ~= 1 then
    return false, "spec directory not found: " .. spec_dir
  end
  
  -- Check if runner file exists
  local runner_path = spec_dir .. "/runner.lua"
  if vim.fn.filereadable(runner_path) ~= 1 then
    return false, "runner file not found: " .. runner_path
  end
  
  -- Run tests
  local cmd
  if options.filter then
    cmd = string.format('cd %s && lua spec/runner.lua "%s"', project_root, options.filter)
  else
    cmd = string.format('cd %s && lua spec/runner.lua', project_root)
  end
  
  local result = os.execute(cmd)
  if result == 0 then
    return true, "Tests passed"
  else
    return false, "Tests failed"
  end
end

return M