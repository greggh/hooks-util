
# Testing Hooks-Util

This document describes the proper testing procedure for hooks-util development and validation.

## Testbed Projects

Four testbed projects have been created to validate hooks-util functionality across different adapter types:

1. **hooks-util-testbed-lua-lib**: Testing hooks-util with Lua library adapter
2. **hooks-util-testbed-nvim-plugin**: Testing hooks-util with Neovim plugin adapter
3. **hooks-util-testbed-nvim-config**: Testing hooks-util with Neovim config adapter
4. **hooks-util-testbed-docs**: Testing hooks-util with Documentation adapter

## Proper Development Workflow

When making changes to hooks-util, follow these essential steps:

1. **Make changes in the main hooks-util repository**:
   ```bash
   # Edit files in the main hooks-util directory
   vim /home/gregg/Projects/lua-library/hooks-util/lib/quality.sh

   # Commit changes to hooks-util repository
   git -C /home/gregg/Projects/lua-library/hooks-util add lib/quality.sh
   git -C /home/gregg/Projects/lua-library/hooks-util commit -m "Fix submodule detection in hooks_fix_staged_quality"
   ```

2. **Update testbed projects using proper submodule commands**:
   ```bash
   # For each testbed project, update the hooks-util submodule
   git -C /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib submodule update --init --recursive
   git -C /home/gregg/Projects/test-projects/hooks-util-testbed-nvim-plugin submodule update --init --recursive
   git -C /home/gregg/Projects/test-projects/hooks-util-testbed-nvim-config submodule update --init --recursive
   git -C /home/gregg/Projects/test-projects/hooks-util-testbed-docs submodule update --init --recursive
   ```

3. **Test the changes without using `--no-verify`**:
   ```bash
   # Create test files with issues in each testbed project
   env -C /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib ./validate-hooks.sh

   # Always let the pre-commit hook run to validate your changes
   git -C /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib add test-file.txt
   git -C /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib commit -m "Test hooks-util functionality"
   ```

## Common Mistakes to Avoid

1. **NEVER edit hooks-util files directly in testbed projects**:
   - Changes to hooks-util should only be made in the main hooks-util repository
   - Never commit hooks-util files as part of a testbed project commit

2. **NEVER use `--no-verify`**:
   - The purpose of testing is to verify that hooks work correctly
   - Using `--no-verify` bypasses hooks and defeats the purpose of testing

3. **NEVER disable checks in testbed projects**:
   - Testbed projects should use strict checking to properly validate hooks-util
   - If checks are failing, fix the underlying issues in hooks-util instead of disabling checks

4. **NEVER commit incomplete work**:
   - Make sure all hooks-util functionality works correctly before committing
   - If hooks fail, fix the issues rather than bypassing them

## Ensuring Proper Submodule Handling

Each testbed project should have hooks-util as a submodule, typically located at `.githooks/hooks-util`. When you update hooks-util in a testbed project, it should be done through proper submodule commands:

```bash

# Initialize submodules if needed
git -C /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib submodule update --init --recursive

# Force reinstall hooks after updating
env -C /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib ./.githooks/hooks-util/install.sh --force

```text

## Comprehensive Testing Strategy

### 1. Testing the Infinite Recursion Fix

To validate that the infinite recursion in the pre-commit hook has been resolved:

```bash

# 1. Set up a test file with formatting issues
echo "function  badlyFormattedFunction()  " > /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib/test-formatting.lua

# 2. Add the file to git staging
git -C /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib add test-formatting.lua

# 3. Run pre-commit with debug enabled to see if recursion occurs
env -C /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib DEBUG=1 ./.githooks/pre-commit

```text

Expected outcome: The pre-commit hook should fix formatting issues without entering an infinite loop. The debug log should show the HOOKS_PROCESSING_QUALITY flag being set to prevent recursive calls.

### 2. Testing ShellCheck Detection

To validate that shellcheck detection works reliably across environments:

```bash

# 1. Test direct detection (with PATH)
env -C /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib DEBUG=1 bash -c "source ./.githooks/hooks-util/lib/shellcheck.sh && hooks_shellcheck_available && echo \$SHELLCHECK_CMD"

# 2. Test detection with pre-commit hook
env -C /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib DEBUG=1 ./.githooks/pre-commit

# 3. Create a test script with shellcheck issues
echo "if [ $a = $b ]" > /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib/bad-script.sh
git -C /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib add bad-script.sh
env -C /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib DEBUG=1 ./.githooks/pre-commit

```text

Expected outcome: ShellCheck should be detected and used for validation. The pre-commit hook should identify shellcheck issues in the test script.

### 3. Testing Template File Handling

To validate that template files are properly created and used:

```bash

# 1. Remove existing templates to force recreation
rm -rf /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib/.githooks/hooks-util/templates/*

# 2. Reinstall hooks-util to trigger template creation
env -C /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib DEBUG=1 ./.githooks/hooks-util/install.sh --force

# 3. Verify that templates were created
ls -la /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib/.githooks/hooks-util/templates/

# 4. Verify template contents match expected strictness for testbed
cat /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib/.githooks/hooks-util/templates/yamllint.yml

```text

Expected outcome: The templates should be recreated with the appropriate strictness level for testbed projects (strict templates for testbeds, standard templates for regular projects).

### 4. Testing Each Adapter Type

#### Lua Library Adapter

```bash

# Reinstall hooks-util with the latest changes
env -C /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib DEBUG=1 /home/gregg/Projects/lua-library/hooks-util/install.sh --force

# Create test files for each format if they don't exist
touch /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib/test_lua.lua
echo "#!/bin/bash\necho 'Test script'" > /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib/test_shell.sh
echo "# Test markdown\n## Heading" > /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib/test_markdown.md
echo "---\nkey: value" > /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib/test_yaml.yml
echo '{"test": "value"}' > /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib/test_json.json
echo 'title = "Test TOML"' > /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib/test_toml.toml

# Add all files to git
git -C /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib add .

# Run pre-commit hook in debug mode
env -C /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib DEBUG=1 ./.githooks/pre-commit

```text

#### Neovim Plugin Adapter

```bash

# Run validation script if it exists
env -C /home/gregg/Projects/test-projects/hooks-util-testbed-nvim-plugin ./validate-hooks.sh

# Or perform manual validation
env -C /home/gregg/Projects/test-projects/hooks-util-testbed-nvim-plugin DEBUG=1 ./.githooks/pre-commit

```text

#### Neovim Config Adapter

```bash

# Reinstall hooks-util with the latest changes
env -C /home/gregg/Projects/test-projects/hooks-util-testbed-nvim-config DEBUG=1 /home/gregg/Projects/lua-library/hooks-util/install.sh --force

# Test pre-commit hook execution
env -C /home/gregg/Projects/test-projects/hooks-util-testbed-nvim-config DEBUG=1 ./.githooks/pre-commit

```text

#### Documentation Adapter

```bash

# Run validation script if it exists
env -C /home/gregg/Projects/test-projects/hooks-util-testbed-docs ./validate-hooks.sh

# Test markdown linting specifically
echo "# Markdown with  extra  spaces" > /home/gregg/Projects/test-projects/hooks-util-testbed-docs/test-markdown.md
git -C /home/gregg/Projects/test-projects/hooks-util-testbed-docs add test-markdown.md
env -C /home/gregg/Projects/test-projects/hooks-util-testbed-docs DEBUG=1 ./.githooks/pre-commit

```text

## Testing GitHub Workflow Fixes

To validate that GitHub workflow issues have been resolved:

1. Create a temporary branch in the hooks-util repository:
   ```bash
   git -C /home/gregg/Projects/lua-library/hooks-util checkout -b test-workflows
   ```

2. Make a small change to trigger workflows:
   ```bash
   echo "# Test comment" >> /home/gregg/Projects/lua-library/hooks-util/README.md
   git -C /home/gregg/Projects/lua-library/hooks-util add README.md
   git -C /home/gregg/Projects/lua-library/hooks-util commit -m "Test workflows"
   ```

3. Push to GitHub and monitor workflow execution:
   ```bash
   git -C /home/gregg/Projects/lua-library/hooks-util push origin test-workflows
   ```

4. Check workflow status using GitHub CLI:
   ```bash
   gh -R greggh/hooks-util workflow view
   ```

Repeat these steps for the neovim-ecosystem-docs repository to ensure all workflows are functioning correctly.

## Automated Testing Script

To simplify comprehensive testing across all adapter types, create an automated test script:

```bash
#!/bin/bash

# test_all_adapters.sh - Comprehensive test script for hooks-util

OUTPUT_DIR="./test-results"
mkdir -p "$OUTPUT_DIR"

# Function to test an adapter
test_adapter() {
  local adapter_name="$1"
  local testbed_path="$2"

  echo "==== Testing $adapter_name adapter in $testbed_path ===="

  # Install hooks-util
  echo "Installing hooks-util..."
  env -C "$testbed_path" /home/gregg/Projects/lua-library/hooks-util/install.sh --force > "$OUTPUT_DIR/$adapter_name-install.log" 2>&1

  # Check template files
  echo "Checking template files..."
  find "$testbed_path/.githooks/hooks-util/templates" -type f > "$OUTPUT_DIR/$adapter_name-templates.log" 2>&1

  # Test for infinite recursion
  echo "Testing pre-commit hook for infinite recursion..."
  # Create a test file with formatting issues
  echo "function  badlyFormattedFunction()  " > "$testbed_path/test-formatting.lua"
  git -C "$testbed_path" add test-formatting.lua
  env -C "$testbed_path" DEBUG=1 ./.githooks/pre-commit > "$OUTPUT_DIR/$adapter_name-precommit.log" 2>&1

  # Test shellcheck detection
  echo "Testing shellcheck detection..."
  env -C "$testbed_path" DEBUG=1 bash -c "source ./.githooks/hooks-util/lib/shellcheck.sh && hooks_shellcheck_available && echo \$SHELLCHECK_CMD" > "$OUTPUT_DIR/$adapter_name-shellcheck.log" 2>&1

  echo "===== Completed testing $adapter_name adapter ====="
  echo ""
}

# Test each adapter type
test_adapter "lua-lib" "/home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib"
test_adapter "nvim-plugin" "/home/gregg/Projects/test-projects/hooks-util-testbed-nvim-plugin"
test_adapter "nvim-config" "/home/gregg/Projects/test-projects/hooks-util-testbed-nvim-config"
test_adapter "docs" "/home/gregg/Projects/test-projects/hooks-util-testbed-docs"

echo "All tests completed. Results available in $OUTPUT_DIR"

```text

## Debugging Issues

When troubleshooting hooks-util, use these approaches:

1. **Enable debug mode**:
   ```bash
   env -C /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib DEBUG=1 ./.githooks/hooks-util/install.sh --force
   ```

2. **Check logs**:
   - Look for debug output in the console
   - Check for any error or warning messages

3. **Test each component separately**:
   ```bash
   # Test shellcheck detection
   env -C /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib DEBUG=1 bash -c "source ./.githooks/hooks-util/lib/shellcheck.sh && hooks_shellcheck_available && echo 'Shellcheck available'"
   ```

4. **Verify submodule setup**:
   ```bash
   git -C /home/gregg/Projects/test-projects/hooks-util-testbed-lua-lib submodule status
   ```

## Testing Specific Functionality

1. **Test submodule detection**:
   - Create a submodule in a testbed project
   - Verify that hooks-util correctly identifies and skips files in the submodule

2. **Test path resolution**:
   - Verify that hooks can correctly find tools like shellcheck
   - Test with both relative and absolute paths

3. **Test template file distribution**:
   - Delete template files and verify they are properly recreated
   - Verify that testbed projects get stricter templates

4. **Test quality checking for testbeds**:
   - Verify that testbed projects enforce strict quality requirements
   - Test that normal projects use standard quality requirements

## Comprehensive Test Checklist

- [ ] Infinite recursion fix validated across all adapter types
- [ ] Shellcheck detection working in all environments
- [ ] Template files correctly generated based on project type
- [ ] Pre-commit hooks executing without errors
- [ ] GitHub workflows succeeding without disabling checks
- [ ] All linting tools (lua, shell, markdown, yaml, json, toml) functioning

## Reporting Issues

When reporting issues, include:

1. The exact command executed
2. The complete error output 
3. Debug logs (with DEBUG=1 enabled)
4. The adapter type being tested
5. The specific functionality that failed

