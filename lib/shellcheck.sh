#!/bin/bash
# ShellCheck integration for Neovim Hooks Utilities

# Include the necessary libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/error.sh"
source "${SCRIPT_DIR}/path.sh"

# Function to check if ShellCheck is available
# Usage: hooks_shellcheck_available
hooks_shellcheck_available() {
  # First check if SHELLCHECK_CMD is already set from pre-commit hook
  if [ -n "${SHELLCHECK_CMD:-}" ]; then
    return 0
  fi
  
  # Next try direct command check
  if command -v shellcheck >/dev/null 2>&1; then
    SHELLCHECK_CMD="shellcheck"
    return 0
  fi
  
  # Try some common locations as fallbacks
  if [ -f "/usr/bin/shellcheck" ]; then
    SHELLCHECK_CMD="/usr/bin/shellcheck"
    return 0
  elif [ -f "/usr/local/bin/shellcheck" ]; then
    SHELLCHECK_CMD="/usr/local/bin/shellcheck"
    return 0
  elif [ -f "/opt/homebrew/bin/shellcheck" ]; then
    SHELLCHECK_CMD="/opt/homebrew/bin/shellcheck"
    return 0
  fi
  
  # Not found
  SHELLCHECK_CMD=""
  return 1
}

# Function to run ShellCheck on a shell script
# Usage: hooks_shellcheck_run "file.sh" [severity]
hooks_shellcheck_run() {
  local file="$1"
  local severity="${2:-error}"  # Default severity level: error
  local shellcheck_args=()
  
  # Check if ShellCheck is available
  if ! hooks_shellcheck_available; then
    hooks_warning "ShellCheck not found, skipping shell script validation for $file"
    return "$HOOKS_ERROR_COMMAND_NOT_FOUND"
  fi
  
  # Check if the file exists
  if [ ! -f "$file" ]; then
    hooks_error "File not found: $file"
    return "$HOOKS_ERROR_PATH_NOT_FOUND"
  fi
  
  # Add standard arguments
  shellcheck_args+=("--severity=$severity")
  shellcheck_args+=("--format=gcc")  # Use GCC format for consistent parsing
  
  # Run ShellCheck
  hooks_debug "Running ShellCheck on $file"
  ${SHELLCHECK_CMD:-shellcheck} "${shellcheck_args[@]}" "$file"
  local exit_code=$?
  
  if [ "$exit_code" -ne 0 ]; then
    hooks_error "ShellCheck failed for $file (Exit code: $exit_code)"
    return "$HOOKS_ERROR_SHELLCHECK_FAILED"
  fi
  
  hooks_debug "ShellCheck successfully validated $file"
  return "$HOOKS_ERROR_SUCCESS"
}

# Function to run ShellCheck on multiple shell scripts
# Usage: hooks_shellcheck_run_files "file1.sh" "file2.sh" ...
hooks_shellcheck_run_files() {
  local files=("$@")
  local exit_code=0
  local checked_count=0
  local failed_count=0
  local skipped_count=0
  
  if [ ${#files[@]} -eq 0 ]; then
    hooks_debug "No files to check"
    return "$HOOKS_ERROR_SUCCESS"
  fi
  
  hooks_print_header "Running ShellCheck on ${#files[@]} files"
  
  for file in "${files[@]}"; do
    if hooks_is_shell_file "$file"; then
      hooks_shellcheck_run "$file"
      local file_exit_code=$?
      
      if [ "$file_exit_code" -eq 0 ]; then
        ((checked_count++))
      elif [ "$file_exit_code" -eq "$HOOKS_ERROR_COMMAND_NOT_FOUND" ]; then
        ((skipped_count++))
        if [ $exit_code -eq 0 ]; then
          exit_code=$file_exit_code
        fi
      else
        ((failed_count++))
        exit_code=$file_exit_code
      fi
    else
      hooks_debug "Skipping non-shell file: $file"
      ((skipped_count++))
    fi
  done
  
  if [ $checked_count -gt 0 ]; then
    hooks_success "ShellCheck verified $checked_count files successfully"
  fi
  
  if [ $failed_count -gt 0 ]; then
    hooks_error "ShellCheck found errors in $failed_count files"
  fi
  
  if [ $skipped_count -gt 0 ]; then
    hooks_info "Skipped $skipped_count files"
  fi
  
  return "$exit_code"
}

# Function to run ShellCheck on staged shell script files
# Usage: hooks_shellcheck_staged
hooks_shellcheck_staged() {
  local staged_files
  staged_files=$(hooks_get_staged_shell_files)
  
  if [ -z "$staged_files" ]; then
    hooks_debug "No staged shell script files to check"
    return "$HOOKS_ERROR_SUCCESS"
  fi
  
  local files_array=()
  while IFS= read -r file; do
    files_array+=("$file")
  done <<< "$staged_files"
  
  hooks_shellcheck_run_files "${files_array[@]}"
  local exit_code=$?
  
  return "$exit_code"
}

# Export all functions
export -f hooks_shellcheck_available
export -f hooks_shellcheck_run
export -f hooks_shellcheck_run_files
export -f hooks_shellcheck_staged