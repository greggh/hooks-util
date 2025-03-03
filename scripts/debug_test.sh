#!/bin/bash
# Debug script to diagnose exit code issues

set -e

# Get the absolute paths
PROJECT_DIR="/home/gregg/Projects/hooks-util"

# Run a specific test in debug mode
TEST_NAME="basic_test"
TEST_FILE="${PROJECT_DIR}/tests/integration/${TEST_NAME}.sh"

echo "========== DEBUGGING TEST EXIT CODE =========="
echo "Running $TEST_NAME with exit code tracing..."

# Save original directory
ORIGINAL_PWD="$PWD"

# Run the test with exit code tracing
(
  # Run with -x for debugging
  set -x
  # Use a subshell to isolate changes
  bash "$TEST_FILE"
  ACTUAL_EXIT_CODE=$?
  echo "Actual exit code: $ACTUAL_EXIT_CODE"
  exit $ACTUAL_EXIT_CODE
)
CAPTURED_EXIT_CODE=$?

# Return to original directory
cd "$ORIGINAL_PWD" || exit 1

echo "========== TEST EXIT CODE REPORT =========="
echo "Captured exit code: $CAPTURED_EXIT_CODE"
echo "Is this what we expect? We want 0 (success)."

exit 0