#!/bin/bash
# Markdown validation utilities for Neovim Hooks Utilities

# Include the necessary libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/error.sh"
source "${SCRIPT_DIR}/path.sh"

# Function to get all staged Markdown files
# Usage: hooks_get_staged_markdown_files
hooks_get_staged_markdown_files() {
  git diff --cached --name-only --diff-filter=ACM | grep -E '\.md$'
}

# Function to fix Markdown files using the available scripts
# Usage: hooks_fix_markdown_file "file.md"
hooks_fix_markdown_file() {
  local file="$1"
  
  if [ ! -f "$file" ]; then
    hooks_error "File not found: $file"
    return "$HOOKS_ERROR_PATH_NOT_FOUND"
  fi
  
  hooks_debug "Fixing Markdown formatting in $file"

  # Check if markdown fixing scripts exist
  local markdown_scripts_dir="${SCRIPT_DIR}/../scripts/markdown"
  
  # If the comprehensive script exists, use it
  if [ -f "${markdown_scripts_dir}/fix_markdown_comprehensive.sh" ]; then
    hooks_debug "Using comprehensive Markdown fixing script"
    "${markdown_scripts_dir}/fix_markdown_comprehensive.sh" "$file"
    return $?
  else
    # Otherwise try the individual scripts
    hooks_debug "Using individual Markdown fixing scripts"
    
    # Apply each available script
    if [ -f "${markdown_scripts_dir}/fix_newlines.sh" ]; then
      "${markdown_scripts_dir}/fix_newlines.sh" "$file"
    fi
    
    if [ -f "${markdown_scripts_dir}/fix_list_numbering.sh" ]; then
      "${markdown_scripts_dir}/fix_list_numbering.sh" "$file"
    fi
    
    if [ -f "${markdown_scripts_dir}/fix_heading_levels.sh" ]; then
      "${markdown_scripts_dir}/fix_heading_levels.sh" "$file"
    fi
    
    if [ -f "${markdown_scripts_dir}/fix_code_blocks.sh" ]; then
      "${markdown_scripts_dir}/fix_code_blocks.sh" "$file"
    fi
  fi
  
  return "$HOOKS_ERROR_SUCCESS"
}

# Function to check Markdown files for linting issues
# Usage: hooks_markdown_lint "file.md"
hooks_markdown_lint() {
  local file="$1"
  
  if [ ! -f "$file" ]; then
    hooks_error "File not found: $file"
    return "$HOOKS_ERROR_PATH_NOT_FOUND"
  fi
  
  # Check for markdown config file
  local md_config="${TARGET_DIR:-$PWD}/.markdownlint.json"
  local md_config_arg=""
  
  if [ -f "${md_config}" ]; then
    hooks_debug "Using markdownlint config at ${md_config}"
    md_config_arg="--config ${md_config}"
  else
    # Check if config exists in templates directory
    local template_config="${SCRIPT_DIR}/../templates/.markdownlint.json"
    if [ -f "${template_config}" ]; then
      hooks_debug "Using template markdownlint config"
      md_config_arg="--config ${template_config}"
    else
      hooks_debug "Using default markdownlint config"
    fi
  fi
  
  # Check if markdownlint-cli or markdownlint is available
  if hooks_command_exists markdownlint-cli; then
    hooks_debug "Using markdownlint-cli to lint $file"
    if [ -n "${md_config_arg}" ]; then
      markdownlint-cli ${md_config_arg} "$file"
    else
      markdownlint-cli "$file"
    fi
    return $?
  elif hooks_command_exists markdownlint; then
    hooks_debug "Using markdownlint to lint $file"
    if [ -n "${md_config_arg}" ]; then
      markdownlint ${md_config_arg} "$file"
    else
      markdownlint "$file"
    fi
    return $?
  else
    hooks_warning "Markdown linting tools not found. Skipping linting for $file"
    return "$HOOKS_ERROR_SUCCESS"  # Return success to allow hook to continue
  fi
}

# Function to fix and lint all staged Markdown files
# Usage: hooks_markdown_staged
hooks_markdown_staged() {
  # Get all staged Markdown files
  local markdown_files
  markdown_files=$(hooks_get_staged_markdown_files)
  
  if [ -z "$markdown_files" ]; then
    hooks_debug "No staged Markdown files to process"
    return "$HOOKS_ERROR_SUCCESS"
  fi
  
  hooks_debug "Processing Markdown files: $markdown_files"
  
  # Process each file
  local exit_code=0
  while read -r file; do
    if [ -n "$file" ]; then
      # Fix markdown formatting issues
      hooks_fix_markdown_file "$file"
      local fix_exit_code=$?
      
      if [ "$fix_exit_code" -ne 0 ]; then
        hooks_warning "Failed to fix Markdown formatting in $file"
      fi
      
      # Lint markdown files
      hooks_markdown_lint "$file"
      local lint_exit_code=$?
      
      if [ "$lint_exit_code" -ne 0 ]; then
        hooks_error "Markdown linting failed for $file"
        exit_code=$lint_exit_code
      fi
      
      # Add fixed file back to staging
      git add "$file"
    fi
  done <<< "$markdown_files"
  
  return "$exit_code"
}

# Export all functions
export -f hooks_get_staged_markdown_files
export -f hooks_fix_markdown_file
export -f hooks_markdown_lint
export -f hooks_markdown_staged