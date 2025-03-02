# Testing the hooks-util Project

This document describes how to thoroughly test the hooks-util project before implementing it in your real projects.

## Running Tests

### Running All Tests

To run all integration tests at once, use the test runner script:

```bash
./scripts/run_integration_tests.sh
```

This will execute all integration tests and provide a summary of the results.

### Running Individual Tests

You can also run individual test scripts directly:

```bash
# Basic functionality test
./tests/integration/basic_test.sh

# Neovim config integration test
./tests/integration/neovim_config_test.sh

# Neovim plugin integration test
./tests/integration/plugin_test.sh
```

### Running Unit Tests

To test the shell script functions:

```bash
./scripts/run_tests.sh
```

## Test Scripts

The following test scripts are included in the project:

### 1. Basic Functionality Test

Tests the core functionality of hooks-util with a simple Git repository:

```bash
./tests/integration/basic_test.sh
```

This script:
- Sets up a test Git repository
- Creates a Lua file with intentional issues (whitespace, unused variables)
- Installs hooks-util
- Verifies that the pre-commit hook catches these issues
- Fixes the issues and verifies that the commit succeeds

### 2. Neovim Config Integration Test

Tests hooks-util with a repository that resembles a Neovim configuration:

```bash
./tests/integration/neovim_config_test.sh
```

This script:
- Creates a test repository with a Neovim config structure (lua/config, lua/plugins, etc.)
- Sets up StyLua and Luacheck configurations
- Creates a Lua file with formatting and linting issues
- Verifies that the pre-commit hook catches these issues
- Fixes the issues and verifies that the commit succeeds

### 3. Neovim Plugin Integration Test

Tests hooks-util with a repository that resembles a Neovim plugin:

```bash
./tests/integration/plugin_test.sh
```

This script:
- Creates a test repository with a Neovim plugin structure (lua/plugin-name, tests/spec, etc.)
- Sets up StyLua, Luacheck, and test configurations
- Creates Lua files with formatting and linting issues
- Verifies that the pre-commit hook catches these issues
- Fixes the issues and verifies that the commit succeeds

## Shell Script Unit Tests

The project also includes unit tests for the shell script functions:

```bash
/home/gregg/Projects/hooks-util/scripts/run_tests.sh
```

These tests verify the behavior of individual functions in the utility libraries.

## Manual Testing Checklist

Before implementing hooks-util in your real projects, perform these manual checks:

1. **Installation Testing**:
   - [ ] Install as a Git submodule
   - [ ] Install via direct download
   - [ ] Verify hooks are properly installed in `.git/hooks`

2. **Configuration Testing**:
   - [ ] Test with default configuration
   - [ ] Test with custom .hooksrc settings
   - [ ] Test with .hooksrc.local and .hooksrc.user overrides

3. **Tool Integration Testing**:
   - [ ] Verify StyLua formatting works correctly
   - [ ] Verify Luacheck linting works correctly
   - [ ] Verify test execution works (if applicable)
   - [ ] Verify code quality fixes work (whitespace, line endings, etc.)

4. **Edge Case Testing**:
   - [ ] Test with non-Lua files in the repository
   - [ ] Test with missing tools (StyLua, Luacheck)
   - [ ] Test with syntax errors in configuration files
   - [ ] Test with very large files

## Implementation in Real Projects

To implement hooks-util in your actual projects:

1. Add hooks-util as a Git submodule:
   ```bash
   cd /path/to/your/project
   git submodule add https://github.com/greggh/hooks-util.git .hooks-util
   ```

2. Install the hooks:
   ```bash
   cd .hooks-util
   ./install.sh
   ```

3. Create a .hooksrc configuration file in your project root:
   ```bash
   cp .hooks-util/templates/hooksrc.template .hooksrc
   ```

4. Customize the configuration as needed for your project.

5. Create StyLua and Luacheck configuration files if they don't already exist:
   ```bash
   cp .hooks-util/examples/.stylua.toml .
   cp .hooks-util/examples/.luacheckrc .
   ```

6. Start working with your project as normal - the hooks will run automatically on commit.

## Troubleshooting

If you encounter issues with the hooks:

1. Increase verbosity in your .hooksrc file:
   ```
   HOOKS_VERBOSITY=2
   ```

2. Check if tools are properly installed and in your PATH:
   ```bash
   which stylua
   which luacheck
   ```

3. Verify that your configuration files are valid.

4. Run the hooks manually to debug:
   ```bash
   .git/hooks/pre-commit
   ```

5. If necessary, bypass the hooks temporarily:
   ```bash
   git commit --no-verify -m "Emergency commit message"
   ```