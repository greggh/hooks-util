
# Configuration Options Reference

This document provides a comprehensive list of all configuration options available in the hooks-util library.

## Basic Configuration Options

These options can be set in `.hooksrc`, `.hooksrc.local`, or `.hooksrc.user` files:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `HOOKS_STYLUA_ENABLED` | boolean | `true` | Enable/disable StyLua formatting |
| `HOOKS_LUACHECK_ENABLED` | boolean | `true` | Enable/disable Luacheck linting |
| `HOOKS_TESTS_ENABLED` | boolean | `true` | Enable/disable test execution |
| `HOOKS_QUALITY_ENABLED` | boolean | `true` | Enable/disable code quality fixes |
| `HOOKS_VERBOSITY` | integer | `1` | Output verbosity level (0=quiet, 1=normal, 2=verbose) |

## Tool Path Configuration

These options allow specifying custom paths to required tools:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `HOOKS_STYLUA_PATH` | string | `stylua` | Path to StyLua executable |
| `HOOKS_LUACHECK_PATH` | string | `luacheck` | Path to Luacheck executable |
| `HOOKS_NEOVIM_PATH` | string | `nvim` | Path to Neovim executable |

## Test Configuration

These options control the test execution behavior:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `HOOKS_TEST_TIMEOUT` | integer | `60000` | Test timeout in milliseconds (60 seconds) |
| `HOOKS_TEST_PATTERN` | string | *varies* | Pattern for test files (default depends on test framework) |

## Advanced Configuration

These options are for advanced customization:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `HOOKS_CUSTOM_HOOKS_DIR` | string | *empty* | Directory for custom hook scripts |
| `HOOKS_AUTO_STAGE` | boolean | `true` | Automatically stage fixed files |
| `HOOKS_ALLOW_NO_VERIFY` | boolean | `true` | Allow bypassing hooks with --no-verify |

## Configuration Locations and Priority

Multiple configuration files can be used together, with later ones overriding earlier ones:

1. **Default configuration** - Built-in defaults from common.sh
2. **Project configuration** - `.hooksrc` in the repository root
3. **Machine-specific configuration** - `.hooksrc.local` in the repository root
4. **User-specific configuration** - `.hooksrc.user` in the repository root

## Examples

### Basic Configuration

```bash

# .hooksrc - Basic configuration
HOOKS_STYLUA_ENABLED=true
HOOKS_LUACHECK_ENABLED=true
HOOKS_TESTS_ENABLED=true
HOOKS_QUALITY_ENABLED=true
HOOKS_VERBOSITY=1

```text

### Machine-Specific Configuration

```bash

# .hooksrc.local - Machine-specific configuration
HOOKS_STYLUA_PATH=/opt/stylua/bin/stylua
HOOKS_LUACHECK_PATH=/usr/local/bin/luacheck
HOOKS_NEOVIM_PATH=/opt/neovim/bin/nvim
HOOKS_TEST_TIMEOUT=120000  # Increase timeout for slower machines

```text

### User-Specific Configuration

```bash

# .hooksrc.user - User-specific configuration
HOOKS_TESTS_ENABLED=false  # Disable tests for this user
HOOKS_VERBOSITY=2          # Increase verbosity for debugging

```text

