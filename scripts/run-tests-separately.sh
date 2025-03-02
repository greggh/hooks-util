#!/bin/bash
# Simple integration test runner that runs each test separately

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Directory containing integration tests
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
INTEGRATION_TEST_DIR="${PROJECT_DIR}/tests/integration"

# Print banner
echo -e "${YELLOW}Running hooks-util Integration Tests${NC}"
echo "=================================================="
echo ""

# Define test order
declare -a TEST_ORDER=(
  "basic_test.sh"
  "neovim_config_test.sh" 
  "plugin_test.sh"
  "tool_validation_test.sh"
)

# Run tests in specified order
for test_name in "${TEST_ORDER[@]}"; do
  test_script="${INTEGRATION_TEST_DIR}/${test_name}"
  
  # Skip if test doesn't exist
  if [ ! -f "$test_script" ]; then
    echo -e "${YELLOW}Warning: Test $test_name not found, skipping${NC}"
    continue
  fi
  
  echo -e "${YELLOW}Running test: ${test_name}${NC}"
  
  # Run the test with verbose output
  HOOKS_VERBOSITY=2 bash "$test_script"
  exit_code=$?
  
  # Report the result
  if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}✓ ${test_name} passed${NC}"
  else
    echo -e "${RED}✗ ${test_name} failed (Exit code: $exit_code)${NC}"
  fi
  
  echo ""
done

echo "All tests completed!"