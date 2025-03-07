#!/bin/bash
# Ensure all submodules including nested ones are properly initialized
# This script ensures that lust-next is properly initialized in hooks-util
# and that hooks-util is properly initialized in projects that use it

set -e
set -o pipefail

# Determine the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Include library files
source "${ROOT_DIR}/lib/common.sh"
source "${ROOT_DIR}/lib/error.sh"
source "${ROOT_DIR}/lib/path.sh"

# Function to check if we're in a git repository
is_git_repo() {
  git -C "$1" rev-parse --is-inside-work-tree > /dev/null 2>&1
  return $?
}

# Parse command-line arguments
TARGET_DIR=""
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target)
      TARGET_DIR="$2"
      shift 2
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo
      echo "Options:"
      echo "  -t, --target DIR  Target directory (default: current git repo)"
      echo "  -v, --verbose     Enable verbose output"
      echo "  -h, --help        Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Determine target directory if not specified
if [ -z "$TARGET_DIR" ]; then
  if ! TARGET_DIR=$(hooks_git_root); then
    echo "Error: Not in a git repository. Please specify a target directory with -t."
    exit 1
  fi
fi

# Verify target is a git repository
if ! is_git_repo "$TARGET_DIR"; then
  echo "Error: Target directory is not a git repository: $TARGET_DIR"
  exit 1
fi

echo "==== Neovim Hooks Utilities Submodule Initialization ===="
echo "Target directory: $TARGET_DIR"

# Check if we're in the hooks-util repository itself
if [ "$(basename "$TARGET_DIR")" = "hooks-util" ]; then
  echo "Initializing submodules in hooks-util repository"
  
  # Initialize and update submodules in hooks-util
  if [ "$VERBOSE" = true ]; then
    git -C "$TARGET_DIR" submodule update --init --recursive
  else
    git -C "$TARGET_DIR" submodule update --init --recursive --quiet
  fi
  
  # Check for lust-next specifically
  if [ -d "$TARGET_DIR/deps/lust-next" ]; then
    echo "Success: lust-next submodule is properly initialized"
  else
    echo "Error: lust-next submodule not found or not initialized"
    exit 1
  fi
  
  echo "All submodules in hooks-util have been initialized"
  
else
  # Check if this is a project that uses hooks-util as a submodule
  HOOKS_UTIL_PATH="$TARGET_DIR/.githooks/hooks-util"
  
  if [ -d "$HOOKS_UTIL_PATH" ]; then
    echo "Found hooks-util as a submodule at: $HOOKS_UTIL_PATH"
    
    # Initialize and update hooks-util submodule
    if [ "$VERBOSE" = true ]; then
      git -C "$TARGET_DIR" submodule update --init "$HOOKS_UTIL_PATH"
    else
      git -C "$TARGET_DIR" submodule update --init "$HOOKS_UTIL_PATH" --quiet
    fi
    
    # Initialize submodules within hooks-util
    echo "Initializing submodules within hooks-util"
    if [ "$VERBOSE" = true ]; then
      git -C "$HOOKS_UTIL_PATH" submodule update --init --recursive
    else
      git -C "$HOOKS_UTIL_PATH" submodule update --init --recursive --quiet
    fi
    
    # Check for lust-next specifically
    if [ -d "$HOOKS_UTIL_PATH/deps/lust-next" ]; then
      echo "Success: lust-next submodule is properly initialized"
    else
      echo "Error: lust-next submodule not found or not initialized in hooks-util"
      exit 1
    fi
    
    echo "All submodules have been recursively initialized"
    
  else
    echo "Warning: hooks-util not found as a submodule in this project"
    echo "If this project should use hooks-util, you need to add it as a submodule first:"
    echo "  git submodule add https://github.com/greggh/hooks-util.git .githooks/hooks-util"
    echo "  git submodule update --init --recursive .githooks/hooks-util"
  fi
fi

echo "==== Submodule Initialization Complete ===="
echo "Run this script any time you need to ensure submodules are properly initialized"

exit 0