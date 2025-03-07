#!/bin/bash
# Comprehensive test for all format validators

set -eo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_UTIL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Set verbose debugging
export HOOKS_VERBOSITY=2

echo "============ ALL FORMAT TESTS ============"
echo "Hooks-Util Root: ${HOOKS_UTIL_ROOT}"
echo "Current Directory: $(pwd)"

# Source all libraries
source "${HOOKS_UTIL_ROOT}/lib/common.sh"
source "${HOOKS_UTIL_ROOT}/lib/error.sh"
source "${HOOKS_UTIL_ROOT}/lib/path.sh"
source "${HOOKS_UTIL_ROOT}/lib/markdown.sh"
source "${HOOKS_UTIL_ROOT}/lib/yaml.sh"
source "${HOOKS_UTIL_ROOT}/lib/json.sh"
source "${HOOKS_UTIL_ROOT}/lib/toml.sh"

# Create temp test directory
TEST_DIR="${HOOKS_UTIL_ROOT}/tests/temp-all-formats"
mkdir -p "${TEST_DIR}"

# Set TARGET_DIR
TARGET_DIR="${HOOKS_UTIL_ROOT}"
export TARGET_DIR
echo "TARGET_DIR: ${TARGET_DIR}"

# Initialize a git repo
if [ ! -d "${TEST_DIR}/.git" ]; then
  echo "Initializing git repository in ${TEST_DIR}..."
  git -C "${TEST_DIR}" init >/dev/null 2>&1
fi

# Test each format
function test_format() {
  local format=$1
  local file=$2
  local content=$3
  local lint_function=$4
  
  echo "===== Testing ${format} format ====="
  
  # Create test file
  echo "Creating ${format} test file: ${file}"
  echo "${content}" > "${file}"
  
  # Stage the file
  git -C "${TEST_DIR}" add "${file}" >/dev/null 2>&1
  
  # Test linting
  echo "Testing ${format} linting..."
  $lint_function "${file}"
  local lint_result=$?
  
  if [ $lint_result -eq 0 ]; then
    echo "✅ ${format} linting passed"
  else
    echo "❌ ${format} linting failed with exit code: ${lint_result}"
  fi
  
  echo ""
}

# Test Markdown
MARKDOWN_CONTENT="# Test Markdown File

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
  return \"hello world\"
end
\`\`\`"

test_format "Markdown" "${TEST_DIR}/test.md" "${MARKDOWN_CONTENT}" "hooks_markdown_lint"

# Test YAML
YAML_CONTENT="# Test YAML file
name: Test Project
version: 1.0.0
author: Claude
description: A test project
dependencies:
  - name: dep1
    version: 1.0.0
  - name: dep2
    version: 2.0.0"

test_format "YAML" "${TEST_DIR}/test.yaml" "${YAML_CONTENT}" "hooks_yaml_lint"

# Test JSON
JSON_CONTENT='{
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
}'

test_format "JSON" "${TEST_DIR}/test.json" "${JSON_CONTENT}" "hooks_json_lint"

# Test TOML
TOML_CONTENT='# This is a TOML document

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
  role = "backend"'

test_format "TOML" "${TEST_DIR}/test.toml" "${TOML_CONTENT}" "hooks_toml_lint"

# Test staged file detection
echo "Testing staged file detection..."
cd "${TEST_DIR}"

# Get staged files of each type
MD_FILES=$(hooks_get_staged_markdown_files)
YAML_FILES=$(hooks_get_staged_yaml_files)
JSON_FILES=$(hooks_get_staged_json_files)
TOML_FILES=$(hooks_get_staged_toml_files)

# Print results
echo "Staged Markdown files: ${MD_FILES}"
echo "Staged YAML files: ${YAML_FILES}"
echo "Staged JSON files: ${JSON_FILES}"
echo "Staged TOML files: ${TOML_FILES}"

# Test hooks functions
echo ""
echo "Testing hooks_markdown_staged..."
hooks_markdown_staged
echo ""
echo "Testing hooks_yaml_staged..."
hooks_yaml_staged
echo ""
echo "Testing hooks_json_staged..."
hooks_json_staged
echo ""
echo "Testing hooks_toml_staged..."
hooks_toml_staged

# Return to original directory
cd "${HOOKS_UTIL_ROOT}"

echo "============ TESTS COMPLETE ============"

# Clean up test files
echo "Cleaning up test files..."
rm -rf "${TEST_DIR}"