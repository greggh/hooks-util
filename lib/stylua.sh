#!/bin/bash
# StyLua integration for Neovim Hooks Utilities

# Include the necessary libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/error.sh"
source "${SCRIPT_DIR}/path.sh"

# Function to check if StyLua is available
# Usage: hooks_stylua_available
hooks_stylua_available() {
  hooks_command_exists stylua
}

# Function to find StyLua configuration file
# Usage: hooks_find_stylua_config [starting_dir]
hooks_find_stylua_config() {
  local dir="${1:-$PWD}"
  local config_file
  
  # Try to find stylua.toml (preferred)
  config_file=$(hooks_find_up "stylua.toml" "$dir")
  if [ -n "$config_file" ]; then
    echo "$config_file"
    return 0
  fi
  
  # Try to find .stylua.toml
  config_file=$(hooks_find_up ".stylua.toml" "$dir")
  if [ -n "$config_file" ]; then
    echo "$config_file"
    return 0
  fi
  
  # No config file found
  return 1
}

# Function to format a Lua file with StyLua
# Usage: hooks_stylua_format "file.lua" [config_file]
hooks_stylua_format() {
  local file="$1"
  local config_file="$2"
  local stylua_args=()
  
  # Check if StyLua is available
  if ! hooks_stylua_available; then
    hooks_warning "StyLua not found, skipping formatting for $file"
    return "$HOOKS_ERROR_COMMAND_NOT_FOUND"
  fi
  
  # Check if the file exists
  if [ ! -f "$file" ]; then
    hooks_error "File not found: $file"
    return "$HOOKS_ERROR_PATH_NOT_FOUND"
  fi
  
  # Use configuration file if provided
  if [ -n "$config_file" ] && [ -f "$config_file" ]; then
    hooks_debug "Using StyLua config file: $config_file"
    stylua_args+=(--config-path "$config_file")
  else
    # Try to find a config file
    local found_config
    found_config=$(hooks_find_stylua_config "$(dirname "$file")")
    if [ -n "$found_config" ]; then
      hooks_debug "Found StyLua config file: $found_config"
      stylua_args+=(--config-path "$found_config")
    else
      hooks_debug "No StyLua config file found, using defaults"
    fi
  fi
  
  # Run StyLua
  hooks_debug "Running StyLua on $file"
  stylua "${stylua_args[@]}" "$file"
  local exit_code=$?
  
  if [ "$exit_code" -ne 0 ]; then
    hooks_error "StyLua failed for $file (Exit code: $exit_code)"
    return "$HOOKS_ERROR_STYLUA_FAILED"
  fi
  
  hooks_debug "StyLua successfully formatted $file"
  return "$HOOKS_ERROR_SUCCESS"
}

# Function to format multiple Lua files with StyLua
# Usage: hooks_stylua_format_files "file1.lua" "file2.lua" ...
hooks_stylua_format_files() {
  local files=("$@")
  local exit_code=0
  local formatted_count=0
  local failed_count=0
  local skipped_count=0
  
  if [ ${#files[@]} -eq 0 ]; then
    hooks_debug "No files to format"
    return "$HOOKS_ERROR_SUCCESS"
  fi
  
  hooks_print_header "Running StyLua on ${#files[@]} files"
  
  # Find StyLua config file once
  local config_file
  config_file=$(hooks_find_stylua_config)
  
  for file in "${files[@]}"; do
    if hooks_is_lua_file "$file"; then
      hooks_stylua_format "$file" "$config_file"
      local file_exit_code=$?
      
      if [ "$file_exit_code" -eq 0 ]; then
        ((formatted_count++))
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
  
  if [ $formatted_count -gt 0 ]; then
    hooks_success "StyLua formatted $formatted_count files successfully"
  fi
  
  if [ $failed_count -gt 0 ]; then
    hooks_error "StyLua failed on $failed_count files"
  fi
  
  if [ $skipped_count -gt 0 ]; then
    hooks_info "Skipped $skipped_count files"
  fi
  
  return "$exit_code"
}

# Function to run StyLua on staged Lua files
# Usage: hooks_stylua_staged
hooks_stylua_staged() {
  local staged_files
  staged_files=$(hooks_get_staged_lua_files)
  
  if [ -z "$staged_files" ]; then
    hooks_debug "No staged Lua files to format"
    return "$HOOKS_ERROR_SUCCESS"
  fi
  
  local files_array=()
  while IFS= read -r file; do
    files_array+=("$file")
  done <<< "$staged_files"
  
  hooks_stylua_format_files "${files_array[@]}"
  local exit_code=$?
  
  if [ "$exit_code" -eq 0 ]; then
    # Add the formatted files back to staging
    for file in "${files_array[@]}"; do
      git add "$file"
    done
    hooks_success "Formatted files have been staged"
  fi
  
  return "$exit_code"
}

# Export all functions
export -f hooks_stylua_available
export -f hooks_find_stylua_config
export -f hooks_stylua_format
export -f hooks_stylua_format_files
export -f hooks_stylua_staged