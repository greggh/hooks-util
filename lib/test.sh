#!/bin/bash
# Test integration for Neovim Hooks Utilities

# Include the necessary libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/error.sh"
source "${SCRIPT_DIR}/path.sh"

# Function to detect the test framework used in a project
# Usage: hooks_detect_test_framework [project_dir]
hooks_detect_test_framework() {
  local project_dir="${1:-$PWD}"
  
  # Check for plenary.nvim in plugins directory or dependencies
  local plenary_present=false
  if grep -q "plenary.nvim" "${project_dir}/lua/plugins" 2>/dev/null; then
    plenary_present=true
  fi
  
  # Check for Makefile test targets
  local makefile_has_test=false
  if [ -f "${project_dir}/Makefile" ]; then
    if grep -q "^test:" "${project_dir}/Makefile"; then
      makefile_has_test=true
    fi
  fi
  
  # Check for minimal-init.lua or minimal_init.lua in test directory
  local minimal_init_file=""
  if [ -f "${project_dir}/tests/minimal-init.lua" ]; then
    minimal_init_file="${project_dir}/tests/minimal-init.lua"
  elif [ -f "${project_dir}/tests/minimal_init.lua" ]; then
    minimal_init_file="${project_dir}/tests/minimal_init.lua"
  elif [ -f "${project_dir}/test/minimal-init.lua" ]; then
    minimal_init_file="${project_dir}/test/minimal-init.lua"
  elif [ -f "${project_dir}/test/minimal_init.lua" ]; then
    minimal_init_file="${project_dir}/test/minimal_init.lua"
  fi
  
  # Determine the test framework
  local test_framework="unknown"
  
  if [ "$makefile_has_test" = true ]; then
    test_framework="makefile"
  elif [ "$plenary_present" = true ] && [ -n "$minimal_init_file" ]; then
    test_framework="plenary"
  elif [ -d "${project_dir}/tests/spec" ] || [ -d "${project_dir}/test/spec" ]; then
    test_framework="busted"
  fi
  
  hooks_debug "Detected test framework: $test_framework"
  
  # Output the detected test framework and minimal init file
  echo "${test_framework}|${minimal_init_file}"
}

# Function to find the test directory
# Usage: hooks_find_test_dir [project_dir]
hooks_find_test_dir() {
  local project_dir="${1:-$PWD}"
  
  # Common test directory names
  local test_dirs=("tests" "test" "spec")
  
  for dir in "${test_dirs[@]}"; do
    if [ -d "${project_dir}/${dir}" ]; then
      echo "${project_dir}/${dir}"
      return 0
    fi
  done
  
  # If we can't find a test directory, return nothing
  return 1
}

# Function to find all test files
# Usage: hooks_find_test_files [test_dir]
hooks_find_test_files() {
  local test_dir="${1:-$(hooks_find_test_dir "$PWD")}"
  
  if [ -z "$test_dir" ]; then
    hooks_error "No test directory found"
    return 1
  fi
  
  # Use find to locate all Lua files in the test directory that contain "spec" or "test" in the name
  find "$test_dir" -type f -name "*spec*.lua" -o -name "*test*.lua" 2>/dev/null | sort
}

# Function to run Neovim tests with Plenary
# Usage: hooks_run_plenary_tests [minimal_init_file] [test_pattern]
hooks_run_plenary_tests() {
  local minimal_init_file="$1"
  local test_pattern="${2:-lua/.*_spec\.lua}"
  local timeout="${HOOKS_TEST_TIMEOUT:-60000}"
  
  hooks_debug "Running Plenary tests with pattern: $test_pattern"
  hooks_debug "Using timeout: $timeout ms"
  
  local nvim_cmd="nvim"
  if ! hooks_command_exists nvim; then
    hooks_error "Neovim not found, cannot run tests"
    return "$HOOKS_ERROR_COMMAND_NOT_FOUND"
  fi
  
  # Use the minimal init file if provided, otherwise try to find it
  if [ -z "$minimal_init_file" ]; then
    local framework_info
    framework_info=$(hooks_detect_test_framework)
    minimal_init_file=$(echo "$framework_info" | cut -d'|' -f2)
    
    if [ -z "$minimal_init_file" ]; then
      # Try common locations for minimal init file
      local project_dir="${PWD}"
      if [ -f "${project_dir}/tests/minimal-init.lua" ]; then
        minimal_init_file="${project_dir}/tests/minimal-init.lua"
      elif [ -f "${project_dir}/tests/minimal_init.lua" ]; then
        minimal_init_file="${project_dir}/tests/minimal_init.lua"
      fi
    fi
  fi
  
  if [ -n "$minimal_init_file" ]; then
    hooks_debug "Using minimal init file: $minimal_init_file"
    nvim_cmd="$nvim_cmd --headless -u $minimal_init_file"
  else
    hooks_debug "No minimal init file found, using empty init"
    nvim_cmd="$nvim_cmd --headless -u NONE"
  fi
  
  # Construct the test command
  local test_cmd="$nvim_cmd -c \"PlenaryBustedDirectory $test_pattern { minimal_init = '$minimal_init_file' }\" -c \"lua require('plenary.busted').teardown()\" -c qa"
  
  # Run the tests with timeout
  hooks_debug "Running command: $test_cmd"
  bash -c "set -o pipefail; $test_cmd 2>&1" | tee test_output.log
  local exit_code=$?
  
  # Check for failures
  if [ "$exit_code" -ne 0 ]; then
    hooks_error "Tests failed (Exit code: $exit_code)"
    if [ -f test_output.log ]; then
      grep -E "^FAILED|^Error" test_output.log | hooks_error
      rm test_output.log
    fi
    return "$HOOKS_ERROR_TESTS_FAILED"
  else
    hooks_success "All tests passed"
    if [ -f test_output.log ]; then
      rm test_output.log
    fi
    return "$HOOKS_ERROR_SUCCESS"
  fi
}

# Function to run tests using Makefile
# Usage: hooks_run_makefile_tests [project_dir]
hooks_run_makefile_tests() {
  local project_dir="${1:-$PWD}"
  local timeout="${HOOKS_TEST_TIMEOUT:-60000}"
  
  hooks_debug "Using timeout: $timeout ms"
  
  # Check if Makefile exists and has a test target
  if [ ! -f "${project_dir}/Makefile" ]; then
    hooks_error "Makefile not found in $project_dir"
    return "$HOOKS_ERROR_PATH_NOT_FOUND"
  fi
  
  if ! grep -q "^test:" "${project_dir}/Makefile"; then
    hooks_error "No test target found in Makefile"
    return "$HOOKS_ERROR_GENERAL"
  fi
  
  # Run the tests
  hooks_debug "Running tests with Makefile"
  (cd "$project_dir" && make test)
  local exit_code=$?
  
  if [ "$exit_code" -ne 0 ]; then
    hooks_error "Tests failed (Exit code: $exit_code)"
    return "$HOOKS_ERROR_TESTS_FAILED"
  else
    hooks_success "All tests passed"
    return "$HOOKS_ERROR_SUCCESS"
  fi
}

# Function to run Neovim tests
# Usage: hooks_run_tests [project_dir]
hooks_run_tests() {
  local project_dir="${1:-$PWD}"
  
  # Detect the test framework
  local framework_info
  framework_info=$(hooks_detect_test_framework "$project_dir")
  local framework
  framework=$(echo "$framework_info" | cut -d'|' -f1)
  local minimal_init_file
  minimal_init_file=$(echo "$framework_info" | cut -d'|' -f2)
  
  hooks_print_header "Running tests for project at $project_dir"
  
  case "$framework" in
    "plenary")
      hooks_run_plenary_tests "$minimal_init_file"
      ;;
    "makefile")
      hooks_run_makefile_tests "$project_dir"
      ;;
    "busted")
      hooks_error "Busted test framework not implemented yet"
      return "$HOOKS_ERROR_GENERAL"
      ;;
    *)
      hooks_error "Unknown or unsupported test framework"
      return "$HOOKS_ERROR_GENERAL"
      ;;
  esac
}

# Function to run project tests in pre-commit
# Usage: hooks_run_tests_precommit
hooks_run_tests_precommit() {
  local project_dir="${1:-$PWD}"
  
  # Skip tests if not enabled
  if [ "${HOOKS_TESTS_ENABLED}" != true ]; then
    hooks_debug "Tests are disabled in configuration"
    return "$HOOKS_ERROR_SUCCESS"
  fi
  
  # For testbed projects, just warn instead of failing if tests don't exist
  if [[ "${project_dir}" == *"testbed"* ]]; then
    hooks_warning "Testbed project detected - tests will be skipped if framework not found"
    
    # Detect the test framework
    local framework_info
    framework_info=$(hooks_detect_test_framework "$project_dir")
    local framework
    framework=$(echo "$framework_info" | cut -d'|' -f1)
    
    # If no valid framework detected in testbed, just return success
    if [ "$framework" = "unknown" ]; then
      hooks_warning "No test framework detected in testbed project, skipping tests"
      return "$HOOKS_ERROR_SUCCESS"
    fi
  fi
  
  # Run the tests
  hooks_run_tests "$project_dir"
  local exit_code=$?
  
  # For testbed projects, don't fail the commit even if tests fail
  if [[ "${project_dir}" == *"testbed"* ]] && [ "$exit_code" -ne 0 ]; then
    hooks_warning "Tests failed in testbed project, but allowing commit to proceed"
    return "$HOOKS_ERROR_SUCCESS"
  fi
  
  return "$exit_code"
}

# Export all functions
export -f hooks_detect_test_framework
export -f hooks_find_test_dir
export -f hooks_find_test_files
export -f hooks_run_plenary_tests
export -f hooks_run_makefile_tests
export -f hooks_run_tests
export -f hooks_run_tests_precommit