#!/bin/bash
# Code quality utilities for Neovim Hooks Utilities

# Include the necessary libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/error.sh"
source "${SCRIPT_DIR}/path.sh"

# Function to fix trailing whitespace in a file
# Usage: hooks_fix_trailing_whitespace "file.lua"
hooks_fix_trailing_whitespace() {
  local file="$1"
  
  if [ ! -f "$file" ]; then
    hooks_error "File not found: $file"
    return $HOOKS_ERROR_PATH_NOT_FOUND
  fi
  
  hooks_debug "Fixing trailing whitespace in $file"
  
  # Create a temporary file
  local temp_file
  temp_file=$(mktemp)
  
  # Remove trailing whitespace and preserve file encoding
  if hooks_command_exists sed; then
    sed 's/[[:space:]]*$//' "$file" > "$temp_file"
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
      hooks_error "Failed to fix trailing whitespace in $file"
      rm -f "$temp_file"
      return $HOOKS_ERROR_GENERAL
    fi
    
    # Replace the original file with the fixed one
    mv "$temp_file" "$file"
    return $HOOKS_ERROR_SUCCESS
  else
    hooks_error "sed command not found, cannot fix trailing whitespace"
    rm -f "$temp_file"
    return $HOOKS_ERROR_COMMAND_NOT_FOUND
  fi
}

# Function to ensure file ends with a single newline
# Usage: hooks_ensure_final_newline "file.lua"
hooks_ensure_final_newline() {
  local file="$1"
  
  if [ ! -f "$file" ]; then
    hooks_error "File not found: $file"
    return $HOOKS_ERROR_PATH_NOT_FOUND
  fi
  
  hooks_debug "Ensuring $file ends with a single newline"
  
  # Create a temporary file
  local temp_file
  temp_file=$(mktemp)
  
  # Ensure file ends with exactly one newline
  if hooks_command_exists awk; then
    # Remove all trailing newlines and add exactly one
    awk '{print}' "$file" | tr -d '\r' > "$temp_file"
    echo "" >> "$temp_file"
    
    # Replace the original file with the fixed one
    mv "$temp_file" "$file"
    return $HOOKS_ERROR_SUCCESS
  else
    hooks_error "awk command not found, cannot fix final newline"
    rm -f "$temp_file"
    return $HOOKS_ERROR_COMMAND_NOT_FOUND
  fi
}

# Function to fix Unix line endings (LF instead of CRLF)
# Usage: hooks_fix_line_endings "file.lua"
hooks_fix_line_endings() {
  local file="$1"
  
  if [ ! -f "$file" ]; then
    hooks_error "File not found: $file"
    return $HOOKS_ERROR_PATH_NOT_FOUND
  fi
  
  hooks_debug "Fixing line endings in $file"
  
  # Create a temporary file
  local temp_file
  temp_file=$(mktemp)
  
  # Convert CRLF to LF
  if hooks_command_exists tr; then
    tr -d '\r' < "$file" > "$temp_file"
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
      hooks_error "Failed to fix line endings in $file"
      rm -f "$temp_file"
      return $HOOKS_ERROR_GENERAL
    fi
    
    # Replace the original file with the fixed one
    mv "$temp_file" "$file"
    return $HOOKS_ERROR_SUCCESS
  else
    hooks_error "tr command not found, cannot fix line endings"
    rm -f "$temp_file"
    return $HOOKS_ERROR_COMMAND_NOT_FOUND
  fi
}

# Function to fix unused variables in Lua files by prefixing with underscore
# Usage: hooks_fix_unused_variables "file.lua"
hooks_fix_unused_variables() {
  local file="$1"
  
  if [ ! -f "$file" ]; then
    hooks_error "File not found: $file"
    return $HOOKS_ERROR_PATH_NOT_FOUND
  fi
  
  # Check if luacheck is available
  if ! hooks_command_exists luacheck; then
    hooks_warning "luacheck not found, cannot fix unused variables"
    return $HOOKS_ERROR_COMMAND_NOT_FOUND
  fi
  
  hooks_debug "Checking for unused variables in $file"
  
  # Run luacheck to find unused variables
  local unused_vars
  unused_vars=$(luacheck --no-color --codes "$file" | grep -E "W211|W212|W213" | grep -oE "[a-zA-Z0-9_]+ was defined but never used")
  
  if [ -z "$unused_vars" ]; then
    hooks_debug "No unused variables found in $file"
    return $HOOKS_ERROR_SUCCESS
  fi
  
  hooks_debug "Found unused variables: $unused_vars"
  
  # Create a temporary file
  local temp_file
  temp_file=$(mktemp)
  
  # Copy the original file
  cp "$file" "$temp_file"
  
  # Process each unused variable
  while IFS= read -r line; do
    if [ -n "$line" ]; then
      local var_name
      var_name=$(echo "$line" | awk '{print $1}')
      
      if [ -n "$var_name" ] && [[ "$var_name" != _* ]]; then
        hooks_debug "Fixing unused variable: $var_name"
        
        # Replace the variable with a prefixed version, being careful with word boundaries
        if hooks_command_exists sed; then
          sed -i "s/\b$var_name\b/_$var_name/g" "$temp_file"
        else
          hooks_error "sed command not found, cannot fix unused variables"
          rm -f "$temp_file"
          return $HOOKS_ERROR_COMMAND_NOT_FOUND
        fi
      fi
    fi
  done <<< "$unused_vars"
  
  # Replace the original file with the fixed one
  mv "$temp_file" "$file"
  return $HOOKS_ERROR_SUCCESS
}

# Function to apply all code quality fixes to a single file
# Usage: hooks_fix_file_quality "file.lua"
hooks_fix_file_quality() {
  local file="$1"
  
  if [ ! -f "$file" ]; then
    hooks_error "File not found: $file"
    return $HOOKS_ERROR_PATH_NOT_FOUND
  fi
  
  hooks_debug "Applying code quality fixes to $file"
  
  # Apply each fix
  hooks_fix_trailing_whitespace "$file"
  hooks_fix_line_endings "$file"
  hooks_ensure_final_newline "$file"
  
  # Only try to fix unused variables if it's a Lua file
  if hooks_is_lua_file "$file"; then
    hooks_fix_unused_variables "$file"
  fi
  
  return $HOOKS_ERROR_SUCCESS
}

# Function to fix code quality issues in multiple files
# Usage: hooks_fix_files_quality "file1" "file2" ...
hooks_fix_files_quality() {
  local files=("$@")
  local exit_code=0
  local fixed_count=0
  local failed_count=0
  
  if [ ${#files[@]} -eq 0 ]; then
    hooks_debug "No files to fix"
    return $HOOKS_ERROR_SUCCESS
  fi
  
  hooks_print_header "Fixing code quality issues in ${#files[@]} files"
  
  for file in "${files[@]}"; do
    hooks_fix_file_quality "$file"
    local file_exit_code=$?
    
    if [ $file_exit_code -eq 0 ]; then
      ((fixed_count++))
    else
      ((failed_count++))
      exit_code=$file_exit_code
    fi
  done
  
  if [ $fixed_count -gt 0 ]; then
    hooks_success "Fixed code quality issues in $fixed_count files"
  fi
  
  if [ $failed_count -gt 0 ]; then
    hooks_error "Failed to fix code quality issues in $failed_count files"
  fi
  
  return $exit_code
}

# Function to fix code quality issues in staged files
# Usage: hooks_fix_staged_quality
hooks_fix_staged_quality() {
  local staged_files
  staged_files=$(git diff --cached --name-only --diff-filter=ACM)
  
  if [ -z "$staged_files" ]; then
    hooks_debug "No staged files to fix"
    return $HOOKS_ERROR_SUCCESS
  fi
  
  local files_array=()
  while IFS= read -r file; do
    files_array+=("$file")
  done <<< "$staged_files"
  
  # Print what we're doing for test debugging
  hooks_debug "Fixing quality issues in ${#files_array[@]} files"
  for file in "${files_array[@]}"; do
    hooks_debug "  - $file"
  done
  
  hooks_fix_files_quality "${files_array[@]}"
  local exit_code=$?
  
  if [ $exit_code -eq 0 ]; then
    # Add the fixed files back to staging
    for file in "${files_array[@]}"; do
      git add "$file"
    done
    hooks_success "Fixed files have been staged"
  else
    hooks_error "Failed to fix some files (exit code: $exit_code)"
  fi
  
  return $exit_code
}

# Export all functions
export -f hooks_fix_trailing_whitespace
export -f hooks_ensure_final_newline
export -f hooks_fix_line_endings
export -f hooks_fix_unused_variables
export -f hooks_fix_file_quality
export -f hooks_fix_files_quality
export -f hooks_fix_staged_quality