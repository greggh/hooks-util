#!/bin/bash
# Path handling utilities for Neovim Hooks Utilities

# Include the common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Function to normalize a path for the current operating system
# Usage: hooks_normalize_path "/path/to/something"
hooks_normalize_path() {
  local path="$1"
  
  # Detect the operating system
  local os_name
  os_name=$(uname -s)
  
  if [[ "${os_name}" == "MINGW"* ]] || [[ "${os_name}" == "MSYS"* ]] || [[ "${os_name}" == "CYGWIN"* ]]; then
    # Windows systems - convert Unix-style paths to Windows-style
    # Example: /c/Users/username -> C:/Users/username
    path=$(echo "$path" | sed -E 's|^/([a-zA-Z])/|\1:/|')
    # Use proper escaping for backslashes in tr
    path=$(echo "$path" | tr '/' '\')
  else
    # Unix-like systems (Linux, macOS)
    # Just make sure it's a canonical path
    path=$(realpath -m "$path" 2>/dev/null || echo "$path")
  fi
  
  echo "$path"
}

# Function to resolve environment variables in a path
# Usage: hooks_resolve_env_vars "~/path/to/$HOME/something"
hooks_resolve_env_vars() {
  local path="$1"
  
  # Resolve ~ to $HOME
  path="${path/#\~/$HOME}"
  
  # Resolve other environment variables
  # This uses parameter expansion to resolve variables
  while [[ "$path" =~ \$\{?([a-zA-Z_][a-zA-Z0-9_]*)\}? ]]; do
    local var_name="${BASH_REMATCH[1]}"
    local var_value="${!var_name}"
    
    # Replace the variable with its value
    path="${path/\$\{$var_name\}/$var_value}"
    path="${path/\$$var_name/$var_value}"
  done
  
  echo "$path"
}

# Function to get an absolute path from a relative path
# Usage: hooks_absolute_path "relative/path"
hooks_absolute_path() {
  local path="$1"
  local base_dir="${2:-$PWD}"
  
  # Check if the path is already absolute
  if [[ "$path" == /* ]]; then
    echo "$path"
  else
    echo "${base_dir}/${path}"
  fi
}

# Function to make a path relative to another path
# Usage: hooks_relative_path "/absolute/path" "/absolute/base"
hooks_relative_path() {
  local path="$1"
  local base_dir="${2:-$PWD}"
  
  # Ensure both paths are absolute
  path=$(hooks_absolute_path "$path")
  base_dir=$(hooks_absolute_path "$base_dir")
  
  # Use Python to calculate the relative path if available
  if hooks_command_exists python; then
    python -c "import os.path; print(os.path.relpath('$path', '$base_dir'))"
  else
    # Fallback: try to use realpath
    if hooks_command_exists realpath; then
      realpath --relative-to="$base_dir" "$path"
    else
      # If all else fails, just return the absolute path
      echo "$path"
    fi
  fi
}

# Function to find a file by searching up the directory tree
# Usage: hooks_find_up "filename" [starting_dir]
hooks_find_up() {
  local filename="$1"
  local dir="${2:-$PWD}"
  
  while [[ "$dir" != "/" ]]; do
    if [[ -e "${dir}/${filename}" ]]; then
      echo "${dir}/${filename}"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  
  # Check the root directory as well
  if [[ -e "/${filename}" ]]; then
    echo "/${filename}"
    return 0
  fi
  
  return 1
}

# Function to find the nearest configuration file by searching up the directory tree
# Usage: hooks_find_config [config_filename] [starting_dir]
hooks_find_config() {
  local config_file="${1:-.hooksrc}"
  local dir="${2:-$PWD}"
  
  hooks_find_up "$config_file" "$dir"
}

# Export all functions
export -f hooks_normalize_path
export -f hooks_resolve_env_vars
export -f hooks_absolute_path
export -f hooks_relative_path
export -f hooks_find_up
export -f hooks_find_config