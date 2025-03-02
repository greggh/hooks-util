#!/bin/bash
# Integration test runner for hooks-util
set -eo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
INTEGRATION_TEST_DIR="${PROJECT_DIR}/tests/integration"

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Initialize test counts
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test script
run_test() {
  local test_script="$1"
  local test_name=$(basename "$test_script" .sh)
  
  echo -e "${YELLOW}Running test: ${test_name}${NC}"
  echo -e "${YELLOW}Test script: ${test_script}${NC}"
  ((TESTS_TOTAL++))
  
  # Run test script with verbose output
  HOOKS_VERBOSITY=2 bash "$test_script"
  local exit_code=$?
  
  # Check the exit code
  if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}✓ ${test_name} passed${NC}"
    ((TESTS_PASSED++))
  else
    echo -e "${RED}✗ ${test_name} failed (Exit code: $exit_code)${NC}"
    ((TESTS_FAILED++))
  fi
  
  echo ""
}

# Make sure all test scripts are executable
chmod +x "${INTEGRATION_TEST_DIR}"/*.sh

# Print banner
echo -e "${YELLOW}Running hooks-util Integration Tests${NC}"
echo "=================================================="
echo ""

# Run all integration tests
for test_script in $(find "${INTEGRATION_TEST_DIR}" -name "*.sh" | sort); do
  run_test "$test_script"
done

# Print summary
echo "=================================================="
echo -e "${YELLOW}Test Summary:${NC}"
echo "Total: ${TESTS_TOTAL}"
echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"

# Exit with error if any tests failed
if [ ${TESTS_FAILED} -gt 0 ]; then
  exit 1
fi

exit 0