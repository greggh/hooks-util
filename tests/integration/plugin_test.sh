#!/bin/bash
# Neovim plugin integration test for hooks-util
set -e  # Exit on any error

# Determine script and project directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEST_DIR=$(mktemp -d)

cleanup() {
  rm -rf "$TEST_DIR"
  echo "Cleaned up test directory"
}

trap cleanup EXIT

echo "=== hooks-util Neovim Plugin Integration Test ==="
echo "Creating test Neovim plugin in $TEST_DIR"

# Set up test repository mimicking a Neovim plugin
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
git init
git config user.name "Test User"
git config user.email "test@example.com"

# Create Neovim plugin structure
mkdir -p lua/test-plugin
mkdir -p tests/spec
mkdir -p doc

# Create some initial files
cat > lua/test-plugin/init.lua << 'EOF'
-- Main plugin init file
local M = {}

function M.setup(opts)
  opts = opts or {}
  
  -- Set default options
  M.options = {
    enabled = opts.enabled ~= false,
    verbose = opts.verbose or false,
    auto_setup = opts.auto_setup ~= false
  }
  
  -- Load components
  require("test-plugin.utils")
  
  return M
end

return M
EOF

cat > lua/test-plugin/utils.lua << 'EOF'
-- Utility functions
local M = {}

-- Check if a file exists
function M.file_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

return M
EOF

# Add files to Git
git add lua doc
git commit -m "Initial plugin setup"

# Create a file with issues
cat > lua/test-plugin/commands.lua << 'EOF'
-- Plugin commands
local M = {}    

function M.register_commands()
    local namespace = "test-plugin"
    local commands = {
        TestCommand = function()
            local result = "test"
            print("Running test command")    
        end,
    }
    
    for command_name, command_fn in pairs(commands) do
        vim.api.nvim_create_user_command(command_name, command_fn, {})
    end
end

return M
EOF

# Add the file to Git
git add lua/test-plugin/commands.lua

# Set up hooks-util
echo "Setting up hooks-util"
mkdir -p .hooks-util
cp -r "$PROJECT_DIR/"* .hooks-util/

# Create a configuration
cat > .hooksrc << 'EOF'
HOOKS_STYLUA_ENABLED=true
HOOKS_LUACHECK_ENABLED=true
HOOKS_TESTS_ENABLED=false
HOOKS_QUALITY_ENABLED=true
HOOKS_VERBOSITY=2
EOF

# Set up StyLua config
cat > .stylua.toml << 'EOF'
column_width = 100
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
EOF

# Set up Luacheck config
cat > .luacheckrc << 'EOF'
-- Global objects
globals = {
  "vim",
}

-- Don't report unused self arguments of methods
self = false

-- Don't report unused arguments
unused_args = false

-- Max line length
max_line_length = 100
EOF

# Set up Makefile with test target
cat > Makefile << 'EOF'
.PHONY: test

test:
	nvim --headless -u tests/minimal-init.lua -c "lua require('plenary.busted').run('./tests/spec')" -c "qa!"
EOF

# Create minimal-init.lua
mkdir -p tests
cat > tests/minimal-init.lua << 'EOF'
-- Minimal init file for tests
vim.opt.runtimepath:append(".")
vim.opt.runtimepath:append("./deps/plenary.nvim")
vim.cmd("runtime plugin/plenary.vim")
EOF

# Install the hooks
bash .hooks-util/install.sh

# Try to commit with issues
echo "Attempting to commit with issues (this should trigger hooks):"
if git commit -m "Add command registration"; then
  echo "FAIL: Commit succeeded but should have failed due to issues"
  exit 1
else
  echo "PASS: Commit correctly failed due to hooks"
fi

# Fix the issues manually for testing
cat > lua/test-plugin/commands.lua << 'EOF'
-- Plugin commands
local M = {}

function M.register_commands()
  local namespace = "test-plugin"
  local commands = {
    TestCommand = function()
      local _result = "test"
      print("Running test command")
    end,
  }

  for command_name, command_fn in pairs(commands) do
    vim.api.nvim_create_user_command(command_name, command_fn, {})
  end
end

return M
EOF

git add lua/test-plugin/commands.lua

# Create a test file
mkdir -p tests/spec
cat > tests/spec/commands_spec.lua << 'EOF'
describe("commands", function()
  it("registers commands properly", function()
    local commands = require("test-plugin.commands")
    commands.register_commands()
    -- This would normally have assertions
    assert(true)
  end)
end)
EOF

git add tests/spec/commands_spec.lua

# Try to commit again
echo "Attempting to commit with fixed issues:"
if git commit -m "Add command registration"; then
  echo "PASS: Commit succeeded after fixing issues"
else
  echo "FAIL: Commit failed even after fixing issues"
  exit 1
fi

echo "All tests passed!"
exit 0