#!/bin/bash
# Unit test runner for hooks-util shell scripts
set -eo pipefail

# We store the original pwd in case we need it for future enhancements
# This value is currently unused but kept for reference
# ORIGINAL_PWD="$PWD"

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEST_DIR="${PROJECT_DIR}/tests"
LIB_DIR="${PROJECT_DIR}/lib"

# Export directories
export SCRIPT_DIR
export PROJECT_DIR
export TEST_DIR
export LIB_DIR

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Create temporary directory for test artifacts
TEST_TMP_DIR=$(mktemp -d)
cleanup() {
  rm -rf "${TEST_TMP_DIR}"
}
trap cleanup EXIT

# Initialize test counts
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Function to run a test
run_test() {
  local test_file="$1"
  local test_name
  test_name=$(basename "$test_file" .sh)
  
  echo -e "${YELLOW}Running test: ${test_name}${NC}"
  ((TESTS_TOTAL++))
  
  # Make sure the test is executable
  chmod +x "$test_file"
  
  # Run the test directly
  "$test_file"
  
  local result=$?
  if [ $result -eq 0 ]; then
    echo -e "${GREEN}✓ ${test_name} passed${NC}"
    ((TESTS_PASSED++))
  elif [ $result -eq 2 ]; then
    echo -e "${YELLOW}⚠ ${test_name} skipped${NC}"
    ((TESTS_SKIPPED++))
  else
    echo -e "${RED}✗ ${test_name} failed${NC}"
    ((TESTS_FAILED++))
  fi
  
  echo ""
}

# Check if test directory exists
if [ ! -d "${TEST_DIR}" ]; then
  echo -e "${YELLOW}Creating test directory: ${TEST_DIR}${NC}"
  mkdir -p "${TEST_DIR}"
fi

# Check if test utilities exist, create if not
if [ ! -f "${TEST_DIR}/test_utils.sh" ]; then
  echo -e "${YELLOW}Creating test utilities: ${TEST_DIR}/test_utils.sh${NC}"
  cat > "${TEST_DIR}/test_utils.sh" << 'EOF'
#!/bin/bash
# Test utilities for hooks-util

# Function to assert that two values are equal
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

# Function to assert that a command exits with a specific code
assert_exit_code() {
  local expected="$1"
  local command="$2"
  local message="${3:-Expected exit code $expected but got $?}"
  
  eval "$command"
  local actual=$?
  
  if [ "$expected" != "$actual" ]; then
    echo -e "\033[0;31mAssertion failed: $message (got code $actual)\033[0m"
    return 1
  fi
  return 0
}

# Function to assert that a command output contains a string
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

# Function to skip a test
skip_test() {
  local reason="${1:-Test skipped (no reason provided)}"
  echo -e "\033[0;33mTest skipped: $reason\033[0m"
  exit 2
}
EOF
fi

# Create an example test if none exist
if [ "$(find "${TEST_DIR}" -name "*_test.sh" | wc -l)" -eq 0 ]; then
  echo -e "${YELLOW}Creating example test: ${TEST_DIR}/common_test.sh${NC}"
  cat > "${TEST_DIR}/common_test.sh" << 'EOF'
#!/bin/bash
# Test for common.sh functions

# Source the module to test
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
exit 0
EOF
fi

# Find and run all tests
echo -e "${YELLOW}Running hooks-util tests${NC}"
echo "========================================"
echo ""

for test_file in $(find "${TEST_DIR}" -name "*_test.sh" | sort); do
  run_test "$test_file"
done

# Print summary
echo "========================================"
echo -e "${YELLOW}Test Summary:${NC}"
echo "Total: ${TESTS_TOTAL}"
echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
echo -e "${YELLOW}Skipped: ${TESTS_SKIPPED}${NC}"

# Exit with error if any tests failed
if [ ${TESTS_FAILED} -gt 0 ]; then
  exit 1
fi

exit 0