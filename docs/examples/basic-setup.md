# Basic Setup Example

This example demonstrates a standard setup for hooks-util in a Neovim Lua plugin project.

## Project Structure

Assume we have a typical Neovim plugin structure:

```
my-plugin/
├── lua/
│   └── my-plugin/
│       ├── init.lua
│       └── utils.lua
├── tests/
│   └── spec/
│       └── my-plugin_spec.lua
├── .stylua.toml
├── .luacheckrc
└── Makefile
```

## Step 1: Add hooks-util as a Git Submodule

```bash
cd my-plugin
git submodule add https://github.com/greggh/hooks-util.git .hooks-util
cd .hooks-util
./install.sh
```

## Step 2: Configure the Hooks

The installation script will create a `.hooksrc` file in your project root. Let's customize it:

```bash
# .hooksrc - Hooks configuration
HOOKS_STYLUA_ENABLED=true
HOOKS_LUACHECK_ENABLED=true
HOOKS_TESTS_ENABLED=true 
HOOKS_QUALITY_ENABLED=true
HOOKS_VERBOSITY=1          # 0=quiet, 1=normal, 2=verbose
```

## Step 3: Add Configuration Files for Tools

If you don't already have them, create configuration files for StyLua and Luacheck:

**.stylua.toml**
```toml
column_width = 120
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
```

**.luacheckrc**
```lua
-- Global objects
globals = {
  "vim",
}

-- Don't report unused self arguments of methods
self = false

-- Don't report unused arguments
unused_args = false

-- Standard globals
std = "luajit"

-- Max line length
max_line_length = 120

-- Exclude submodules and generated files
exclude_files = {
  ".luarocks/**",
  "lua/deps/**",
}
```

## Step 4: Add a Test Setup

**tests/minimal-init.lua**
```lua
-- Minimal init file for tests
vim.cmd("set runtimepath+=.")
vim.cmd("set packpath=")
vim.o.termguicolors = true
vim.o.swapfile = false

-- Load the plugin
require("my-plugin")
```

**Makefile**
```makefile
.PHONY: test

test:
	nvim --headless -u tests/minimal-init.lua -c "lua require('plenary.busted').run('./tests/spec')" -c "qa!"
```

## Step 5: Make a Commit

Now when you make changes and commit, the hooks will run automatically:

```bash
# Make some changes to your plugin
vim lua/my-plugin/init.lua

# Add the changes
git add lua/my-plugin/init.lua

# Commit (this will trigger the pre-commit hook)
git commit -m "Update plugin initialization"
```

The pre-commit hook will:
1. Fix code quality issues (trailing whitespace, line endings, etc.)
2. Format your Lua code with StyLua
3. Lint your code with Luacheck
4. Run your tests to ensure nothing is broken

## Troubleshooting

If you encounter any issues:

1. Increase verbosity in your `.hooksrc` file: `HOOKS_VERBOSITY=2`
2. Check the output for specific errors
3. Ensure StyLua and Luacheck are correctly installed and in your PATH