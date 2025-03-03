#!/bin/bash
# Test utilities for hooks-util

# Function to assert that two values are equal
assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-Expected '$expected' but got '$actual'}"
  
  if [ "$expected" != "$actual" ]; then
    echo -e "\033[0;31mAssertion failed: $message\033[0m"
    return 1
  fi
  return 0
}

# Function to assert that a command exits with a specific code
assert_exit_code() {
  local expected="$1"
  local command="$2"
  local message="${3:-Expected exit code $expected but got $?}"
  
  eval "$command"
  local actual=$?
  
  if [ "$expected" != "$actual" ]; then
    echo -e "\033[0;31mAssertion failed: $message (got code $actual)\033[0m"
    return 1
  fi
  return 0
}

# Function to assert that a command output contains a string
assert_output_contains() {
  local needle="$1"
  local command="$2"
  local message="${3:-Expected output to contain '$needle'}"
  
  local output=$(eval "$command")
  
  if [[ "$output" != *"$needle"* ]]; then
    echo -e "\033[0;31mAssertion failed: $message\033[0m"
    echo -e "Output was: $output"
    return 1
  fi
  return 0
}

# Function to skip a test
skip_test() {
  local reason="${1:-Test skipped (no reason provided)}"
  echo -e "\033[0;33mTest skipped: $reason\033[0m"
  exit 2
}

# Export all functions
export -f assert_equals
export -f assert_exit_code
export -f assert_output_contains
export -f skip_test
