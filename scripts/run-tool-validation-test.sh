#!/bin/bash
# Wrapper script to run the tool validation test without showing post-cleanup errors

# Run the test and capture output
HOOKS_VERBOSITY=2 /home/gregg/Projects/hooks-util/tests/integration/tool_validation_test.sh 2>&1 | 
  grep -v "line 9: cd:" |  # Filter out the specific error
  grep -v "No such file or directory"  # Filter out directory not found errors

# Use the exit code from the test, not from grep
exit ${PIPESTATUS[0]}