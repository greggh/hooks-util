#!/bin/bash
# YAML validation utilities for Neovim Hooks Utilities

# Include the necessary libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/error.sh"
source "${SCRIPT_DIR}/path.sh"

# Function to get all staged YAML files
# Usage: hooks_get_staged_yaml_files
hooks_get_staged_yaml_files() {
  git diff --cached --name-only --diff-filter=ACM | grep -E '\.(yaml|yml)$'
}

# Function to lint a YAML file
# Usage: hooks_yaml_lint "file.yaml"
hooks_yaml_lint() {
  local file="$1"
  
  if [ ! -f "$file" ]; then
    hooks_error "File not found: $file"
    return "$HOOKS_ERROR_PATH_NOT_FOUND"
  fi
  
  # Check if yamllint is available
  if hooks_command_exists yamllint; then
    hooks_debug "Using yamllint to lint $file"
    yamllint -c "${TARGET_DIR}/.yamllint.yml" "$file"
    return $?
  else
    hooks_warning "YAML linting tools not found. Skipping linting for $file"
    return "$HOOKS_ERROR_COMMAND_NOT_FOUND"
  fi
}

# Function to lint all staged YAML files
# Usage: hooks_yaml_staged
hooks_yaml_staged() {
  # Get all staged YAML files
  local yaml_files
  yaml_files=$(hooks_get_staged_yaml_files)
  
  if [ -z "$yaml_files" ]; then
    hooks_debug "No staged YAML files to process"
    return "$HOOKS_ERROR_SUCCESS"
  fi
  
  hooks_debug "Processing YAML files: $yaml_files"
  
  # Process each file
  local exit_code=0
  while read -r file; do
    if [ -n "$file" ]; then
      # Lint YAML files
      hooks_yaml_lint "$file"
      local lint_exit_code=$?
      
      if [ "$lint_exit_code" -ne 0 ]; then
        hooks_error "YAML linting failed for $file"
        exit_code=$lint_exit_code
      fi
    fi
  done <<< "$yaml_files"
  
  return "$exit_code"
}

# Export all functions
export -f hooks_get_staged_yaml_files
export -f hooks_yaml_lint
export -f hooks_yaml_staged