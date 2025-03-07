#!/bin/bash
# Test script for JSON validation

set -eo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_UTIL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Set verbose debugging
export HOOKS_VERBOSITY=2

echo "========== JSON VALIDATION TEST =========="
echo "Hooks-Util Root: ${HOOKS_UTIL_ROOT}"
echo "Current Directory: $(pwd)"

# Source the json library
source "${HOOKS_UTIL_ROOT}/lib/common.sh"
source "${HOOKS_UTIL_ROOT}/lib/error.sh"
source "${HOOKS_UTIL_ROOT}/lib/path.sh"
source "${HOOKS_UTIL_ROOT}/lib/json.sh"

# Create a test JSON file
TEST_DIR="${HOOKS_UTIL_ROOT}/tests/temp"
mkdir -p "${TEST_DIR}"
TEST_JSON="${TEST_DIR}/test.json"

echo "Creating test JSON file: ${TEST_JSON}"
cat > "${TEST_JSON}" << EOF
{
  "name": "hooks-util",
  "version": "0.6.0",
  "description": "Git hooks framework for Neovim ecosystem projects",
  "repository": {
    "type": "git",
    "url": "https://github.com/greggh/hooks-util"
  },
  "author": "Gregg",
  "license": "MIT",
  "dependencies": {
    "lust-next": "^0.7.0"
  },
  "engines": {
    "neovim": ">=0.7.0"
  }
}
EOF

# Set TARGET_DIR to the hooks-util root
TARGET_DIR="${HOOKS_UTIL_ROOT}"
export TARGET_DIR
echo "TARGET_DIR: ${TARGET_DIR}"

# Test JSON linting
echo "Testing JSON linting..."
hooks_json_lint "${TEST_JSON}"
lint_result=$?

if [ $lint_result -eq 0 ]; then
  echo "✅ JSON linting passed"
else
  echo "❌ JSON linting failed with exit code: ${lint_result}"
fi

# Test staged file function (by simulating a staged file)
echo "Testing staged files function..."

# Create a git repo in temp directory if it doesn't exist
if [ ! -d "${TEST_DIR}/.git" ]; then
  echo "Initializing git repository in ${TEST_DIR}..."
  git -C "${TEST_DIR}" init >/dev/null 2>&1
fi

# Add the test file and stage it
git -C "${TEST_DIR}" add "${TEST_JSON}" >/dev/null 2>&1

# Save current directory
CURRENT_DIR=$(pwd)

# Change to the test directory to run hooks_get_staged_json_files
cd "${TEST_DIR}"

# Run the function to get staged JSON files
staged_files=$(hooks_get_staged_json_files)
echo "Staged JSON files: ${staged_files}"

# Return to original directory
cd "${CURRENT_DIR}"

echo "========== TEST COMPLETE =========="

# Clean up test files
echo "Cleaning up test files..."
rm -rf "${TEST_DIR}"