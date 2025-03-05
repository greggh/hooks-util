<div align="center">

# Neovim Hooks Utilities

[![GitHub License](https://img.shields.io/github/license/greggh/hooks-util?style=flat-square)](https://github.com/greggh/hooks-util/blob/main/LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/greggh/hooks-util?style=flat-square)](https://github.com/greggh/hooks-util/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/greggh/hooks-util?style=flat-square)](https://github.com/greggh/hooks-util/issues)
[![CI](https://img.shields.io/github/actions/workflow/status/greggh/hooks-util/ci.yml?branch=main&style=flat-square&logo=github)](https://github.com/greggh/hooks-util/actions/workflows/ci.yml)
[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Version](https://img.shields.io/badge/Version-0.2.2-blue?style=flat-square)](https://github.com/greggh/hooks-util/releases/tag/v0.2.2)
[![Docs](https://img.shields.io/badge/docs-passing-success?style=flat-square)](https://github.com/greggh/hooks-util/actions/workflows/docs.yml)

*A standardized Git hook framework for Lua-based Neovim projects with powerful error handling and code quality tools*

[Features](#features) • 
[Installation](#installation) • 
[Usage](#usage) • 
[Configuration](#configuration) • 
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
- **GitHub Integration** - Workflows for CI/CD, documentation, and releases

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

### Project Type Detection

Hooks-util can automatically detect your project type based on file structure:

- **neovim-config**: Neovim configuration with init.lua + plugin/ftplugin/after directories
- **neovim-plugin**: Neovim plugin with plugin/init.vim or lua/*/init.lua structure
- **lua-lib**: Lua library with .rockspec files or certain directory structures
- **lua-project**: Generic Lua project not fitting other categories

You can override this detection by setting `project_type` in your configuration file.

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

#### Generating CI Workflow

You can generate a CI workflow configuration for your tests:

```lua
local lust_next = require("hooks-util.lust-next")
lust_next.generate_workflow("/path/to/project", "github")  -- github, gitlab, or azure
```

This creates the appropriate workflow files for your CI platform, configured to run your lust-next tests.

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
  <p>Made with ❤️ by <a href="https://github.com/greggh">greggh</a></p>
</div>