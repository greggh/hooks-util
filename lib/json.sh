#!/bin/bash
# JSON validation utilities for Neovim Hooks Utilities

# Include the necessary libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/error.sh"
source "${SCRIPT_DIR}/path.sh"

# Function to get all staged JSON files
# Usage: hooks_get_staged_json_files
hooks_get_staged_json_files() {
  git diff --cached --name-only --diff-filter=ACM | grep -E '\.json$'
}

# Function to lint a JSON file
# Usage: hooks_json_lint "file.json"
hooks_json_lint() {
  local file="$1"
  
  if [ ! -f "$file" ]; then
    hooks_error "File not found: $file"
    return "$HOOKS_ERROR_PATH_NOT_FOUND"
  fi
  
  # Try different JSON linting tools
  if hooks_command_exists jsonlint; then
    hooks_debug "Using jsonlint to lint $file"
    jsonlint -c "${TARGET_DIR}/.jsonlintrc" "$file"
    return $?
  elif hooks_command_exists jq; then
    hooks_debug "Using jq to lint $file"
    jq empty "$file"
    return $?
  else
    hooks_warning "JSON linting tools not found. Skipping linting for $file"
    return "$HOOKS_ERROR_COMMAND_NOT_FOUND"
  fi
}

# Function to lint all staged JSON files
# Usage: hooks_json_staged
hooks_json_staged() {
  # Get all staged JSON files
  local json_files
  json_files=$(hooks_get_staged_json_files)
  
  if [ -z "$json_files" ]; then
    hooks_debug "No staged JSON files to process"
    return "$HOOKS_ERROR_SUCCESS"
  fi
  
  hooks_debug "Processing JSON files: $json_files"
  
  # Process each file
  local exit_code=0
  while read -r file; do
    if [ -n "$file" ]; then
      # Lint JSON files
      hooks_json_lint "$file"
      local lint_exit_code=$?
      
      if [ "$lint_exit_code" -ne 0 ]; then
        hooks_error "JSON linting failed for $file"
        exit_code=$lint_exit_code
      fi
    fi
  done <<< "$json_files"
  
  return "$exit_code"
}

# Export all functions
export -f hooks_get_staged_json_files
export -f hooks_json_lint
export -f hooks_json_staged