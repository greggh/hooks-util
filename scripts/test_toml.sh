#!/bin/bash
# Test script for TOML validation

set -eo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_UTIL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Set verbose debugging
export HOOKS_VERBOSITY=2

echo "========== TOML VALIDATION TEST =========="
echo "Hooks-Util Root: ${HOOKS_UTIL_ROOT}"
echo "Current Directory: $(pwd)"

# Source the toml library
source "${HOOKS_UTIL_ROOT}/lib/common.sh"
source "${HOOKS_UTIL_ROOT}/lib/error.sh"
source "${HOOKS_UTIL_ROOT}/lib/path.sh"
source "${HOOKS_UTIL_ROOT}/lib/toml.sh"

# Create a test TOML file
TEST_DIR="${HOOKS_UTIL_ROOT}/tests/temp"
mkdir -p "${TEST_DIR}"
TEST_TOML="${TEST_DIR}/test.toml"

echo "Creating test TOML file: ${TEST_TOML}"
cat > "${TEST_TOML}" << EOF
# This is a TOML document

title = "TOML Example"

[owner]
name = "Claude"
bio = """
AI assistant
Created by Anthropic
"""

[database]
server = "192.168.1.1"
ports = [ 8000, 8001, 8002 ]
connection_max = 5000
enabled = true

[servers]

  [servers.alpha]
  ip = "10.0.0.1"
  role = "frontend"

  [servers.beta]
  ip = "10.0.0.2"
  role = "backend"
EOF

# Set TARGET_DIR to the hooks-util root
TARGET_DIR="${HOOKS_UTIL_ROOT}"
export TARGET_DIR
echo "TARGET_DIR: ${TARGET_DIR}"

# Test TOML linting
echo "Testing TOML linting..."
hooks_toml_lint "${TEST_TOML}"
lint_result=$?

if [ $lint_result -eq 0 ]; then
  echo "✅ TOML linting passed"
else
  echo "❌ TOML linting failed with exit code: ${lint_result}"
fi

# Test staged file function (by simulating a staged file)
echo "Testing staged files function..."

# Create a git repo in temp directory if it doesn't exist
if [ ! -d "${TEST_DIR}/.git" ]; then
  echo "Initializing git repository in ${TEST_DIR}..."
  git -C "${TEST_DIR}" init >/dev/null 2>&1
fi

# Add the test file and stage it
git -C "${TEST_DIR}" add "${TEST_TOML}" >/dev/null 2>&1

# Save current directory
CURRENT_DIR=$(pwd)

# Change to the test directory to run hooks_get_staged_toml_files
cd "${TEST_DIR}"

# Run the function to get staged TOML files
staged_files=$(hooks_get_staged_toml_files)
echo "Staged TOML files: ${staged_files}"

# Return to original directory
cd "${CURRENT_DIR}"

echo "========== TEST COMPLETE =========="

# Clean up test files
echo "Cleaning up test files..."
rm -rf "${TEST_DIR}"