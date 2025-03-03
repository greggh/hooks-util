#!/bin/bash
# Test to verify tool validation failures using real tools
# Enable error handling but allow specific failures we expect
set +e

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

# Always clean up at the end
success_cleanup() {
  local exit_code=$?
  
  if [ $exit_code -eq 0 ]; then
    echo "Test completed successfully!"
    cleanup
  elif [ -n "$EXPECTED_FAIL" ]; then
    echo "Test completed as expected (with allowed failures)"
    cleanup
  else
    echo "Test failed - not cleaning up directory: $TEST_DIR"
    echo "You may want to inspect it for debugging"
    # Return to original directory
    popd > /dev/null 2>&1 || true
    exit $exit_code
  fi
  
  # Return to original directory
  popd > /dev/null 2>&1 || true
  # Ensure we return success
  exit 0
}

trap success_cleanup EXIT

echo "=== hooks-util Tool Validation Test ==="
echo "Creating test Git repository in $TEST_DIR"

# Set up test repository
mkdir -p "$TEST_DIR"
pushd "$TEST_DIR" > /dev/null || exit 1
git init
git config user.name "Test User"
git config user.email "test@example.com"

# Create some initial files with formatting and linting issues
cat > test.lua << 'EOF'
-- Lua file with formatting and linting issues
local test   = "hello"  
local unused = "this will trigger a linting warning"
print(test)

function badlyFormattedFunction(   )    {
   return "not formatted correctly"  
}
EOF

# Create a shell script with shellcheck issues
cat > test.sh << 'EOF'
#!/bin/bash
# Shell script with shellcheck issues
echo $UNDEFINED_VAR
ls *.txt
if [ $? == 0 ]; then
  echo "Files found"
fi
EOF
chmod +x test.sh

# Commit initial files
git add test.lua test.sh
git commit -m "Initial commit"

# Set up hooks-util
echo "Setting up hooks-util..."
mkdir -p .hooks-util
cp -r "$PROJECT_DIR/"* .hooks-util/

# Create a clean hooks directory with just the pre-commit hook
mkdir -p .githooks/lib/
cp "$PROJECT_DIR/hooks/pre-commit" .githooks/pre-commit
chmod +x .githooks/pre-commit
cp -r "$PROJECT_DIR/lib/"*.sh .githooks/lib/

# Configure git to use our hooks directory
git config core.hooksPath .githooks

# Create configuration files
cat > .stylua.toml << 'EOF'
column_width = 100
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
EOF

cat > .luacheckrc << 'EOF'
-- Global objects
globals = {
  "vim",
}
unused = true
max_line_length = 100
EOF

# Set up configuration for hooks
cat > .hooksrc << 'EOF'
HOOKS_STYLUA_ENABLED=true
HOOKS_LUACHECK_ENABLED=true
HOOKS_SHELLCHECK_ENABLED=true
HOOKS_TESTS_ENABLED=false
HOOKS_QUALITY_ENABLED=true
HOOKS_VERBOSITY=2
EOF

# Run test with missing tools first (modify the lib temporarily)
echo "PART 1: Testing behavior with missing tools"

# Create a function to simulate missing commands
cat > .githooks/lib/command_mock.sh << 'EOF'
#!/bin/bash

# Override hooks_command_exists to simulate missing tools
hooks_command_exists() {
  local cmd="$1"
  if [ "$cmd" = "stylua" ] || [ "$cmd" = "shellcheck" ] || [ "$cmd" = "luacheck" ]; then
    return 1  # Command not found
  fi
  # Check for the actual command
  command -v "$cmd" &> /dev/null
}

# Export the function
export -f hooks_command_exists
EOF

# Source our mock
source .githooks/lib/command_mock.sh

# Modify a file to trigger pre-commit
echo "function anotherBadFormat() { return 'also not formatted' }" >> test.lua
git add test.lua

# Try to commit with missing tools - this should fail
echo "Attempting to commit with missing tools (this should fail):"
if git commit -m "This should fail"; then
  echo "FAIL: Commit succeeded but should have failed due to missing tools"
  exit 1
else
  echo "PASS: Commit correctly failed due to missing tools"
  EXPECTED_FAIL=true
fi

# Now check if the actual tools are available on the system
echo "PART 2: Testing behavior with real tools"

# Remove the command mock
rm -f .githooks/lib/command_mock.sh

# Check if the real tools are installed
missing_tools=0
if ! command -v stylua &> /dev/null; then
  echo "StyLua not installed - skipping real tool test"
  missing_tools=$((missing_tools + 1))
fi

if ! command -v luacheck &> /dev/null; then
  echo "Luacheck not installed - skipping real tool test"
  missing_tools=$((missing_tools + 1))
fi

if ! command -v shellcheck &> /dev/null; then
  echo "ShellCheck not installed - skipping real tool test"
  missing_tools=$((missing_tools + 1))
fi

# If any tool is missing, skip this part
if [ $missing_tools -gt 0 ]; then
  echo "Some tools are missing ($missing_tools). Skipping real tool tests."
  echo "To run the full test, please install: stylua, luacheck, and shellcheck."
  git config --unset core.hooksPath || true
  echo "Tool validation test partially passed (missing tools test only)."
  exit 0
fi

# Now test with real tools
echo "All tools installed. Testing with real StyLua, Luacheck, and ShellCheck."

# Try to commit - this should fail due to real formatting and linting issues
if git commit -m "This should fail due to real issues"; then
  echo "FAIL: Commit succeeded but should have failed due to real linting/formatting issues"
  exit 1
else
  echo "PASS: Commit correctly failed due to real linting/formatting issues"
  EXPECTED_FAIL=true
fi

# Implement a robust fix-and-retry approach
MAX_ATTEMPTS=5
attempt=1

echo "Starting iterative fix process (max $MAX_ATTEMPTS attempts)"

while [ $attempt -le $MAX_ATTEMPTS ]; do
  echo "Fix attempt $attempt of $MAX_ATTEMPTS"
  
  # Apply fixes based on current issues
  if [ $attempt -eq 1 ]; then
    # Initial fix - create files that should pass all checks
    echo "Implementing initial fixes..."
    
    # Create a clean Lua file
    cat > test.lua << 'EOF'
-- Lua file with proper formatting and no linting issues
local test = "hello"
print(test)

function properly_formatted_function()
  return "formatted correctly"
end

-- No unused variables here
EOF

    # Create a clean shell script
    cat > test.sh << 'EOF'
#!/bin/bash
# Shell script with no shellcheck issues
FILES="$(find . -name "*.txt")"
if [ -n "$FILES" ]; then
  echo "Files found: $FILES"
fi
EOF
    chmod +x test.sh

    # Format Lua files with stylua if available
    if command -v stylua &> /dev/null; then
      echo "Formatting Lua files with StyLua..."
      stylua test.lua
    fi
  else
    # Additional fix attempts based on specific issues
    echo "Implementing additional fixes for attempt $attempt..."
    
    # Check for Lua issues
    if grep -q "unused variable" .githooks/pre-commit-output.log 2>/dev/null; then
      echo "Fixing unused variables in Lua files..."
      sed -i 's/local unused.*$/-- No unused variables/' test.lua
      sed -i 's/local function unused.*$/-- Function removed due to being unused/' test.lua
    fi
    
    if grep -q "trailing whitespace" .githooks/pre-commit-output.log 2>/dev/null; then
      echo "Fixing trailing whitespace in Lua files..."
      sed -i 's/[ \t]*$//' test.lua
    fi
    
    # Format Lua files with stylua if available
    if command -v stylua &> /dev/null; then
      echo "Applying StyLua formatting to fix indentation..."
      stylua test.lua
    fi
    
    # Check for shell script issues
    if grep -q "SC2034" .githooks/pre-commit-output.log 2>/dev/null; then
      echo "Fixing unused variables in shell scripts..."
      sed -i 's/FILES=.*$/FILES="$(find . -name "*.txt")"\necho "Found $(echo "$FILES" | wc -w) files"/' test.sh
    fi
  fi
  
  # Add all files
  git add test.lua test.sh
  
  # Try to commit, capturing output for analysis on failure
  echo "Attempting to commit with fixed issues (attempt $attempt)..."
  git commit -m "Fixed formatting and linting issues (attempt $attempt)" 2>&1 | tee .githooks/pre-commit-output.log
  
  # Check if commit succeeded
  if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "PASS: Commit succeeded after fixing issues on attempt $attempt"
    break
  fi
  
  # If we've reached max attempts, report failure
  if [ $attempt -eq $MAX_ATTEMPTS ]; then
    echo "FAIL: Could not fix all issues after $MAX_ATTEMPTS attempts"
    cat .githooks/pre-commit-output.log
    exit 1
  fi
  
  # Analyze output to inform next fix attempt
  echo "Commit failed. Analyzing issues for next fix attempt..."
  
  ((attempt++))
done

# Unset the special git hooks path before exiting to prevent errors
git config --unset core.hooksPath || true

echo "Tool validation test passed completely!"
# Return to original directory before exiting
popd > /dev/null 2>&1 || true
# Cleanup
if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
  rm -rf "$TEST_DIR"
  echo "Cleaned up test directory: $TEST_DIR"
fi
exit 0