
# Getting Started with Neovim Hooks Utilities

This guide will help you set up and start using the Neovim Hooks Utilities in your Neovim Lua project.

## Prerequisites

Before you begin, make sure you have:

- Git installed and configured
- Bash shell (Linux/macOS) or Git Bash (Windows)
- Neovim installed (0.5.0+)
- StyLua installed for Lua formatting
- Luacheck installed for Lua linting

## Installation

### Option 1: Git Submodule (Recommended)

```bash

# Add the hooks utilities as a git submodule
git submodule add https://github.com/greggh/hooks-util.git .hooks-util

# Run the installation script
cd .hooks-util
./install.sh

```text

### Option 2: Direct Download

```bash

# Create a directory for the hooks utilities
mkdir -p .hooks-util

# Download and extract the utilities
curl -L https://github.com/greggh/hooks-util/archive/refs/tags/v0.2.1.tar.gz | tar -xz --strip-components=1 -C .hooks-util

# Run the installation script
cd .hooks-util
./install.sh

```text

## Configuration

After installation, you'll have a `.hooksrc` file in your project root. This file controls the behavior of the hooks.

```bash

# Example .hooksrc configuration
HOOKS_STYLUA_ENABLED=true
HOOKS_LUACHECK_ENABLED=true
HOOKS_TESTS_ENABLED=true
HOOKS_QUALITY_ENABLED=true
HOOKS_VERBOSITY=1  # 0=quiet, 1=normal, 2=verbose

```text

You can customize this configuration to suit your project needs.

### Advanced Configuration

For machine-specific or user-specific settings, you can create:

- `.hooksrc.local` - For machine-specific settings (not committed to git)
- `.hooksrc.user` - For user-specific preferences (not committed to git)

Example files are provided in the hooks-util repository.

## Basic Usage

Once installed, the hooks will run automatically on git operations:

- **Pre-commit hook**: Runs before each commit to format, lint, and test code
- More hook types coming soon

## Customization

### Tool Paths

If your tools are installed in non-standard locations, you can specify their paths:

```bash

# Custom tool paths
HOOKS_STYLUA_PATH=/custom/path/to/stylua
HOOKS_LUACHECK_PATH=/custom/path/to/luacheck
HOOKS_NEOVIM_PATH=/custom/path/to/nvim

```text

## Next Steps

- Check out the [API Reference](../api/README.md) for details on available functions
- See [Examples](../examples/README.md) for advanced usage scenarios
- Learn about [Hook Types](../reference/hook-types.md) for different git operations

## Troubleshooting

If you encounter issues:

1. Increase verbosity in `.hooksrc`: `HOOKS_VERBOSITY=2`
2. Check that required tools (StyLua, Luacheck) are in your PATH
3. Verify configuration file syntax
4. See [Common Issues](troubleshooting.md) for known problems and solutions

