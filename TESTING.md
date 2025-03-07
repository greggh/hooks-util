# Testing Hooks-Util

This document describes the proper testing procedure for hooks-util development.

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