# Neovim Hooks Utilities

A shared library of utilities for Git hooks across Lua-based Neovim projects.

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
- **Robust Test Framework** - Comprehensive tests for various scenarios (fixable issues, unfixable issues, tool validation)
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
curl -L https://github.com/greggh/hooks-util/archive/main.tar.gz | tar -xz --strip-components=1 -C .hooks-util
cd .hooks-util
./install.sh
```

## Usage

After installation, the pre-commit hooks in your repository will automatically use the shared utilities.

### Configuration

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

#### Advanced Configuration

The hooks utility supports additional configuration files for different environments:

1. **`.hooksrc`** - Main project configuration, committed to git
2. **`.hooksrc.local`** - Machine-specific configuration, not committed to git
3. **`.hooksrc.user`** - User-specific configuration, not committed to git

Example files are provided (`.hooksrc.local.example` and `.hooksrc.user.example`) that you can copy and customize:

```bash
# Create your local configuration
cp .hooksrc.local.example .hooksrc.local
# Create your user configuration
cp .hooksrc.user.example .hooksrc.user
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

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to contribute to this project.

## License

MIT License - See [LICENSE](LICENSE) for details.

## Acknowledgements

- [StyLua](https://github.com/JohnnyMorganz/StyLua) - Lua code formatter designed for Neovim
- [Luacheck](https://github.com/lunarmodules/luacheck) - Lua static analyzer and linter
- [ShellCheck](https://github.com/koalaman/shellcheck) - Shell script static analysis tool
- [Neovim](https://neovim.io/) - The core editor these hooks support
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