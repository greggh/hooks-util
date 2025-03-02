#!/bin/bash
# Common utility functions for Neovim Hooks Utilities

# Include the version information
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/version.sh"

# Color codes for better output formatting
export HOOKS_COLOR_RED='\033[0;31m'
export HOOKS_COLOR_GREEN='\033[0;32m'
export HOOKS_COLOR_YELLOW='\033[0;33m'
export HOOKS_COLOR_BLUE='\033[0;34m'
export HOOKS_COLOR_MAGENTA='\033[0;35m'
export HOOKS_COLOR_CYAN='\033[0;36m'
export HOOKS_COLOR_BOLD='\033[1m'
export HOOKS_COLOR_RESET='\033[0m'

# Verbosity levels
export HOOKS_VERBOSITY_QUIET=0
export HOOKS_VERBOSITY_NORMAL=1
export HOOKS_VERBOSITY_VERBOSE=2

# Default configuration values
export HOOKS_DEFAULT_VERBOSITY=${HOOKS_VERBOSITY_NORMAL}
export HOOKS_DEFAULT_STYLUA_ENABLED=true
export HOOKS_DEFAULT_LUACHECK_ENABLED=true
export HOOKS_DEFAULT_TESTS_ENABLED=true
export HOOKS_DEFAULT_TEST_TIMEOUT=60000  # 60 seconds

# Current verbosity level
HOOKS_VERBOSITY=${HOOKS_DEFAULT_VERBOSITY}

# Function to print error messages
# Usage: hooks_error "Error message"
hooks_error() {
  echo -e "${HOOKS_COLOR_RED}${HOOKS_COLOR_BOLD}Error:${HOOKS_COLOR_RESET} ${HOOKS_COLOR_RED}$1${HOOKS_COLOR_RESET}" >&2
}

# Function to print warning messages
# Usage: hooks_warning "Warning message"
hooks_warning() {
  echo -e "${HOOKS_COLOR_YELLOW}${HOOKS_COLOR_BOLD}Warning:${HOOKS_COLOR_RESET} ${HOOKS_COLOR_YELLOW}$1${HOOKS_COLOR_RESET}" >&2
}

# Function to print info messages
# Usage: hooks_info "Info message"
hooks_info() {
  echo -e "${HOOKS_COLOR_BLUE}${HOOKS_COLOR_BOLD}Info:${HOOKS_COLOR_RESET} $1"
}

# Function to print success messages
# Usage: hooks_success "Success message"
hooks_success() {
  echo -e "${HOOKS_COLOR_GREEN}${HOOKS_COLOR_BOLD}Success:${HOOKS_COLOR_RESET} ${HOOKS_COLOR_GREEN}$1${HOOKS_COLOR_RESET}"
}

# Function to print debug messages (only if verbosity is VERBOSE)
# Usage: hooks_debug "Debug message"
hooks_debug() {
  if [ "${HOOKS_VERBOSITY}" -ge "${HOOKS_VERBOSITY_VERBOSE}" ]; then
    echo -e "${HOOKS_COLOR_MAGENTA}${HOOKS_COLOR_BOLD}Debug:${HOOKS_COLOR_RESET} ${HOOKS_COLOR_MAGENTA}$1${HOOKS_COLOR_RESET}" >&2
  fi
}

# Function to print messages only if verbosity is not QUIET
# Usage: hooks_message "Message"
hooks_message() {
  if [ "${HOOKS_VERBOSITY}" -ge "${HOOKS_VERBOSITY_NORMAL}" ]; then
    echo -e "$1"
  fi
}

# Function to check if a command exists
# Usage: hooks_command_exists "command-name"
hooks_command_exists() {
  command -v "$1" &> /dev/null
}

# Function to set the verbosity level
# Usage: hooks_set_verbosity LEVEL
hooks_set_verbosity() {
  HOOKS_VERBOSITY=$1
  export HOOKS_VERBOSITY
}

# Function to load configuration from .hooksrc file and its variants
# Usage: hooks_load_config [path/to/.hooksrc]
hooks_load_config() {
  local config_file="${1:-"${PWD}/.hooksrc"}"
  local default_config_file="${SCRIPT_DIR}/../templates/hooksrc.template"
  local config_dir=$(dirname "$config_file")
  local local_config_file="${config_dir}/.hooksrc.local"
  local user_config_file="${config_dir}/.hooksrc.user"
  
  # Initialize with default values
  HOOKS_STYLUA_ENABLED=${HOOKS_DEFAULT_STYLUA_ENABLED}
  HOOKS_LUACHECK_ENABLED=${HOOKS_DEFAULT_LUACHECK_ENABLED}
  HOOKS_TESTS_ENABLED=${HOOKS_DEFAULT_TESTS_ENABLED}
  HOOKS_TEST_TIMEOUT=${HOOKS_DEFAULT_TEST_TIMEOUT}
  HOOKS_VERBOSITY=${HOOKS_DEFAULT_VERBOSITY}
  
  # Load default configuration file if exists
  if [ -f "${default_config_file}" ]; then
    hooks_debug "Loading default configuration from ${default_config_file}"
    # shellcheck disable=SC1090
    source "${default_config_file}"
  fi
  
  # Load project-specific configuration file if exists
  if [ -f "${config_file}" ]; then
    hooks_debug "Loading main configuration from ${config_file}"
    # shellcheck disable=SC1090
    source "${config_file}"
  else
    hooks_debug "Main configuration file ${config_file} not found, using defaults"
  fi
  
  # Load local machine configuration if exists
  if [ -f "${local_config_file}" ]; then
    hooks_debug "Loading local configuration from ${local_config_file}"
    # shellcheck disable=SC1090
    source "${local_config_file}"
  else
    hooks_debug "Local configuration file ${local_config_file} not found, skipping"
  fi
  
  # Load user-specific configuration if exists
  if [ -f "${user_config_file}" ]; then
    hooks_debug "Loading user configuration from ${user_config_file}"
    # shellcheck disable=SC1090
    source "${user_config_file}"
  else
    hooks_debug "User configuration file ${user_config_file} not found, skipping"
  fi
  
  # Export all configuration variables
  export HOOKS_STYLUA_ENABLED
  export HOOKS_LUACHECK_ENABLED
  export HOOKS_TESTS_ENABLED
  export HOOKS_TEST_TIMEOUT
  export HOOKS_VERBOSITY
}

# Function to get the Git top level directory
# Usage: hooks_git_root
hooks_git_root() {
  git rev-parse --show-toplevel
}

# Function to check if a file is a Lua file
# Usage: hooks_is_lua_file "filename"
hooks_is_lua_file() {
  [[ "$1" == *.lua ]]
}

# Function to get all staged Lua files
# Usage: hooks_get_staged_lua_files
hooks_get_staged_lua_files() {
  git diff --cached --name-only --diff-filter=ACM | grep -E '\.lua$'
}

# Function to print a header for a section
# Usage: hooks_print_header "Header text"
hooks_print_header() {
  if [ "${HOOKS_VERBOSITY}" -ge "${HOOKS_VERBOSITY_NORMAL}" ]; then
    echo -e "\n${HOOKS_COLOR_CYAN}${HOOKS_COLOR_BOLD}===== $1 =====${HOOKS_COLOR_RESET}\n"
  fi
}

# Export all functions
export -f hooks_error
export -f hooks_warning
export -f hooks_info
export -f hooks_success
export -f hooks_debug
export -f hooks_message
export -f hooks_command_exists
export -f hooks_set_verbosity
export -f hooks_load_config
export -f hooks_git_root
export -f hooks_is_lua_file
export -f hooks_get_staged_lua_files
export -f hooks_print_header