#!/bin/bash
# Test for common.sh functions

# Define test functions directly in case test_utils.sh isn't properly loaded
assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-Expected '$expected' but got '$actual'}"
  
  if [ "$expected" != "$actual" ]; then
    echo -e "\033[0;31mAssertion failed: $message\033[0m"
    return 1
  fi
  return 0
}

assert_output_contains() {
  local needle="$1"
  local command="$2"
  local message="${3:-Expected output to contain '$needle'}"
  
  local output=$(eval "$command")
  
  if [[ "$output" != *"$needle"* ]]; then
    echo -e "\033[0;31mAssertion failed: $message\033[0m"
    echo -e "Output was: $output"
    return 1
  fi
  return 0
}

# Source the required script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
LIB_DIR="${PROJECT_DIR}/lib"

# Source version.sh first
source "${LIB_DIR}/version.sh"

# Then source common.sh
source "${LIB_DIR}/common.sh"

# Test hooks_command_exists
echo "Testing hooks_command_exists..."
assert_equals 0 $(hooks_command_exists "bash" && echo 0 || echo 1) "bash command should exist"
assert_equals 1 $(hooks_command_exists "non_existent_command_xyz" && echo 0 || echo 1) "non-existent command should not exist"

# Test hooks_is_lua_file
echo "Testing hooks_is_lua_file..."
assert_equals 0 $(hooks_is_lua_file "file.lua" && echo 0 || echo 1) "file.lua should be recognized as Lua file"
assert_equals 1 $(hooks_is_lua_file "file.txt" && echo 0 || echo 1) "file.txt should not be recognized as Lua file"

# Test output functions (basic smoke test)
echo "Testing output functions..."
hooks_set_verbosity 0  # Set to quiet
output=$(hooks_message "This should not be printed" 2>&1)
assert_equals "" "$output" "No output should be produced in quiet mode"

hooks_set_verbosity 2  # Set to verbose
output=$(hooks_debug "Debug message" 2>&1)
assert_output_contains "Debug" "echo \"$output\"" "Debug message should be printed in verbose mode"

# All tests passed
echo "All tests passed!"
exit 0
