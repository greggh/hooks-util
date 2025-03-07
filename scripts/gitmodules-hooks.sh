#!/bin/bash
# This file contains custom hooks for .gitmodules
# It should be sourced by your shell initialization script (e.g. .bashrc, .zshrc)

# Define a function to wrap git commands that handle submodules
git_with_hooks() {
  # Capture the original command
  local original_command="$@"
  
  # Execute the original git command
  git "$@"
  result=$?
  
  # Check if this was a submodule update command
  if [[ "$1" == "submodule" && ("$2" == "update" || "$2" == "init") ]]; then
    echo "Running post-submodule-update hooks..."
    
    # Find the root of the repository
    local repo_root=$(git rev-parse --show-toplevel)
    
    # Run the post-submodule-update hook if it exists
    if [ -x "$repo_root/.githooks/post-submodule-update" ]; then
      "$repo_root/.githooks/post-submodule-update"
    fi
  fi
  
  return $result
}

# Instructions:
# Add these lines to your shell config (e.g., ~/.bashrc or ~/.zshrc):
# 
# source "/path/to/your/repo/hooks-util/scripts/gitmodules-hooks.sh"
# alias git=git_with_hooks
#
# Replace "/path/to/your/repo" with the actual path to your repository.
#
# Usage example:
# $ git submodule update  # Will run post-submodule-update hook afterwards