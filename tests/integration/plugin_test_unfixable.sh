#!/bin/bash
# Neovim plugin integration test for hooks-util (Failure Path)
# Tests the scenario where hooks detect issues that cannot be fixed automatically
set -e

# Determine script and project directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEST_DIR=$(mktemp -d)

cleanup() {
  if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
    echo "Cleaned up test directory: $TEST_DIR"
  fi
}

# Clean up at the end or on error
trap 'cleanup' EXIT

echo "=== hooks-util Neovim Plugin Unfixable Issues Test ==="
echo "Creating test Neovim plugin in $TEST_DIR"

# Set up test repository mimicking a Neovim plugin
mkdir -p "$TEST_DIR"
pushd "$TEST_DIR" > /dev/null || exit 1
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

# Create a file with UNFIXABLE issues (syntax errors, etc.)
cat > lua/test-plugin/commands.lua << 'EOF'
-- Plugin commands with severe issues
local M = {}    

function M.register_commands()
    local namespace = "test-plugin"  -- unused variable
    local commands = {
        TestCommand = function()
            local result = "test"  -- unused variable
            print("Running test command")    
        end,
    }
    
    for command_name, command_fn in pairs(commands) do
        vim.api.nvim_create_user_command(command_name, command_fn, {})
    end
end

-- Invalid Lua syntax - unfixable by automatic tools
if (true) {
   print("This is not valid Lua syntax - tools cannot auto-fix this")
}

return M
EOF

# Create scripts directory with a script that has unfixable issues
mkdir -p scripts

cat > scripts/test-script.sh << 'EOF'
#!/bin/bash
# This script has unfixable ShellCheck issues

# Intentional complex nested issue that can't be auto-fixed
for f in $(ls *.{sh,bash} 2>/dev/null); do
  while read line; do
    eval $line 2>/dev/null  # Dangerous eval with no quotes - intentionally bad
  done < "$f"
done

# Missing EOF (unbalanced heredoc) - unfixable by tools
cat << 'DELIM'
This heredoc is not terminated properly
EOF
chmod +x scripts/test-script.sh

# Add the files to Git
git add lua/test-plugin/commands.lua scripts/test-script.sh

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

# Set up the hooks directory structure
echo "Setting up hooks environment..."
mkdir -p .githooks/lib/

# Copy the pre-commit hook
cp .hooks-util/hooks/pre-commit .githooks/pre-commit
chmod +x .githooks/pre-commit

# Copy the actual library files
cp -r .hooks-util/lib/* .githooks/lib/

# Create proper lib directory structure
mkdir -p "${PWD}/.githooks/../lib"
cp -r "${PWD}/.hooks-util/lib/"* "${PWD}/.githooks/../lib/"

# Configure git to use our hooks directory
git config core.hooksPath .githooks

# Verify hook installation
echo "Verifying hooks installation..."
ls -la .githooks/
echo "Git hooks path: $(git config core.hooksPath)"

# Test the hook directly (it should fail with syntax errors)
echo "Testing pre-commit hook directly with unfixable issues:"
if bash .githooks/pre-commit; then
  echo "FAIL: Pre-commit hook should fail with unfixable issues but succeeded"
  exit 1
else
  echo "PASS: Pre-commit hook correctly failed with unfixable issues"
fi

# Try to commit with unfixable issues (should fail)
echo "Attempting to commit with unfixable issues (this should fail):"
if git commit -m "Add commands with unfixable issues" 2>&1; then
  echo "FAIL: Commit succeeded but should have failed due to unfixable issues"
  exit 1
else
  echo "PASS: Commit correctly failed due to unfixable issues"
fi

# Try 5 fix attempts (these should all fail)
MAX_ATTEMPTS=5
echo "Starting iterative fix process (max $MAX_ATTEMPTS attempts)"

for attempt in $(seq 1 $MAX_ATTEMPTS); do
  echo "Fix attempt $attempt of $MAX_ATTEMPTS"
  
  # Try different automatic fix approaches
  if [ $attempt -eq 1 ]; then
    echo "Attempting first round of fixes..."
    # Try to fix formatting issues with StyLua
    if command -v stylua &> /dev/null; then
      find lua -name "*.lua" -exec stylua {} \; 2>/dev/null || true
    fi
  elif [ $attempt -eq 2 ]; then
    echo "Attempting second round of fixes..."
    # Try to comment out problematic sections
    sed -i 's/if (true) {/-- if (true) {/' lua/test-plugin/commands.lua 2>/dev/null || true
    sed -i 's/   print(/   -- print(/' lua/test-plugin/commands.lua 2>/dev/null || true
    sed -i 's/}/-- }/' lua/test-plugin/commands.lua 2>/dev/null || true
  elif [ $attempt -eq 3 ]; then
    echo "Attempting third round of fixes..."
    # Try to fix shell script
    sed -i 's/eval $line/eval "$line"/' scripts/test-script.sh 2>/dev/null || true
    echo "DELIM" >> scripts/test-script.sh 2>/dev/null || true
  elif [ $attempt -eq 4 ]; then
    echo "Attempting drastic measures..."
    # Remove syntax error lines completely
    grep -v "{" lua/test-plugin/commands.lua > lua/test-plugin/commands.lua.tmp 2>/dev/null || true
    grep -v "}" lua/test-plugin/commands.lua.tmp > lua/test-plugin/commands.lua 2>/dev/null || true
    rm lua/test-plugin/commands.lua.tmp 2>/dev/null || true
  elif [ $attempt -eq 5 ]; then
    echo "Final attempt - trying to completely rewrite the file..."
    # Try to completely replace the file with a valid one
    cat > lua/test-plugin/commands.lua << 'EOF'
-- Plugin commands
local M = {}

function M.register_commands()
  local commands = {
    TestCommand = function()
      print("Running test command")
    end,
  }

  for command_name, command_fn in pairs(commands) do
    vim.api.nvim_create_user_command(command_name, command_fn, {})
  end
end

return M
EOF
    # Fix shell script
    cat > scripts/test-script.sh << 'EOF'
#!/bin/bash
# This script is fixed for ShellCheck
echo "Fixed script"
EOF
    chmod +x scripts/test-script.sh
  fi
  
  # Add the files
  git add lua/test-plugin/commands.lua scripts/test-script.sh
  
  # Try to commit, should still fail due to unfixable issues or syntax errors
  if git commit -m "Fix attempts for unfixable issues (attempt $attempt)" 2>&1; then
    if [ $attempt -eq 5 ]; then
      echo "PASS: Final attempt succeeded by completely rewriting the files (acceptable)"
      break
    else
      echo "UNEXPECTED SUCCESS: Commit should have failed on attempt $attempt"
      git show -p
      echo "This indicates a possible issue with the pre-commit hook validation"
      exit 1
    fi
  else
    echo "PASS: Commit correctly failed on attempt $attempt (as expected with unfixable issues)"
  fi
done

# This test is specifically checking that commits with unfixable issues fail
echo "Test completed successfully - unfixable issues were properly detected and blocked"
popd > /dev/null || true
exit 0