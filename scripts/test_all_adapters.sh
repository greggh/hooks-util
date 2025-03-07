#!/bin/bash
# test_all_adapters.sh - Comprehensive test script for hooks-util
#
# This script automates the testing of hooks-util across all adapter types,
# specifically focusing on validating the fixes for:
# 1. Infinite recursion in pre-commit hook
# 2. ShellCheck detection
# 3. Template file handling
# 4. Pre-commit hook functionality with all linting tools

set -e

# Create output directory
OUTPUT_DIR="./test-results"
mkdir -p "$OUTPUT_DIR"

# Print with color
print_header() {
  echo -e "\033[1;36m==== $1 ====\033[0m"
}

print_subheader() {
  echo -e "\033[1;34m--- $1 ---\033[0m"
}

print_success() {
  echo -e "\033[1;32m✓ $1\033[0m"
}

print_warning() {
  echo -e "\033[1;33m⚠ $1\033[0m"
}

print_error() {
  echo -e "\033[1;31m✗ $1\033[0m"
}

# Function to test an adapter
test_adapter() {
  local adapter_name="$1"
  local testbed_path="$2"
  
  print_header "Testing $adapter_name adapter in $testbed_path"
  
  # Verify testbed exists
  if [ ! -d "$testbed_path" ]; then
    print_error "Testbed path does not exist: $testbed_path"
    return 1
  fi
  
  # Install hooks-util
  print_subheader "Installing hooks-util..."
  env -C "$testbed_path" $(pwd)/install.sh --force > "$OUTPUT_DIR/$adapter_name-install.log" 2>&1
  if [ $? -eq 0 ]; then
    print_success "Hooks-util installed successfully"
  else
    print_error "Hooks-util installation failed! See $OUTPUT_DIR/$adapter_name-install.log for details"
  fi
  
  # Check template files
  print_subheader "Checking template files..."
  find "$testbed_path/.githooks/hooks-util/templates" -type f > "$OUTPUT_DIR/$adapter_name-templates.log" 2>&1
  template_count=$(cat "$OUTPUT_DIR/$adapter_name-templates.log" | wc -l)
  if [ "$template_count" -ge 4 ]; then
    print_success "Found $template_count template files"
  else
    print_warning "Only found $template_count template files (expected at least 4)"
  fi
  
  # Create test files for all formats if they don't exist
  print_subheader "Creating test files..."
  echo "function  badlyFormattedFunction()  " > "$testbed_path/test-formatting.lua"
  echo "#!/bin/bash\necho 'Test script'" > "$testbed_path/test-shell.sh"
  echo "# Test markdown\n## Heading" > "$testbed_path/test-markdown.md"
  echo "---\nkey: value" > "$testbed_path/test-yaml.yml"
  echo '{"test": "value"}' > "$testbed_path/test-json.json"
  echo 'title = "Test TOML"' > "$testbed_path/test-toml.toml"
  
  # Add all files to git
  print_subheader "Adding test files to git..."
  git -C "$testbed_path" add .

  # Test for infinite recursion
  print_subheader "Testing pre-commit hook for infinite recursion..."
  env -C "$testbed_path" DEBUG=1 ./.githooks/pre-commit > "$OUTPUT_DIR/$adapter_name-precommit.log" 2>&1
  precommit_exit_code=$?
  
  # Check for HOOKS_PROCESSING_QUALITY flag in the log
  if grep -q "HOOKS_PROCESSING_QUALITY" "$OUTPUT_DIR/$adapter_name-precommit.log"; then
    print_success "HOOKS_PROCESSING_QUALITY flag detected (prevents recursion)"
  else
    print_warning "HOOKS_PROCESSING_QUALITY flag not found in logs"
  fi
  
  # Look for recursion errors
  if grep -q "Maximum recursion depth exceeded" "$OUTPUT_DIR/$adapter_name-precommit.log"; then
    print_error "Found recursion error in pre-commit output"
  else
    print_success "No recursion errors detected"
  fi
  
  # Report pre-commit hook result
  if [ $precommit_exit_code -eq 0 ]; then
    print_success "Pre-commit hook executed successfully"
  else
    print_warning "Pre-commit hook failed with exit code $precommit_exit_code"
  fi
  
  # Test shellcheck detection
  print_subheader "Testing shellcheck detection..."
  env -C "$testbed_path" DEBUG=1 bash -c "source ./.githooks/hooks-util/lib/shellcheck.sh && hooks_shellcheck_available && echo \$SHELLCHECK_CMD" > "$OUTPUT_DIR/$adapter_name-shellcheck.log" 2>&1
  
  if grep -q "shellcheck" "$OUTPUT_DIR/$adapter_name-shellcheck.log"; then
    print_success "ShellCheck detected: $(grep "shellcheck" "$OUTPUT_DIR/$adapter_name-shellcheck.log" | tail -1)"
  else
    print_warning "ShellCheck not detected"
  fi
  
  print_header "Completed testing $adapter_name adapter"
  echo ""
}

# Main script execution
print_header "Starting comprehensive testing of hooks-util across all adapter types"
echo "Results will be available in $OUTPUT_DIR"
echo ""

# Test each adapter type
test_adapter "lua-lib" "/home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib"
test_adapter "nvim-plugin" "/home/gregg/Projects/test-projects/hooks-util-testbed-nvim-plugin" 
test_adapter "nvim-config" "/home/gregg/Projects/test-projects/hooks-util-testbed-nvim-config"
test_adapter "docs" "/home/gregg/Projects/test-projects/hooks-util-testbed-docs"

print_header "All tests completed"
echo "Detailed logs available in $OUTPUT_DIR"

# Create a summary report
cat > "$OUTPUT_DIR/summary.md" << EOF
# Hooks-Util Test Summary

## Test Environment
- Date: $(date)
- Hooks-Util Version: $(git -C $(pwd) rev-parse --short HEAD)

## Test Results

### Lua Library Adapter
- Installation: $(if grep -q "success" "$OUTPUT_DIR/lua-lib-install.log"; then echo "✅ Success"; else echo "❌ Failure"; fi)
- Templates: $(cat "$OUTPUT_DIR/lua-lib-templates.log" | wc -l) files found
- Recursion Protection: $(if grep -q "HOOKS_PROCESSING_QUALITY" "$OUTPUT_DIR/lua-lib-precommit.log"; then echo "✅ Working"; else echo "⚠️ Not detected"; fi)
- ShellCheck Detection: $(if grep -q "shellcheck" "$OUTPUT_DIR/lua-lib-shellcheck.log"; then echo "✅ Detected"; else echo "⚠️ Not found"; fi)

### Neovim Plugin Adapter
- Installation: $(if grep -q "success" "$OUTPUT_DIR/nvim-plugin-install.log"; then echo "✅ Success"; else echo "❌ Failure"; fi)
- Templates: $(cat "$OUTPUT_DIR/nvim-plugin-templates.log" | wc -l) files found
- Recursion Protection: $(if grep -q "HOOKS_PROCESSING_QUALITY" "$OUTPUT_DIR/nvim-plugin-precommit.log"; then echo "✅ Working"; else echo "⚠️ Not detected"; fi)
- ShellCheck Detection: $(if grep -q "shellcheck" "$OUTPUT_DIR/nvim-plugin-shellcheck.log"; then echo "✅ Detected"; else echo "⚠️ Not found"; fi)

### Neovim Config Adapter
- Installation: $(if grep -q "success" "$OUTPUT_DIR/nvim-config-install.log"; then echo "✅ Success"; else echo "❌ Failure"; fi)
- Templates: $(cat "$OUTPUT_DIR/nvim-config-templates.log" | wc -l) files found
- Recursion Protection: $(if grep -q "HOOKS_PROCESSING_QUALITY" "$OUTPUT_DIR/nvim-config-precommit.log"; then echo "✅ Working"; else echo "⚠️ Not detected"; fi)
- ShellCheck Detection: $(if grep -q "shellcheck" "$OUTPUT_DIR/nvim-config-shellcheck.log"; then echo "✅ Detected"; else echo "⚠️ Not found"; fi)

### Documentation Adapter
- Installation: $(if grep -q "success" "$OUTPUT_DIR/docs-install.log"; then echo "✅ Success"; else echo "❌ Failure"; fi)
- Templates: $(cat "$OUTPUT_DIR/docs-templates.log" | wc -l) files found
- Recursion Protection: $(if grep -q "HOOKS_PROCESSING_QUALITY" "$OUTPUT_DIR/docs-precommit.log"; then echo "✅ Working"; else echo "⚠️ Not detected"; fi)
- ShellCheck Detection: $(if grep -q "shellcheck" "$OUTPUT_DIR/docs-shellcheck.log"; then echo "✅ Detected"; else echo "⚠️ Not found"; fi)

## Issues Found

$(grep -l "error" "$OUTPUT_DIR"/*.log | while read file; do echo "- Issue in $(basename "$file"): $(grep "error" "$file" | head -1)"; done)

## Recommendations

1. Verify any failed tests manually using commands in TESTING.md
2. Address any shellcheck detection issues across environments 
3. Ensure template files are generated with correct strictness levels
EOF

print_success "Summary report created at $OUTPUT_DIR/summary.md"