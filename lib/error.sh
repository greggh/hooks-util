#!/bin/bash
# Error handling for Neovim Hooks Utilities

# Include the common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Error codes
export HOOKS_ERROR_SUCCESS=0
export HOOKS_ERROR_GENERAL=1
export HOOKS_ERROR_COMMAND_NOT_FOUND=127
export HOOKS_ERROR_STYLUA_FAILED=10
export HOOKS_ERROR_LUACHECK_FAILED=11
export HOOKS_ERROR_SHELLCHECK_FAILED=12
export HOOKS_ERROR_TESTS_FAILED=13
export HOOKS_ERROR_CONFIG_INVALID=20
export HOOKS_ERROR_PATH_NOT_FOUND=30
export HOOKS_ERROR_TIMEOUT=40

# Keep track of errors
HOOKS_ERROR_COUNT=0
HOOKS_ERROR_MESSAGES=()

# Function to handle errors with descriptive messages
# Usage: hooks_handle_error $? "Error message" [error_code]
hooks_handle_error() {
  local exit_code=$1
  local message="$2"
  local error_code="${3:-$exit_code}"
  
  if [ "$exit_code" -ne 0 ]; then
    hooks_error "$message (Exit code: $exit_code)"
    ((HOOKS_ERROR_COUNT++))
    HOOKS_ERROR_MESSAGES+=("$message")
    return "$error_code"
  fi
  
  return "$HOOKS_ERROR_SUCCESS"
}

# Function to check if a command exists, with fallback options
# Usage: hooks_require_command "primary-command" ["alternative-command"...]
hooks_require_command() {
  local primary_command="$1"
  shift
  
  if hooks_command_exists "$primary_command"; then
    hooks_debug "Command '$primary_command' found"
    echo "$primary_command"
    return "$HOOKS_ERROR_SUCCESS"
  fi
  
  # Try alternative commands if provided
  for cmd in "$@"; do
    if hooks_command_exists "$cmd"; then
      hooks_warning "Primary command '$primary_command' not found, using '$cmd' instead"
      echo "$cmd"
      return "$HOOKS_ERROR_SUCCESS"
    fi
  done
  
  # No command found
  hooks_error "Required command '$primary_command' not found"
  return "$HOOKS_ERROR_COMMAND_NOT_FOUND"
}

# Function to try running a command with fallback options
# Usage: hooks_try_command "command" ["fallback-command"...]
hooks_try_command() {
  local command_to_run
  command_to_run=$(hooks_require_command "$@")
  local exit_code=$?
  
  if [ "$exit_code" -eq 0 ]; then
    hooks_debug "Running command: $command_to_run"
    $command_to_run
    return $?
  else
    hooks_error "No suitable command found to run"
    return "$HOOKS_ERROR_COMMAND_NOT_FOUND"
  fi
}

# Function to run a command with a timeout
# Usage: hooks_run_with_timeout TIMEOUT_SECONDS COMMAND [ARGS...]
hooks_run_with_timeout() {
  local timeout=$1
  shift
  
  # Check if we have the timeout command
  if hooks_command_exists timeout; then
    timeout "$timeout" "$@"
    local exit_code=$?
    if [ "$exit_code" -eq 124 ]; then
      hooks_error "Command timed out after ${timeout} seconds: $*"
      return "$HOOKS_ERROR_TIMEOUT"
    fi
    return "$exit_code"
  else
    # Fallback: run without timeout
    hooks_warning "Timeout command not available, running without timeout: $*"
    "$@"
    return $?
  fi
}

# Function to print a summary of errors
# Usage: hooks_print_error_summary
hooks_print_error_summary() {
  if [ "$HOOKS_ERROR_COUNT" -gt 0 ]; then
    hooks_print_header "Error Summary"
    hooks_error "Found $HOOKS_ERROR_COUNT error(s):"
    
    local i=1
    for error_msg in "${HOOKS_ERROR_MESSAGES[@]}"; do
      hooks_error "  $i. $error_msg"
      ((i++))
    done
    
    echo -e "\n${HOOKS_COLOR_YELLOW}${HOOKS_COLOR_BOLD}Hint:${HOOKS_COLOR_RESET} Run with increased verbosity for more details"
    echo -e "${HOOKS_COLOR_YELLOW}${HOOKS_COLOR_BOLD}Bypass:${HOOKS_COLOR_RESET} You can bypass this check with git commit --no-verify\n"
    
    return "$HOOKS_ERROR_GENERAL"
  fi
  
  return "$HOOKS_ERROR_SUCCESS"
}

# Function to reset error counter
# Usage: hooks_reset_errors
hooks_reset_errors() {
  HOOKS_ERROR_COUNT=0
  HOOKS_ERROR_MESSAGES=()
}

# Export all functions
export -f hooks_handle_error
export -f hooks_require_command
export -f hooks_try_command
export -f hooks_run_with_timeout
export -f hooks_print_error_summary
export -f hooks_reset_errors

# Export variables
export HOOKS_ERROR_COUNT
export HOOKS_ERROR_MESSAGES