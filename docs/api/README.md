# Neovim Hooks Utilities API Reference

This directory contains documentation for the Neovim Hooks Utilities API.

## Module Overview

### Shell Modules

| Module | Description |
|--------|-------------|
| [common.sh](common.md) | Core utility functions and configuration handling |
| [error.sh](error.md) | Error handling and reporting utilities |
| [path.sh](path.md) | Path handling and resolution functions |
| [stylua.sh](stylua.md) | StyLua integration for Lua formatting |
| [luacheck.sh](luacheck.md) | Luacheck integration for Lua linting |
| [test.sh](test.md) | Test runner integration for Neovim plugins |
| [quality.sh](quality.md) | Code quality improvement utilities |
| [version.sh](version.md) | Version information and management |

### Lua Modules

| Module | Description |
|--------|-------------|
| [lua-integration](lua-integration.md) | Lua integration, adapter system, and lust-next integration |
| [adapter](lua-integration.md#adapter-module) | Project type detection and adapter system |
| [config](lua-integration.md#config-module) | Configuration management in Lua |
| [registry](lua-integration.md#registry-module) | Adapter registry and management |
| [lust-next](lua-integration.md#lust-next-integration) | Testing framework integration |

## Hook Types

| Hook | Description |
|------|-------------|
| [pre-commit](../hooks/pre-commit.md) | Runs before a commit is created |

## Getting Started

To use the hooks utility API in your own hooks:

```bash
#!/bin/bash
# Example custom hook

# Include the required modules
HOOKS_UTIL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.hooks-util" && pwd)"
source "${HOOKS_UTIL_DIR}/lib/common.sh"
source "${HOOKS_UTIL_DIR}/lib/error.sh"

# Use the API functions
hooks_print_header "Custom Hook"
hooks_debug "Running custom functionality"

# Define custom logic
# ...

# Handle errors
hooks_handle_error $? "Custom hook failed"

# Exit with proper code
hooks_print_error_summary
exit $?
```
