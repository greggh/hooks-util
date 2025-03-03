#!/bin/bash
# Luacheck integration for Neovim Hooks Utilities

# Include the necessary libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/error.sh"
source "${SCRIPT_DIR}/path.sh"

# Function to check if Luacheck is available
# Usage: hooks_luacheck_available
hooks_luacheck_available() {
  hooks_command_exists luacheck
}

# Function to find Luacheck configuration file
# Usage: hooks_find_luacheck_config [starting_dir]
hooks_find_luacheck_config() {
  local dir="${1:-$PWD}"
  local config_file
  
  # Try to find .luacheckrc (common name)
  config_file=$(hooks_find_up ".luacheckrc" "$dir")
  if [ -n "$config_file" ]; then
    echo "$config_file"
    return 0
  fi
  
  # Try to find luacheck.rc (alternative name)
  config_file=$(hooks_find_up "luacheck.rc" "$dir")
  if [ -n "$config_file" ]; then
    echo "$config_file"
    return 0
  fi
  
  # No config file found
  return 1
}

# Function to run Luacheck on a Lua file
# Usage: hooks_luacheck_run "file.lua" [config_file]
hooks_luacheck_run() {
  local file="$1"
  local config_file="$2"
  local luacheck_args=()
  
  # Check if Luacheck is available
  if ! hooks_luacheck_available; then
    hooks_warning "Luacheck not found, skipping linting for $file"
    return "$HOOKS_ERROR_COMMAND_NOT_FOUND"
  fi
  
  # Check if the file exists
  if [ ! -f "$file" ]; then
    hooks_error "File not found: $file"
    return "$HOOKS_ERROR_PATH_NOT_FOUND"
  fi
  
  # Add standard arguments
  luacheck_args+=("--codes")  # Show error codes
  luacheck_args+=("--no-color")  # Disable color output for better parsing
  
  # Use configuration file if provided
  if [ -n "$config_file" ] && [ -f "$config_file" ]; then
    hooks_debug "Using Luacheck config file: $config_file"
    # Luacheck automatically finds .luacheckrc files, so we don't need to specify it
    # We just need to run it from the directory that contains the config
    local original_dir="$PWD"
    # Declare and assign separately to avoid masking return values
    local config_dir
    config_dir=$(dirname "$config_file")
    cd "$config_dir" || return "$HOOKS_ERROR_PATH_NOT_FOUND"
    
    # Use absolute path for the file if we're changing directories
    local abs_file
    abs_file=$(hooks_absolute_path "$file" "$original_dir")
    
    # Run Luacheck
    hooks_debug "Running Luacheck on $abs_file from $config_dir"
    luacheck "${luacheck_args[@]}" "$abs_file"
    local exit_code=$?
    
    # Change back to the original directory
    cd "$original_dir" || return "$HOOKS_ERROR_PATH_NOT_FOUND"
  else
    # Try to find a config file
    local found_config
    found_config=$(hooks_find_luacheck_config "$(dirname "$file")")
    if [ -n "$found_config" ]; then
      hooks_debug "Found Luacheck config file: $found_config"
      local original_dir="$PWD"
      # Declare and assign separately to avoid masking return values
      local config_dir
      config_dir=$(dirname "$found_config")
      cd "$config_dir" || return "$HOOKS_ERROR_PATH_NOT_FOUND"
      
      # Use absolute path for the file if we're changing directories
      local abs_file
      abs_file=$(hooks_absolute_path "$file" "$original_dir")
      
      # Run Luacheck
      hooks_debug "Running Luacheck on $abs_file from $config_dir"
      luacheck "${luacheck_args[@]}" "$abs_file"
      local exit_code=$?
      
      # Change back to the original directory
      cd "$original_dir" || return "$HOOKS_ERROR_PATH_NOT_FOUND"
    else
      # No config file found, run with default settings
      hooks_debug "No Luacheck config file found, using defaults"
      luacheck "${luacheck_args[@]}" "$file"
      local exit_code=$?
    fi
  fi
  
  if [ "$exit_code" -ne 0 ]; then
    if [ "$exit_code" -eq 1 ]; then
      # Exit code 1 means warnings only, which we'll allow
      hooks_warning "Luacheck found warnings in $file (Exit code: $exit_code)"
      return "$HOOKS_ERROR_SUCCESS"
    else
      # Exit code 2+ means errors
      hooks_error "Luacheck found errors in $file (Exit code: $exit_code)"
      return "$HOOKS_ERROR_LUACHECK_FAILED"
    fi
  fi
  
  hooks_debug "Luacheck successfully checked $file"
  return "$HOOKS_ERROR_SUCCESS"
}

# Function to run Luacheck on multiple Lua files
# Usage: hooks_luacheck_run_files "file1.lua" "file2.lua" ...
hooks_luacheck_run_files() {
  local files=("$@")
  local exit_code=0
  local checked_count=0
  local failed_count=0
  local skipped_count=0
  
  if [ ${#files[@]} -eq 0 ]; then
    hooks_debug "No files to check"
    return "$HOOKS_ERROR_SUCCESS"
  fi
  
  hooks_print_header "Running Luacheck on ${#files[@]} files"
  
  # Find Luacheck config file once
  local config_file
  config_file=$(hooks_find_luacheck_config)
  
  for file in "${files[@]}"; do
    if hooks_is_lua_file "$file"; then
      hooks_luacheck_run "$file" "$config_file"
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
      hooks_debug "Skipping non-Lua file: $file"
      ((skipped_count++))
    fi
  done
  
  if [ $checked_count -gt 0 ]; then
    hooks_success "Luacheck verified $checked_count files successfully"
  fi
  
  if [ $failed_count -gt 0 ]; then
    hooks_error "Luacheck found errors in $failed_count files"
  fi
  
  if [ $skipped_count -gt 0 ]; then
    hooks_info "Skipped $skipped_count files"
  fi
  
  return "$exit_code"
}

# Function to run Luacheck on staged Lua files
# Usage: hooks_luacheck_staged
hooks_luacheck_staged() {
  local staged_files
  staged_files=$(hooks_get_staged_lua_files)
  
  if [ -z "$staged_files" ]; then
    hooks_debug "No staged Lua files to check"
    return "$HOOKS_ERROR_SUCCESS"
  fi
  
  local files_array=()
  while IFS= read -r file; do
    files_array+=("$file")
  done <<< "$staged_files"
  
  hooks_luacheck_run_files "${files_array[@]}"
  local exit_code=$?
  
  return "$exit_code"
}

# Export all functions
export -f hooks_luacheck_available
export -f hooks_find_luacheck_config
export -f hooks_luacheck_run
export -f hooks_luacheck_run_files
export -f hooks_luacheck_staged