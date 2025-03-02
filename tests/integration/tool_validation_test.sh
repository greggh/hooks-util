#!/bin/bash
# Test to verify tool validation failures
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
    exit $exit_code
  fi
  
  # Ensure we return success
  exit 0
}

trap success_cleanup EXIT

echo "=== hooks-util Tool Validation Test ==="
echo "Creating test Git repository in $TEST_DIR"

# Set up test repository
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
git init
git config user.name "Test User"
git config user.email "test@example.com"

# Create some initial files
cat > test.lua << 'EOF'
local test = "hello"
print(test)
EOF

# Commit initial files
git add test.lua
git commit -m "Initial commit"

# Set up hooks-util
echo "Setting up hooks-util..."
mkdir -p .hooks-util
cp -r "$PROJECT_DIR/"* .hooks-util/

# Create a clean hooks directory with just the pre-commit hook
# but no other tools are installed
mkdir -p .githooks/lib/
cp "$PROJECT_DIR/hooks/pre-commit" .githooks/pre-commit
chmod +x .githooks/pre-commit
cp -r "$PROJECT_DIR/lib/"*.sh .githooks/lib/

# Configure git to use our hooks directory
git config core.hooksPath .githooks

# Create a function to simulate missing commands
cat > .githooks/lib/command_mock.sh << 'EOF'
#!/bin/bash

# Override hooks_command_exists to simulate missing tools
hooks_command_exists() {
  local cmd="$1"
  if [ "$cmd" = "stylua" ] || [ "$cmd" = "shellcheck" ]; then
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
echo "function badFormat() { return 'not formatted' }" >> test.lua
git add test.lua

# Try to commit with missing tools - this should fail
echo "Attempting to commit with missing tools (should fail):"
if git commit -m "This should fail"; then
  echo "FAIL: Commit succeeded but should have failed due to missing tools"
  exit 1
else
  echo "PASS: Commit correctly failed due to missing tools"
  EXPECTED_FAIL=true
  
  # Unset the special git hooks path before exiting to prevent errors
  git config --unset core.hooksPath || true
fi

echo "Tool validation test passed!"