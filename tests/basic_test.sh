#!/bin/bash
# Basic smoke test

# Echo the LIB_DIR for debugging
echo "LIB_DIR=${LIB_DIR}"

# Check that common.sh exists
if [ ! -f "${LIB_DIR}/common.sh" ]; then
  echo "Error: common.sh not found at ${LIB_DIR}/common.sh"
  exit 1
fi

# Check that version.sh exists
if [ ! -f "${LIB_DIR}/version.sh" ]; then
  echo "Error: version.sh not found at ${LIB_DIR}/version.sh"
  exit 1
fi

# Try to source version.sh
source "${LIB_DIR}/version.sh"
echo "HOOKS_UTIL_VERSION=${HOOKS_UTIL_VERSION}"

# Try to source common.sh
source "${LIB_DIR}/common.sh"
echo "Common.sh sourced successfully"

# Use a simple function from common.sh
hooks_message "Test message from hooks_message"

# All tests passed
exit 0