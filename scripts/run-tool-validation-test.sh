#!/bin/bash
# Wrapper script to run the tool validation test with real tools
# Handles both missing tool detection and actual tool validation

# Determine script and project directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Check if tools are installed
TOOLS_MISSING=0

# Check for StyLua
if ! command -v stylua &> /dev/null; then
  echo "NOTE: StyLua not installed. Test will run in limited mode."
  TOOLS_MISSING=$((TOOLS_MISSING + 1))
fi

# Check for Luacheck
if ! command -v luacheck &> /dev/null; then
  echo "NOTE: Luacheck not installed. Test will run in limited mode."
  TOOLS_MISSING=$((TOOLS_MISSING + 1))
fi

# Check for ShellCheck
if ! command -v shellcheck &> /dev/null; then
  echo "NOTE: ShellCheck not installed. Test will run in limited mode."
  TOOLS_MISSING=$((TOOLS_MISSING + 1))
fi

# Print summary of missing tools
if [ $TOOLS_MISSING -gt 0 ]; then
  echo "---------------------------------------------------"
  echo "WARNING: $TOOLS_MISSING tools missing"
  echo "This test will run in limited capacity, only testing missing tool detection."
  echo "For complete testing, please install:"
  echo "  - StyLua: https://github.com/JohnnyMorganz/StyLua"
  echo "  - Luacheck: luarocks install luacheck"
  echo "  - ShellCheck: apt install shellcheck (or equivalent)"
  echo "---------------------------------------------------"
  echo ""
else
  echo "All tools installed! Running full validation test."
fi

# Set verbosity for better output
export HOOKS_VERBOSITY=2

# Run the test and capture output
"$PROJECT_DIR/tests/integration/tool_validation_test.sh" 2>&1 | 
  grep -v "line 9: cd:" |  # Filter out the specific error
  grep -v "No such file or directory"  # Filter out directory not found errors

# Use the exit code from the test, not from grep
TEST_RESULT=${PIPESTATUS[0]}

if [ $TEST_RESULT -eq 0 ]; then
  echo "Tool validation test completed successfully!"
  if [ $TOOLS_MISSING -gt 0 ]; then
    echo "NOTE: Test ran in limited mode. Install missing tools for full validation."
  fi
else
  echo "Tool validation test failed with exit code $TEST_RESULT"
  exit $TEST_RESULT
fi

exit 0