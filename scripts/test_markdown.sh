#!/bin/bash
# Test script for Markdown validation

set -eo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_UTIL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Set verbose debugging
export HOOKS_VERBOSITY=2

echo "========== MARKDOWN VALIDATION TEST =========="
echo "Hooks-Util Root: ${HOOKS_UTIL_ROOT}"
echo "Current Directory: $(pwd)"

# Source the markdown library
source "${HOOKS_UTIL_ROOT}/lib/common.sh"
source "${HOOKS_UTIL_ROOT}/lib/error.sh"
source "${HOOKS_UTIL_ROOT}/lib/path.sh"
source "${HOOKS_UTIL_ROOT}/lib/markdown.sh"

# Create a test Markdown file
TEST_DIR="${HOOKS_UTIL_ROOT}/tests/temp"
mkdir -p "${TEST_DIR}"
TEST_MD="${TEST_DIR}/test.md"

echo "Creating test Markdown file: ${TEST_MD}"
cat > "${TEST_MD}" << EOF
# Test Markdown File

This is a test markdown file for validation.

## Section 1

- Item 1
- Item 2
- Item 3

## Section 2

1. Ordered item 1
1. Ordered item 2
1. Ordered item 3

\`\`\`lua
local function test()
  return "hello world"
end
\`\`\`
EOF

# Test Markdown fixing
echo "Testing Markdown fixing..."
hooks_fix_markdown_file "${TEST_MD}"
fix_result=$?

if [ $fix_result -eq 0 ]; then
  echo "✅ Markdown fixing passed"
else
  echo "❌ Markdown fixing failed with exit code: ${fix_result}"
fi

# Test Markdown linting
echo "Testing Markdown linting..."
hooks_markdown_lint "${TEST_MD}"
lint_result=$?

if [ $lint_result -eq 0 ]; then
  echo "✅ Markdown linting passed"
else
  echo "❌ Markdown linting failed with exit code: ${lint_result}"
fi

# Test staged file function (by simulating a staged file)
echo "Testing staged files function..."

# Create a git repo in temp directory if it doesn't exist
if [ ! -d "${TEST_DIR}/.git" ]; then
  echo "Initializing git repository in ${TEST_DIR}..."
  git -C "${TEST_DIR}" init >/dev/null 2>&1
fi

# Add the test file and stage it
git -C "${TEST_DIR}" add "${TEST_MD}" >/dev/null 2>&1

# Save current directory
CURRENT_DIR=$(pwd)

# Change to the test directory to run hooks_get_staged_markdown_files
cd "${TEST_DIR}"

# Run the function to get staged Markdown files
staged_files=$(hooks_get_staged_markdown_files)
echo "Staged Markdown files: ${staged_files}"

# Return to original directory
cd "${CURRENT_DIR}"

echo "========== TEST COMPLETE =========="

# Clean up test files
echo "Cleaning up test files..."
rm -rf "${TEST_DIR}"