#!/bin/bash
# Basic functionality test for hooks-util
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

echo "=== hooks-util Basic Functionality Test ==="
echo "Creating test Git repository in $TEST_DIR"

# Set up test repository
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
git init
git config user.name "Test User"
git config user.email "test@example.com"

# Create a sample file and commit it
echo "console.log('hello');" > test.js
git add test.js
git commit -m "Initial commit"

# Create a test Lua file with issues
cat > test.lua << 'EOF'
local function test_function()
    local unused_var = "test"  -- Unused variable
    print("Hello with trailing whitespace")    
    return true
end

local test_result = test_function()
print(test_result)
EOF

# Create a test shell script with issues
cat > test.sh << 'EOF'
#!/bin/bash
# Test shell script with issues

# Missing quotes around variables
MYVAR=test
echo $MYVAR

# Using deprecated backticks
OUTPUT=`ls -la`

# Using = instead of == in test
if [ $MYVAR = "test" ]; then
    echo "Variable is test"
fi
EOF

# Add the files to Git
git add test.lua test.sh

# Set up hooks-util
echo "Setting up hooks-util"
mkdir -p .hooks-util
cp -r "$PROJECT_DIR/"* .hooks-util/

# Create a minimal config
cat > .hooksrc << 'EOF'
HOOKS_STYLUA_ENABLED=true
HOOKS_LUACHECK_ENABLED=true
HOOKS_TESTS_ENABLED=false
HOOKS_QUALITY_ENABLED=true
HOOKS_VERBOSITY=2
EOF

# Install the hooks
bash .hooks-util/install.sh

# Try to commit with issues
echo "Attempting to commit with issues (this should trigger hooks):"
if git commit -m "Test commit with hooks"; then
  echo "FAIL: Commit succeeded but should have failed due to issues"
  exit 1
else
  echo "PASS: Commit correctly failed due to hooks"
fi

# Fix the issues manually for testing
cat > test.lua << 'EOF'
local function test_function()
  local _unused_var = "test"  -- Unused variable prefixed with _
  print("Hello without trailing whitespace")
  return true
end

local test_result = test_function()
print(test_result)
EOF

# Fix the shell script issues
cat > test.sh << 'EOF'
#!/bin/bash
# Test shell script with fixed issues

# Properly quoted variables
MYVAR="test"
echo "$MYVAR"

# Using $() instead of backticks
OUTPUT="$(ls -la)"

# Using == in test (or keep = for POSIX compatibility)
if [ "$MYVAR" == "test" ]; then
    echo "Variable is test"
fi
EOF

git add test.lua test.sh

# Try to commit again
echo "Attempting to commit with fixed issues:"
if git commit -m "Test commit with fixed issues"; then
  echo "PASS: Commit succeeded after fixing issues"
else
  echo "FAIL: Commit failed even after fixing issues"
  exit 1
fi

echo "All tests passed!"
exit 0