#!/bin/bash
# Test for common.sh functions

# Source the module to test
source "${LIB_DIR}/common.sh"

# Test hooks_command_exists
echo "Testing hooks_command_exists..."
assert_equals 0 $(hooks_command_exists "bash" && echo 0 || echo 1) "bash command should exist"
assert_equals 1 $(hooks_command_exists "non_existent_command_xyz" && echo 0 || echo 1) "non-existent command should not exist"

# Test hooks_is_lua_file
echo "Testing hooks_is_lua_file..."
assert_equals 0 $(hooks_is_lua_file "file.lua" && echo 0 || echo 1) "file.lua should be recognized as Lua file"
assert_equals 1 $(hooks_is_lua_file "file.txt" && echo 0 || echo 1) "file.txt should not be recognized as Lua file"

# Test output functions (basic smoke test)
echo "Testing output functions..."
hooks_set_verbosity 0  # Set to quiet
output=$(hooks_message "This should not be printed" 2>&1)
assert_equals "" "$output" "No output should be produced in quiet mode"

hooks_set_verbosity 2  # Set to verbose
output=$(hooks_debug "Debug message" 2>&1)
assert_output_contains "Debug" "echo \"$output\"" "Debug message should be printed in verbose mode"

# All tests passed
exit 0
