#!/bin/bash
# Test quality validation for hooks-util
# Implementation of Phase 3 integration with lust-next quality and coverage modules

# Include the necessary libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/error.sh"
source "${SCRIPT_DIR}/path.sh"
source "${SCRIPT_DIR}/test.sh"

# Path to lust-next submodule
LUST_NEXT_DIR="${SCRIPT_DIR}/../deps/lust-next"

# Function to find lust-next in the current project
# Usage: hooks_find_lust_next [project_dir]
hooks_find_lust_next() {
  local project_dir="${1:-$PWD}"
  local lust_next_paths=(
    # Direct submodule in the project
    "${project_dir}/deps/lust-next"
    # Submodule under githooks
    "${project_dir}/.githooks/hooks-util/deps/lust-next"
    # Using the copy from hooks-util
    "${LUST_NEXT_DIR}"
    # Check in other common locations
    "${project_dir}/test/lust-next"
    "${project_dir}/spec/lust-next"
    "${project_dir}/vendor/lust-next"
  )
  
  # Check each path
  for path in "${lust_next_paths[@]}"; do
    if [ -f "${path}/lust-next.lua" ]; then
      echo "${path}"
      return 0
    fi
  done
  
  return 1
}

# Function to check if lust-next has coverage capability
# Usage: hooks_lustx_has_coverage [lust_next_path]
hooks_lustx_has_coverage() {
  local lust_next_path="${1:-$(hooks_find_lust_next)}"
  
  if [ -z "$lust_next_path" ]; then
    hooks_debug "Could not find lust-next"
    return 1
  fi
  
  # Check for the coverage module
  if [ -f "${lust_next_path}/src/coverage.lua" ]; then
    hooks_debug "Found lust-next coverage module at ${lust_next_path}/src/coverage.lua"
    return 0
  else
    hooks_debug "Could not find lust-next coverage module"
    return 1
  fi
}

# Function to check if lust-next has quality capability
# Usage: hooks_lustx_has_quality [lust_next_path]
hooks_lustx_has_quality() {
  local lust_next_path="${1:-$(hooks_find_lust_next)}"
  
  if [ -z "$lust_next_path" ]; then
    hooks_debug "Could not find lust-next"
    return 1
  fi
  
  # Check for the quality module
  if [ -f "${lust_next_path}/src/quality.lua" ]; then
    hooks_debug "Found lust-next quality module at ${lust_next_path}/src/quality.lua"
    return 0
  else
    hooks_debug "Could not find lust-next quality module"
    return 1
  fi
}

# Function to find project's test directory
# Usage: hooks_find_project_test_dir [project_dir]
hooks_find_project_test_dir() {
  local project_dir="${1:-$PWD}"
  
  # Common test directory names
  local test_dirs=("tests" "test" "spec")
  
  for dir in "${test_dirs[@]}"; do
    if [ -d "${project_dir}/${dir}" ]; then
      echo "${project_dir}/${dir}"
      return 0
    fi
  done
  
  # If no dedicated test directory, check for tests in the lua directory
  if [ -d "${project_dir}/lua" ]; then
    # Check for test files in the lua directory
    if ls "${project_dir}/lua"/*{_test,_spec}.lua &> /dev/null || find "${project_dir}/lua" -name "*_test.lua" -o -name "*_spec.lua" &> /dev/null; then
      echo "${project_dir}/lua"
      return 0
    fi
  fi
  
  return 1
}

# Function to run test coverage validation using lust-next
# Usage: hooks_validate_test_coverage [project_dir] [threshold] [include_pattern] [exclude_pattern]
hooks_validate_test_coverage() {
  local project_dir="${1:-$PWD}"
  local threshold="${2:-80}"  # Default 80% coverage threshold
  local include_pattern="${3:-"*.lua"}"
  local exclude_pattern="${4:-"*_test*.lua,*_spec*.lua"}"
  
  # Find lust-next
  local lust_next_path
  lust_next_path=$(hooks_find_lust_next "$project_dir")
  
  if [ -z "$lust_next_path" ]; then
    hooks_error "Could not find lust-next installation"
    return "$HOOKS_ERROR_PATH_NOT_FOUND"
  fi
  
  # Check if lust-next has coverage capability
  if ! hooks_lustx_has_coverage "$lust_next_path"; then
    hooks_error "The installed lust-next does not have coverage capability"
    return "$HOOKS_ERROR_NOT_IMPLEMENTED"
  fi
  
  # Find the test directory
  local test_dir
  test_dir=$(hooks_find_project_test_dir "$project_dir")
  
  if [ -z "$test_dir" ]; then
    hooks_error "Could not find test directory in project"
    return "$HOOKS_ERROR_PATH_NOT_FOUND"
  fi
  
  hooks_info "Running test coverage validation (threshold: ${threshold}%)"
  
  # Create a temporary config file to set the coverage options
  local config_file
  config_file=$(mktemp)
  
  cat > "$config_file" << EOL
return {
  coverage = {
    enabled = true,
    threshold = ${threshold},
    include = {"${include_pattern}"},
    exclude = {"${exclude_pattern}"},
    format = "summary"
  }
}
EOL
  
  # Run lust-next with coverage enabled
  local lua_cmd
  if hooks_command_exists luajit; then
    lua_cmd="luajit"
  elif hooks_command_exists lua; then
    lua_cmd="lua"
  else
    hooks_error "Could not find Lua interpreter (lua or luajit)"
    rm -f "$config_file"
    return "$HOOKS_ERROR_COMMAND_NOT_FOUND"
  fi
  
  # Save original directory and change to project directory
  local original_dir="$PWD"
  cd "$project_dir" || return "$HOOKS_ERROR_PATH_NOT_FOUND"
  
  # Set up the command to run lust-next with coverage
  local command="${lua_cmd} ${lust_next_path}/lust-next.lua --coverage --coverage-threshold=${threshold} ${test_dir}"
  
  # Capture both stdout and stderr
  local temp_output
  temp_output=$(mktemp)
  
  hooks_debug "Running command: $command"
  if ! eval "$command" > "$temp_output" 2>&1; then
    local exit_code=$?
    cat "$temp_output"
    
    # Check if it failed because of coverage threshold
    if grep -q "COVERAGE BELOW THRESHOLD" "$temp_output"; then
      hooks_error "Test coverage is below the threshold of ${threshold}%"
      # Extract actual coverage value if possible
      local actual_coverage
      actual_coverage=$(grep -oE "([0-9]+\.[0-9]+% < ${threshold}\.[0-9]+%)" "$temp_output" | awk '{print $1}')
      if [ -n "$actual_coverage" ]; then
        hooks_error "Actual coverage: ${actual_coverage}"
      fi
      cd "$original_dir" || return "$HOOKS_ERROR_PATH_NOT_FOUND"
      rm -f "$config_file" "$temp_output"
      return "$HOOKS_ERROR_ASSERTION_FAILED"
    else
      hooks_error "Test coverage validation failed with exit code $exit_code"
      cd "$original_dir" || return "$HOOKS_ERROR_PATH_NOT_FOUND"
      rm -f "$config_file" "$temp_output"
      return "$HOOKS_ERROR_GENERAL"
    fi
  else
    # Print success message with actual coverage percentage
    local coverage_percentage
    coverage_percentage=$(grep -oE "Overall:[[:space:]]+.+?([0-9]+\.[0-9]+%)" "$temp_output" | grep -oE "[0-9]+\.[0-9]+%")
    if [ -n "$coverage_percentage" ]; then
      hooks_success "Test coverage validation passed (${coverage_percentage})"
    else
      hooks_success "Test coverage validation passed"
    fi
    cat "$temp_output"
  fi
  
  # Restore original directory
  cd "$original_dir" || return "$HOOKS_ERROR_PATH_NOT_FOUND"
  
  # Clean up temporary files
  rm -f "$config_file" "$temp_output"
  
  return "$HOOKS_ERROR_SUCCESS"
}

# Function to check test quality level using lust-next
# Usage: hooks_validate_test_quality [project_dir] [level] [strict]
hooks_validate_test_quality() {
  local project_dir="${1:-$PWD}"
  local quality_level="${2:-1}"  # Default level 1 (Basic)
  local strict="${3:-false}"     # Default non-strict mode
  
  # Find lust-next
  local lust_next_path
  lust_next_path=$(hooks_find_lust_next "$project_dir")
  
  if [ -z "$lust_next_path" ]; then
    hooks_error "Could not find lust-next installation"
    return "$HOOKS_ERROR_PATH_NOT_FOUND"
  fi
  
  # Check if lust-next has quality capability
  if ! hooks_lustx_has_quality "$lust_next_path"; then
    hooks_error "The installed lust-next does not have quality validation capability"
    return "$HOOKS_ERROR_NOT_IMPLEMENTED"
  fi
  
  # Find the test directory
  local test_dir
  test_dir=$(hooks_find_project_test_dir "$project_dir")
  
  if [ -z "$test_dir" ]; then
    hooks_error "Could not find test directory in project"
    return "$HOOKS_ERROR_PATH_NOT_FOUND"
  fi
  
  hooks_info "Running test quality validation (level: ${quality_level}, strict: ${strict})"
  
  # Set up strict mode flag if enabled
  local strict_flag=""
  if [ "$strict" = true ]; then
    strict_flag="--quality-strict"
  fi
  
  # Run lust-next with quality validation enabled
  local lua_cmd
  if hooks_command_exists luajit; then
    lua_cmd="luajit"
  elif hooks_command_exists lua; then
    lua_cmd="lua"
  else
    hooks_error "Could not find Lua interpreter (lua or luajit)"
    return "$HOOKS_ERROR_COMMAND_NOT_FOUND"
  fi
  
  # Save original directory and change to project directory
  local original_dir="$PWD"
  cd "$project_dir" || return "$HOOKS_ERROR_PATH_NOT_FOUND"
  
  # Set up the command to run lust-next with quality validation
  local command="${lua_cmd} ${lust_next_path}/lust-next.lua --quality --quality-level=${quality_level} ${strict_flag} ${test_dir}"
  
  # Capture both stdout and stderr
  local temp_output
  temp_output=$(mktemp)
  
  hooks_debug "Running command: $command"
  if ! eval "$command" > "$temp_output" 2>&1; then
    local exit_code=$?
    cat "$temp_output"
    
    # Check if it failed because of quality level
    if grep -q "QUALITY BELOW REQUIRED LEVEL" "$temp_output"; then
      hooks_error "Test quality is below the required level ${quality_level}"
      # Extract actual quality level if possible
      local actual_level
      actual_level=$(grep -E "Quality Level:[[:space:]]+.+? \(Level ([0-9]+) of 5\)" "$temp_output" | grep -oE "\(Level ([0-9]+) of 5\)" | grep -oE "[0-9]+")
      if [ -n "$actual_level" ]; then
        hooks_error "Actual quality level: ${actual_level} (required: ${quality_level})"
      fi
      cd "$original_dir" || return "$HOOKS_ERROR_PATH_NOT_FOUND"
      rm -f "$temp_output"
      return "$HOOKS_ERROR_ASSERTION_FAILED"
    else
      hooks_error "Test quality validation failed with exit code $exit_code"
      cd "$original_dir" || return "$HOOKS_ERROR_PATH_NOT_FOUND"
      rm -f "$temp_output"
      return "$HOOKS_ERROR_GENERAL"
    fi
  else
    # Print success message with actual quality level
    local quality_name
    quality_name=$(grep -E "Quality Level:[[:space:]]+.+? \(Level [0-9]+ of 5\)" "$temp_output" | sed -E 's/Quality Level:[[:space:]]+(.+) \(Level.*/\1/')
    local quality_number
    quality_number=$(grep -E "Quality Level:[[:space:]]+.+? \(Level ([0-9]+) of 5\)" "$temp_output" | grep -oE "\(Level ([0-9]+) of 5\)" | grep -oE "[0-9]+")
    
    if [ -n "$quality_name" ] && [ -n "$quality_number" ]; then
      hooks_success "Test quality validation passed (${quality_name}, Level ${quality_number})"
    else
      hooks_success "Test quality validation passed"
    fi
    cat "$temp_output"
  fi
  
  # Restore original directory
  cd "$original_dir" || return "$HOOKS_ERROR_PATH_NOT_FOUND"
  
  # Clean up temporary file
  rm -f "$temp_output"
  
  return "$HOOKS_ERROR_SUCCESS"
}

# Function to run both coverage and quality checks
# Usage: hooks_run_test_quality_checks [project_dir]
hooks_run_test_quality_checks() {
  local project_dir="${1:-$PWD}"
  
  # Skip if test quality validation is not enabled
  if [ "${HOOKS_TEST_QUALITY_ENABLED}" != true ]; then
    hooks_debug "Test quality validation is disabled in configuration"
    return "$HOOKS_ERROR_SUCCESS"
  fi
  
  # Get the Lua configuration file
  local lua_config_file="${project_dir}/.hooks-util.lua"
  local has_lua_config=false
  
  if [ -f "$lua_config_file" ]; then
    has_lua_config=true
    hooks_debug "Found Lua configuration file: $lua_config_file"
  else
    hooks_debug "No Lua configuration file found, using default settings"
  fi
  
  # Print header
  hooks_print_header "Validating test quality"
  
  # Get configuration values from environment or defaults
  local coverage_enabled="${HOOKS_TEST_COVERAGE_ENABLED:-false}"
  local coverage_threshold="${HOOKS_TEST_COVERAGE_THRESHOLD:-80}"
  local coverage_include="${HOOKS_TEST_COVERAGE_INCLUDE:-"*.lua"}"
  local coverage_exclude="${HOOKS_TEST_COVERAGE_EXCLUDE:-"*_test*.lua,*_spec*.lua"}"
  local quality_enabled="${HOOKS_TEST_QUALITY_ENABLED:-false}"
  local quality_level="${HOOKS_TEST_QUALITY_LEVEL:-1}"
  local quality_strict="${HOOKS_TEST_QUALITY_STRICT:-false}"
  
  # If we have a Lua config, try to extract the test quality settings from it
  if [ "$has_lua_config" = true ] && hooks_command_exists lua; then
    # Create a temporary script to extract the test_quality settings
    local temp_script
    temp_script=$(mktemp)
    
    cat > "$temp_script" << 'EOL'
local config_path = arg[1]
local config = dofile(config_path)

if not config or type(config) ~= "table" then
  os.exit(1)
end

if config.test_quality then
  local tq = config.test_quality
  
  if tq.enabled ~= nil then
    print("ENABLED=" .. tostring(tq.enabled))
  end
  
  if tq.coverage and tq.coverage.enabled ~= nil then
    print("COVERAGE_ENABLED=" .. tostring(tq.coverage.enabled))
  end
  
  if tq.coverage and tq.coverage.threshold then
    print("COVERAGE_THRESHOLD=" .. tostring(tq.coverage.threshold))
  end
  
  if tq.coverage and tq.coverage.include then
    local include_str = table.concat(tq.coverage.include, ",")
    print("COVERAGE_INCLUDE=" .. include_str)
  end
  
  if tq.coverage and tq.coverage.exclude then
    local exclude_str = table.concat(tq.coverage.exclude, ",")
    print("COVERAGE_EXCLUDE=" .. exclude_str)
  end
  
  if tq.quality and tq.quality.enabled ~= nil then
    print("QUALITY_ENABLED=" .. tostring(tq.quality.enabled))
  end
  
  if tq.quality and tq.quality.level then
    print("QUALITY_LEVEL=" .. tostring(tq.quality.level))
  end
  
  if tq.quality and tq.quality.strict ~= nil then
    print("QUALITY_STRICT=" .. tostring(tq.quality.strict))
  end
end
EOL
    
    # Run the script to extract the config
    local config_output
    config_output=$(lua "$temp_script" "$lua_config_file" 2>/dev/null)
    local extract_exit_code=$?
    
    if [ "$extract_exit_code" -eq 0 ] && [ -n "$config_output" ]; then
      hooks_debug "Successfully extracted Lua configuration"
      
      # Parse the output and override environment variables
      while IFS= read -r line; do
        if [[ "$line" == ENABLED=* ]]; then
          local value="${line#ENABLED=}"
          if [ "$value" = "true" ]; then
            HOOKS_TEST_QUALITY_ENABLED=true
          elif [ "$value" = "false" ]; then
            HOOKS_TEST_QUALITY_ENABLED=false
          fi
        elif [[ "$line" == COVERAGE_ENABLED=* ]]; then
          local value="${line#COVERAGE_ENABLED=}"
          if [ "$value" = "true" ]; then
            coverage_enabled=true
          elif [ "$value" = "false" ]; then
            coverage_enabled=false
          fi
        elif [[ "$line" == COVERAGE_THRESHOLD=* ]]; then
          coverage_threshold="${line#COVERAGE_THRESHOLD=}"
        elif [[ "$line" == COVERAGE_INCLUDE=* ]]; then
          coverage_include="${line#COVERAGE_INCLUDE=}"
        elif [[ "$line" == COVERAGE_EXCLUDE=* ]]; then
          coverage_exclude="${line#COVERAGE_EXCLUDE=}"
        elif [[ "$line" == QUALITY_ENABLED=* ]]; then
          local value="${line#QUALITY_ENABLED=}"
          if [ "$value" = "true" ]; then
            quality_enabled=true
          elif [ "$value" = "false" ]; then
            quality_enabled=false
          fi
        elif [[ "$line" == QUALITY_LEVEL=* ]]; then
          quality_level="${line#QUALITY_LEVEL=}"
        elif [[ "$line" == QUALITY_STRICT=* ]]; then
          local value="${line#QUALITY_STRICT=}"
          if [ "$value" = "true" ]; then
            quality_strict=true
          elif [ "$value" = "false" ]; then
            quality_strict=false
          fi
        fi
      done <<< "$config_output"
    else
      hooks_debug "Failed to extract Lua configuration (exit code: $extract_exit_code)"
    fi
    
    # Clean up temporary script
    rm -f "$temp_script"
  fi
  
  # Skip if test quality validation is disabled after checking config
  if [ "${HOOKS_TEST_QUALITY_ENABLED}" != true ]; then
    hooks_info "Test quality validation is disabled in configuration"
    return "$HOOKS_ERROR_SUCCESS"
  fi
  
  # Find lust-next
  local lust_next_path
  lust_next_path=$(hooks_find_lust_next "$project_dir")
  
  if [ -z "$lust_next_path" ]; then
    hooks_warning "Could not find lust-next installation - skipping test quality validation"
    return "$HOOKS_ERROR_SUCCESS"
  fi
  
  # Check for required modules
  local has_coverage=false
  local has_quality=false
  
  if hooks_lustx_has_coverage "$lust_next_path"; then
    has_coverage=true
  fi
  
  if hooks_lustx_has_quality "$lust_next_path"; then
    has_quality=true
  fi
  
  if [ "$has_coverage" = false ] && [ "$has_quality" = false ]; then
    hooks_warning "lust-next does not have coverage or quality modules - skipping test quality validation"
    return "$HOOKS_ERROR_SUCCESS"
  fi
  
  # Track overall status
  local exit_code=0
  
  # Run coverage validation if enabled and available
  if [ "$coverage_enabled" = true ] && [ "$has_coverage" = true ]; then
    hooks_validate_test_coverage "$project_dir" "$coverage_threshold" "$coverage_include" "$coverage_exclude"
    local coverage_exit_code=$?
    hooks_handle_error $coverage_exit_code "Test coverage validation failed"
    
    if [ "$coverage_exit_code" -ne 0 ]; then
      exit_code=$coverage_exit_code
    fi
  elif [ "$coverage_enabled" = true ] && [ "$has_coverage" = false ]; then
    hooks_warning "Coverage validation is enabled but lust-next does not have coverage capability"
  else
    hooks_debug "Test coverage validation is disabled in configuration"
  fi
  
  # Run quality validation if enabled and available
  if [ "$quality_enabled" = true ] && [ "$has_quality" = true ]; then
    hooks_validate_test_quality "$project_dir" "$quality_level" "$quality_strict"
    local quality_exit_code=$?
    hooks_handle_error $quality_exit_code "Test quality validation failed"
    
    if [ "$quality_exit_code" -ne 0 ]; then
      exit_code=$quality_exit_code
    fi
  elif [ "$quality_enabled" = true ] && [ "$has_quality" = false ]; then
    hooks_warning "Quality validation is enabled but lust-next does not have quality capability"
  else
    hooks_debug "Test quality validation is disabled in configuration"
  fi
  
  # Return the final status
  return "$exit_code"
}

# Export all functions
export -f hooks_find_lust_next
export -f hooks_lustx_has_coverage
export -f hooks_lustx_has_quality
export -f hooks_find_project_test_dir
export -f hooks_validate_test_coverage
export -f hooks_validate_test_quality
export -f hooks_run_test_quality_checks