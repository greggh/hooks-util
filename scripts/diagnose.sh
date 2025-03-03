#!/bin/bash
# Diagnostic script to help isolate the issue

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
LIB_DIR="${PROJECT_DIR}/lib"

echo "SCRIPT_DIR=${SCRIPT_DIR}"
echo "PROJECT_DIR=${PROJECT_DIR}"
echo "LIB_DIR=${LIB_DIR}"

echo "Checking if common.sh exists..."
if [ -f "${LIB_DIR}/common.sh" ]; then
  echo "common.sh exists"
else
  echo "common.sh NOT found!"
  exit 1
fi

echo "Checking if version.sh exists..."
if [ -f "${LIB_DIR}/version.sh" ]; then
  echo "version.sh exists"
else
  echo "version.sh NOT found!"
  exit 1
fi

echo "Attempting to source version.sh..."
source "${LIB_DIR}/version.sh"
echo "HOOKS_UTIL_VERSION=${HOOKS_UTIL_VERSION}"

echo "Attempting to source common.sh..."
source "${LIB_DIR}/common.sh"
echo "Common.sh sourced successfully"

echo "Testing hooks_command_exists function..."
if hooks_command_exists "bash"; then
  echo "hooks_command_exists works properly"
else
  echo "hooks_command_exists failed"
  exit 1
fi

echo "Diagnostic completed successfully"
exit 0