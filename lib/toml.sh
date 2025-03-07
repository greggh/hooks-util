#!/bin/bash
# TOML validation utilities for Neovim Hooks Utilities

# Include the necessary libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/error.sh"
source "${SCRIPT_DIR}/path.sh"

# Function to get all staged TOML files
# Usage: hooks_get_staged_toml_files
hooks_get_staged_toml_files() {
  git diff --cached --name-only --diff-filter=ACM | grep -E '\.toml$'
}

# Function to lint a TOML file
# Usage: hooks_toml_lint "file.toml"
hooks_toml_lint() {
  local file="$1"
  
  if [ ! -f "$file" ]; then
    hooks_error "File not found: $file"
    return "$HOOKS_ERROR_PATH_NOT_FOUND"
  fi
  
  # Try different TOML linting tools
  if hooks_command_exists taplo; then
    hooks_debug "Using taplo to lint $file"
    
    # Check if taplo config exists
    local taplo_config="${TARGET_DIR}/.taplo.toml"
    
    if [ -f "${taplo_config}" ]; then
      hooks_debug "Using taplo config at ${taplo_config}"
      taplo lint --config "${taplo_config}" "$file"
    else
      # Check if config exists in templates directory
      local template_config="${SCRIPT_DIR}/../templates/.taplo.toml"
      if [ -f "${template_config}" ]; then
        hooks_debug "Using template taplo config"
        taplo lint --config "${template_config}" "$file"
      else
        hooks_debug "Using default taplo config"
        taplo lint "$file"
      fi
    fi
    
    return $?
  elif hooks_command_exists tomll; then
    hooks_debug "Using tomll to lint $file"
    tomll "$file"
    return $?
  else
    hooks_warning "TOML linting tools not found. Skipping linting for $file"
    return "$HOOKS_ERROR_SUCCESS"  # Return success to allow hook to continue
  fi
}

# Function to lint all staged TOML files
# Usage: hooks_toml_staged
hooks_toml_staged() {
  # Get all staged TOML files
  local toml_files
  toml_files=$(hooks_get_staged_toml_files)
  
  if [ -z "$toml_files" ]; then
    hooks_debug "No staged TOML files to process"
    return "$HOOKS_ERROR_SUCCESS"
  fi
  
  hooks_debug "Processing TOML files: $toml_files"
  
  # Process each file
  local exit_code=0
  while read -r file; do
    if [ -n "$file" ]; then
      # Lint TOML files
      hooks_toml_lint "$file"
      local lint_exit_code=$?
      
      if [ "$lint_exit_code" -ne 0 ]; then
        hooks_error "TOML linting failed for $file"
        exit_code=$lint_exit_code
      fi
    fi
  done <<< "$toml_files"
  
  return "$exit_code"
}

# Export all functions
export -f hooks_get_staged_toml_files
export -f hooks_toml_lint
export -f hooks_toml_staged