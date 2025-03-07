<div align="center">

# Neovim Hooks Utilities

[![GitHub License](https://img.shields.io/github/license/greggh/hooks-util?style=flat-square)](https://github.com/greggh/hooks-util/blob/main/LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/greggh/hooks-util?style=flat-square)](https://github.com/greggh/hooks-util/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/greggh/hooks-util?style=flat-square)](https://github.com/greggh/hooks-util/issues)
[![CI](https://img.shields.io/github/actions/workflow/status/greggh/hooks-util/ci.yml?branch=main&style=flat-square&logo=github)](https://github.com/greggh/hooks-util/actions/workflows/ci.yml)
[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Version](https://img.shields.io/badge/Version-0.6.0-blue?style=flat-square)](https://github.com/greggh/hooks-util/releases/tag/v0.6.0)
[![Docs](https://img.shields.io/badge/docs-passing-success?style=flat-square)](https://github.com/greggh/hooks-util/actions/workflows/docs.yml)

*A standardized Git hook framework for Lua-based Neovim projects with powerful error handling and code quality tools*

[Features](#features) •
[Installation](#installation) •
[Usage](#usage) •
[Community](#community) •
[Contributing](#contributing) •
[License](#license)

</div>

## Overview

This library provides standardized Git hook functionality for Neovim Lua projects, with a focus on:

1. **Enhanced Error Handling** - Better error messages and fallback mechanisms
2. **Improved Path Handling** - Cross-platform path resolution and environment variable support
3. **Shared Core Utilities** - Common functionality for pre-commit tasks

The primary tools supported are:

- **StyLua** - Lua code formatter designed for Neovim configurations
- **Luacheck** - Lua static analyzer and linter
- **ShellCheck** - Shell script static analysis tool
- **Markdownlint** - Markdown linting and fixing
- **Yamllint** - YAML validation
- **JSON/TOML Linting** - Configuration file validation
- **GitHub Workflow Management** - Standardized CI/CD workflows
- **Neovim Test Framework** - For running plugin and configuration tests
- **Code Quality Tools** - Fix common code issues automatically

## Features

- **Configurable Tool Paths** - Set custom paths for StyLua, Luacheck, ShellCheck, etc.
- **Cross-platform Support** - Works consistently on Linux, macOS, and Windows
- **Fallback Mechanisms** - Graceful degradation when tools are missing
- **Standardized Output Format** - Consistent, colorized messages across all hooks
- **Verbose Debug Mode** - Detailed output for troubleshooting
- **Test Integration** - Standardized test execution and reporting
- **Robust Test Framework** - Comprehensive tests for various scenarios
- **Automatic Code Quality Fixes** - Fix common issues like trailing whitespace and line endings
- **Layered Configuration** - Machine and user-specific configuration options
- **Framework Auto-detection** - Automatically detects project structure and testing frameworks
- **Documentation Linting** - Comprehensive markdown, YAML, JSON, and TOML validation
- **Adapter Architecture** - Project-specific adapters for different project types:
  - Neovim Plugin projects
  - Neovim Configuration projects
  - Lua Library projects
  - Documentation projects
- **GitHub Workflow Management** - Base + adapter workflow templates for CI/CD
- **Submodule Update Mechanism** - Automatically update hooks when the submodule is updated
- **Backup System** - Automatically backup files before updating them

## Installation

### Option 1: Git Submodule (Recommended)

```bash
git submodule add https://github.com/greggh/hooks-util.git .hooks-util
cd .hooks-util
./install.sh
```

### Option 2: Direct download

```bash
mkdir -p .hooks-util
curl -L https://github.com/greggh/hooks-util/releases/download/v0.2.1/hooks-util-0.2.1.zip -o hooks-util.zip
unzip hooks-util.zip -d .hooks-util
cd .hooks-util
./install.sh
```

## Usage

After installation, the pre-commit hooks in your repository will automatically use the shared utilities.

### Configuration

Hooks-util supports two configuration methods: the traditional shell-based config and a new Lua-based config.

#### Shell-Based Configuration

Create a `.hooksrc` file in your project root to customize hook behavior:

```bash
# .hooksrc - Hook configuration
STYLUA_ENABLED=true           # Enable StyLua formatting
LUACHECK_ENABLED=true         # Enable Luacheck linting
TESTS_ENABLED=true            # Enable test runner
QUALITY_ENABLED=true          # Enable code quality fixes
TEST_TIMEOUT=60000            # 60 seconds test timeout
VERBOSITY=1                   # 0=quiet, 1=normal, 2=verbose
SHELLCHECK_SEVERITY="error"   # ShellCheck severity level
```

#### Lua-Based Configuration (Recommended)

Create a `.hooks-util.lua` file in your project root for more advanced configuration:

```lua
-- hooks-util.lua configuration file
return {
  -- Project type configuration
  -- Valid values:
  --   "auto"           - Automatically detect project type (default)
  --   "neovim-plugin"  - Neovim plugin project
  --   "neovim-config"  - Neovim configuration directory
  --   "lua-lib"        - Lua library
  --   "lua-project"    - Generic Lua project
  project_type = "auto", -- Will auto-detect, change only if detection is incorrect

  -- Configure which hooks should be run on pre-commit
  hooks = {
    pre_commit = {
      lint = true,       -- Run linting (luacheck, etc.)
      format = true,     -- Run formatting (stylua, etc.)
      test = true,       -- Run tests
    }
  },

  -- Testing configuration
  test = {
    framework = "lust-next",             -- Test framework to use
    runner = "spec/runner.lua",          -- Path to test runner
    timeout = 60000,                     -- Test timeout in milliseconds
  },

  -- Linting configuration
  lint = {
    luacheck = {
      enabled = true,
      config_file = ".luacheckrc",
    },
    stylua = {
      enabled = true,
      config_file = "stylua.toml",
    }
  }
}
```

### Project Type Detection and Adapters

Hooks-util features an adapter-based architecture that automatically detects your project type and applies specialized validations and workflows:

- **neovim-config**: Neovim configuration with init.lua + plugin/ftplugin/after directories
  - Specialized plugin loading verification
  - Config validation
  - Mock Neovim environment support

- **neovim-plugin**: Neovim plugin with plugin/init.vim or lua/*/init.lua structure
  - Health check validation
  - Runtime path validation
  - Plugin structure validation

- **lua-lib**: Lua library with .rockspec files or certain directory structures
  - LuaRocks validation
  - Code coverage tracking
  - Multi-version testing

- **docs**: Documentation projects with MkDocs or similar structures
  - Documentation structure validation
  - Cross-reference validation
  - Site generation testing

You can override this detection by setting `project_type` in your configuration file.

### Documentation Validation

Hooks-util now includes comprehensive documentation validation tools:

- **Markdown Linting**: Using markdownlint with customizable rules
  - List numbering validation and fixing
  - Heading level consistency
  - Code block formatting
  - Comprehensive formatting checks

- **YAML Validation**: Using yamllint for workflow and configuration files
  - Schema validation
  - Format consistency
  - Syntax checking

- **JSON/TOML Validation**: For configuration files and package manifests
  - Syntax checking
  - Format validation

These tools are automatically enabled when the corresponding file types are detected in your repository.

### Advanced Configuration

The hooks utility supports additional configuration files for different environments:

1. **`.hooksrc`** / **`.hooks-util.lua`** - Main project configuration, committed to git
2. **`.hooksrc.local`** - Machine-specific configuration, not committed to git (shell format)
3. **`.hooksrc.user`** - User-specific configuration, not committed to git (shell format)
4. **`.hooks-util.local.lua`** - Machine-specific Lua configuration, not committed to git
5. **`.hooks-util.user.lua`** - User-specific Lua configuration, not committed to git

Example files are provided that you can copy and customize:

```bash
# Create your local shell configuration
cp templates/hooksrc.local.example .hooksrc.local

# Create your user shell configuration
cp templates/hooksrc.user.example .hooksrc.user

# Create your Lua configuration
cp templates/hooks-util.lua.template .hooks-util.lua
```

Configuration files are loaded in order (main → local → user), with later files overriding earlier ones.

## Component Overview

- `/lib` - Core utility functions
- `/hooks` - Ready-to-use hook implementations
- `/templates` - Template configurations

## Requirements

- **Bash** - Shell environment for hook execution
- **Git** - Version control system
- **StyLua** - For Lua code formatting (optional but recommended)
- **Luacheck** - For Lua static analysis (optional but recommended)
- **ShellCheck** - For shell script validation (required for shell scripts)
- **Neovim 0.8+** - For running tests (if enabled)

The hooks system will gracefully handle missing tools with appropriate warnings.

## Tool Integration

### StyLua Integration

Automatically formats Lua files according to Neovim coding conventions:

```bash
# Custom StyLua path can be specified in .hooksrc
STYLUA_PATH="/custom/path/to/stylua"
STYLUA_ARGS="--config-path=/path/to/.stylua.toml"
```

### Luacheck Integration

Static analysis for your Lua code to catch errors before they occur:

```bash
# Custom Luacheck path can be specified in .hooksrc
LUACHECK_PATH="/custom/path/to/luacheck"
LUACHECK_ARGS="--config /path/to/.luacheckrc"
```

### ShellCheck Integration

Validates shell scripts for common errors and best practices:

```bash
# Custom ShellCheck path can be specified in .hooksrc
SHELLCHECK_PATH="/custom/path/to/shellcheck"
SHELLCHECK_SEVERITY="warning" # error, warning, info, style
```

### Neovim Test Integration

Runs your project's test suite before committing:

```bash
# Test configuration in .hooksrc
TEST_TIMEOUT=60000            # 60 seconds test timeout
TEST_FRAMEWORK="plenary"      # plenary, busted, lust-next, or make
TEST_COMMAND="make test"      # Custom test command
```

### Lust-Next Testing Integration

Hooks-util now includes comprehensive integration with lust-next, a lightweight and powerful testing framework for Lua:

```bash
# Run all tests with lust-next
./spec/runner.lua

# Filter tests by pattern
./spec/runner.lua "core"

# Run tests with specific tags
./spec/runner.lua "" "unit"
```

### Test Quality Validation

Hooks-util provides integrated test quality validation through lust-next:

```lua
-- From your .hooks-util.lua configuration
test_quality = {
  enabled = true,      -- Enable test quality validation in pre-commit hooks

  -- Test coverage configuration
  coverage = {
    enabled = false,   -- Enable code coverage validation
    threshold = 80,    -- Minimum coverage percentage required (0-100)
    include = {"lua/**/*.lua"}, -- Files to check coverage for
    exclude = {"test_*", "*_spec.lua"} -- Files to exclude from coverage
  },

  -- Test quality level configuration
  quality = {
    enabled = false,   -- Enable quality level validation
    level = 1,         -- Quality level to enforce (1-5)
    strict = false,    -- Strict mode (fail on first issue)
  }
}
```

#### Quality Levels

The test quality validation system has five progressive levels:

1. **Basic (Level 1)** - Minimal testing with proper structure
   - At least one assertion per test
   - Basic test organization with describe/it blocks
   - No empty test blocks

1. **Standard (Level 2)** - More comprehensive testing
   - Multiple assertions per test
   - Multiple assertion types (equality, truth, type checking)
   - Better test naming with "should" descriptions
   - Proper error case handling

1. **Comprehensive (Level 3)** - Edge case testing and better isolation
   - Edge case testing
   - Type checking assertions
   - Proper mock/stub usage
   - Isolated test setup and teardown with before/after hooks

1. **Advanced (Level 4)** - Boundary testing and complete verification
   - Boundary condition testing
   - Complete mock verification
   - Proper test organization with nested contexts
   - Detailed error assertions and validation

1. **Complete (Level 5)** - Security, performance, and thorough coverage
   - 100% branch coverage
   - Security vulnerability testing
   - Performance validation
   - Comprehensive API contract testing
   - Full dependency isolation

You can gradually increase the quality level as your test suite matures.

#### Setting Up Lust-Next Testing

To configure your project for lust-next testing:

```lua
-- From your Lua code
local lust_next = require("hooks-util.lust-next")
lust_next.setup_project("/path/to/your/project")
```

This will:

- Create a `spec/` directory structure for your tests
- Set up a test runner script
- Create a base spec helper
- Prepare a minimal test example
- Add necessary configuration for GitHub or GitLab CI

#### Test File Structure

Lust-next tests use a BDD-style syntax:

```lua
-- spec/core/my_module_spec.lua
describe("my_module", function()
  local my_module

  before_each(function()
    -- Setup code runs before each test
    my_module = require("my_module")
  end)

  it("performs the expected action", function()
    local result = my_module.some_function()
    assert(result == "expected value")
  end)

  it("handles errors gracefully", function()
    local success = pcall(my_module.risky_function)
    assert(not success, "Should have failed")
  end)
end)
```

### Submodule Update Mechanism

When you use hooks-util as a git submodule, you can enable automatic updates whenever the submodule is updated:

```bash
# Add these lines to your shell configuration file (~/.bashrc or ~/.zshrc)
source "/path/to/your/repo/hooks-util/scripts/gitmodules-hooks.sh"
alias git=git_with_hooks
```

This sets up a wrapper around the git command that detects when you run `git submodule update` and automatically runs the post-update hooks.

For more details, see [Submodule Update Mechanism](docs/submodule-update.md).

### Workflow Management

Hooks-util provides a base + adapter workflow system for GitHub Actions:

```bash
# Base workflows are combined with adapter-specific configurations
hooks-util/
├── ci/
│   ├── github/
│   │   ├── workflows/       # Base workflow templates
│   │   │   ├── ci.yml
│   │   │   ├── markdown-lint.yml
│   │   │   └── ...
│   │   └── configs/        # Adapter-specific configurations
│   │       ├── lua-lib/
│   │       ├── nvim-plugin/
│   │       └── ...
```

When you run the installation script, hooks-util automatically:

1. Detects your project type
2. Installs the appropriate base workflows
3. Merges them with adapter-specific configurations
4. Creates the final workflow files in your `.github/workflows` directory

This ensures that your project gets both the common functionality and the specialized validations specific to your project type.

#### Generating CI Workflow

You can generate a CI workflow configuration for your tests:

```lua
local lust_next = require("hooks-util.lust-next")
lust_next.generate_workflow("/path/to/project", "github")  -- github, gitlab, or azure
```

This creates the appropriate workflow files for your CI platform, configured to run your lust-next tests.

## Testing

Hooks-util includes a comprehensive testing strategy to ensure reliability across different adapter types and environments.

### Automated Testing

The project includes several automated testing tools:

```bash
# Run the test suite on core functionality
env -C /home/gregg/Projects/lua-library/hooks-util ./spec/runner.lua

# Test across all adapter types
env -C /home/gregg/Projects/lua-library/hooks-util ./scripts/test_all_adapters.sh

# Validate GitHub workflows locally
env -C /home/gregg/Projects/lua-library/hooks-util ./scripts/test_github_workflows.sh
```

### Testing with Testbed Projects

For comprehensive validation, hooks-util is tested across multiple adapter types using specialized testbed projects:

- **hooks-util-testbed-lua-lib**: Tests with Lua library adapter
- **hooks-util-testbed-nvim-plugin**: Tests with Neovim plugin adapter
- **hooks-util-testbed-nvim-config**: Tests with Neovim config adapter
- **hooks-util-testbed-docs**: Tests with Documentation adapter

### Testing Guidelines

For details on proper testing procedures, common pitfalls to avoid, and comprehensive testing strategies, see [TESTING.md](TESTING.md).

## Community

- [GitHub Discussions](https://github.com/greggh/hooks-util/discussions) - Get help, share ideas, and connect with other users
- [GitHub Issues](https://github.com/greggh/hooks-util/issues) - Report bugs or suggest features
- [GitHub Pull Requests](https://github.com/greggh/hooks-util/pulls) - Contribute to the project

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to contribute to this project.

## License

[MIT License](LICENSE) - See the LICENSE file for details.

## Acknowledgements

- [StyLua](https://github.com/JohnnyMorganz/StyLua) - Lua code formatter designed for Neovim
- [Luacheck](https://github.com/lunarmodules/luacheck) - Lua static analyzer and linter
- [ShellCheck](https://github.com/koalaman/shellcheck) - Shell script static analysis tool
- [Neovim](https://neovim.io/) - The core editor these hooks support
- [lust-next](https://github.com/greggh/lust-next) - Lightweight, powerful Lua testing framework
- [Plenary.nvim](https://github.com/nvim-lua/plenary.nvim) - Testing framework integration
- [pre-commit](https://pre-commit.com/) - Hook management framework that inspired this project
- [GitHub Actions](https://github.com/features/actions) - CI/CD workflow integration
- [Semantic Versioning](https://semver.org/) - Versioning standard used in this project
- [Contributor Covenant](https://www.contributor-covenant.org/) - Code of Conduct standard
- [Keep a Changelog](https://keepachangelog.com/) - Changelog format

---

<div align="center">
  <p>Made with ❤️ by <a href="https://github.com/greggh">Gregg Housh</a></p>
</div>

