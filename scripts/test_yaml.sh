#!/bin/bash
# Test script for YAML validation

set -eo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_UTIL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Set verbose debugging
export HOOKS_VERBOSITY=2

echo "========== YAML VALIDATION TEST =========="
echo "Hooks-Util Root: ${HOOKS_UTIL_ROOT}"
echo "Current Directory: $(pwd)"

# Source the yaml library
source "${HOOKS_UTIL_ROOT}/lib/common.sh"
source "${HOOKS_UTIL_ROOT}/lib/error.sh"
source "${HOOKS_UTIL_ROOT}/lib/path.sh"
source "${HOOKS_UTIL_ROOT}/lib/yaml.sh"

# Create a test YAML file
TEST_DIR="${HOOKS_UTIL_ROOT}/tests/temp"
mkdir -p "${TEST_DIR}"
TEST_YAML="${TEST_DIR}/test.yaml"

echo "Creating test YAML file: ${TEST_YAML}"
cat > "${TEST_YAML}" << EOF
# Test YAML file
name: Test Project
version: 1.0.0
author: Claude
description: A test project
dependencies:
  - name: dep1
    version: 1.0.0
  - name: dep2
    version: 2.0.0
EOF

# Set TARGET_DIR to the hooks-util root
TARGET_DIR="${HOOKS_UTIL_ROOT}"
export TARGET_DIR
echo "TARGET_DIR: ${TARGET_DIR}"

# Check if yamllint config exists
if [ -f "${TARGET_DIR}/.yamllint.yml" ]; then
  echo "✅ .yamllint.yml exists at ${TARGET_DIR}/.yamllint.yml"
else
  echo "❌ .yamllint.yml does not exist at ${TARGET_DIR}/.yamllint.yml"
  
  echo "Checking templates directory..."
  if [ -f "${HOOKS_UTIL_ROOT}/templates/.yamllint.yml" ]; then
    echo "✅ .yamllint.yml exists in templates directory"
    echo "Copying template to target directory..."
    cp "${HOOKS_UTIL_ROOT}/templates/.yamllint.yml" "${TARGET_DIR}/.yamllint.yml"
  else
    echo "❌ .yamllint.yml does not exist in templates directory"
    
    # Create a basic yamllint config
    echo "Creating basic .yamllint.yml file..."
    cat > "${TARGET_DIR}/.yamllint.yml" << EOF
---
extends: default
rules:
  line-length:
    max: 120
    level: warning
  document-start:
    level: warning
  trailing-spaces:
    level: warning
EOF
  fi
fi

# Test YAML linting
echo "Testing YAML linting..."
hooks_yaml_lint "${TEST_YAML}"
lint_result=$?

if [ $lint_result -eq 0 ]; then
  echo "✅ YAML linting passed"
else
  echo "❌ YAML linting failed with exit code: ${lint_result}"
fi

# Test staged file function (by simulating a staged file)
echo "Testing staged files function..."

# Create a git repo in temp directory if it doesn't exist
if [ ! -d "${TEST_DIR}/.git" ]; then
  echo "Initializing git repository in ${TEST_DIR}..."
  git -C "${TEST_DIR}" init >/dev/null 2>&1
fi

# Add the test file and stage it
git -C "${TEST_DIR}" add "${TEST_YAML}" >/dev/null 2>&1

# Save current directory
CURRENT_DIR=$(pwd)

# Change to the test directory to run hooks_get_staged_yaml_files
cd "${TEST_DIR}"

# Run the function to get staged YAML files
staged_files=$(hooks_get_staged_yaml_files)
echo "Staged YAML files: ${staged_files}"

# Return to original directory
cd "${CURRENT_DIR}"

echo "========== TEST COMPLETE =========="

# Clean up test files
echo "Cleaning up test files..."
rm -rf "${TEST_DIR}"