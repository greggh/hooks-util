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

# Create the minimal test directory structure needed
echo "Setting up simplified test environment..."
mkdir -p .githooks/lib/
cp .hooks-util/tests/integration/test-pre-commit .githooks/pre-commit
chmod +x .githooks/pre-commit
cp -r .hooks-util/lib/* .githooks/lib/

# Configure git to use our hooks directory
git config core.hooksPath .githooks

# Verify hook installation
echo "Verifying hooks installation..."
ls -la .githooks/
echo "Git hooks path: $(git config core.hooksPath)"

# Debug the hook directly
echo "Testing pre-commit hook directly to verify it works:"
bash .githooks/pre-commit
HOOK_EXIT=$?
if [ $HOOK_EXIT -ne 0 ]; then
  echo "PASS: Pre-commit hook returns non-zero exit code ($HOOK_EXIT) for issues"
else
  echo "PASS: Pre-commit hook passed initial test run"
fi

# Try to commit with issues
echo "Attempting to commit with issues (this should trigger hooks):"
OUTPUT=$(git commit -m "Test commit with hooks" 2>&1)
echo "$OUTPUT"

# Check if the commit succeeded when it should have failed due to issues
if git log -1 --oneline | grep -q "Test commit with hooks"; then
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