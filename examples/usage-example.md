# Neovim Hooks Utilities Usage Examples

This document provides examples of how to use the Neovim Hooks Utilities in your Neovim Lua projects.

## Basic Installation

Here's how to install the hooks in your project:

```bash
# Clone the repository (as a submodule or standalone)
git submodule add https://github.com/greggh/hooks-util.git .hooks-util

# Run the installation script
.hooks-util/install.sh
```

## Configuration

Create a `.hooksrc` file in your project root:

```bash
# Basic configuration
HOOKS_STYLUA_ENABLED=true
HOOKS_LUACHECK_ENABLED=true
HOOKS_TESTS_ENABLED=true
HOOKS_VERBOSITY=1
```

## Custom Configuration

You can customize the configuration for more advanced scenarios:

```bash
# Custom paths for tools
HOOKS_STYLUA_PATH=/usr/local/bin/stylua
HOOKS_LUACHECK_PATH=/home/user/.luarocks/bin/luacheck
HOOKS_NEOVIM_PATH=/usr/local/bin/nvim

# Test configuration
HOOKS_TEST_TIMEOUT=120000  # 2 minutes
HOOKS_TEST_INIT_FILE="tests/minimal-init.lua"
```

## Integration with GitHub Actions

You can use these hooks in your GitHub Actions workflows too:

```yaml
name: Code Quality

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  lint-and-format:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: true
      
      - name: Install StyLua
        run: |
          curl -L -o stylua.zip $(curl -s https://api.github.com/repos/JohnnyMorganz/StyLua/releases/latest | grep -o "https://.*stylua-linux-x86_64.zip")
          unzip stylua.zip
          sudo mv stylua /usr/local/bin/
      
      - name: Install Luacheck
        run: |
          sudo apt-get update
          sudo apt-get install -y luarocks
          sudo luarocks install luacheck
      
      - name: Setup hooks
        run: |
          .hooks-util/install.sh --config
          
      - name: Check formatting
        run: |
          # This will use the hooks to check all Lua files
          find . -name "*.lua" | xargs .hooks-util/lib/stylua.sh
```

## Using Path Utilities

You can use the path utilities in your own scripts:

```bash
#!/bin/bash
# Example custom script

# Source the path utilities
source .hooks-util/lib/path.sh

# Use the utilities
config_file=$(hooks_find_config ".luacheckrc")
if [ -n "$config_file" ]; then
  echo "Found Luacheck config at: $config_file"
fi

# Normalize a path
win_path=$(hooks_normalize_path "/c/Users/username/project")
echo "Windows path: $win_path"
```

## Using Error Handling

The error handling utilities can be used in your scripts:

```bash
#!/bin/bash
# Example script with error handling

# Source the error handling utilities
source .hooks-util/lib/error.sh

# Try to run a command with fallbacks
formatter=$(hooks_require_command "stylua" "luafmt" "lua-format")
if [ $? -eq 0 ]; then
  echo "Using formatter: $formatter"
else
  echo "No formatter found!"
  exit 1
fi

# Run a command with timeout
hooks_run_with_timeout 30 nvim --headless -c "luafile tests/run_tests.lua" -c "q"
hooks_handle_error $? "Tests failed!" $HOOKS_ERROR_TESTS_FAILED
```