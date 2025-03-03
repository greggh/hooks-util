#!/bin/bash
# Simple test runner for basic_test.sh

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEST_DIR="${PROJECT_DIR}/tests"
LIB_DIR="${PROJECT_DIR}/lib"

# Export LIB_DIR for the test script
export LIB_DIR

echo "Running basic_test.sh with LIB_DIR=${LIB_DIR}"
"${TEST_DIR}/basic_test.sh"
exit $?