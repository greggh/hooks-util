#!/bin/bash
# Neovim config integration test for hooks-util
set -e  # Exit on any error

# Determine script and project directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TEST_DIR=$(mktemp -d)

cleanup() {
  rm -rf "$TEST_DIR"
  echo "Cleaned up test directory"
}

trap cleanup EXIT

echo "=== hooks-util Neovim Config Integration Test ==="
echo "Creating test Neovim config in $TEST_DIR"

# Set up test repository mimicking Neovim config
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
git init
git config user.name "Test User"
git config user.email "test@example.com"

# Create Neovim config structure
mkdir -p lua/plugins
mkdir -p lua/config
mkdir -p lua/utils
mkdir -p tests/spec

# Create some initial files
cat > lua/init.lua << 'EOF'
-- Main Neovim config init file
require("config.options")
require("config.plugins")
require("config.keymaps")
EOF

cat > lua/config/options.lua << 'EOF'
-- Neovim options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
EOF

# Add files to Git
git add lua
git commit -m "Initial Neovim config"

# Create a file with issues
cat > lua/plugins/lsp.lua << 'EOF'
-- LSP configuration
local lsp_installed = false    
local diagnostic_enabled = true

-- Configure LSP servers
local function setup_lsp()
    local lspconfig = require("lspconfig")
    local unused_var = "test"
    
    -- Set up lua-ls
    lspconfig.lua_ls.setup({
        settings = {
            Lua = {
                diagnostics = {
                    globals = { "vim" },
                },
            },
        },
    })
    
    lsp_installed = true
    return true
end

return {
    "neovim/nvim-lspconfig",
    config = setup_lsp,
}
EOF

# Add the file to Git
git add lua/plugins/lsp.lua

# Set up hooks-util
echo "Setting up hooks-util"
mkdir -p .hooks-util
cp -r "$PROJECT_DIR/"* .hooks-util/

# Create a configuration
cat > .hooksrc << 'EOF'
HOOKS_STYLUA_ENABLED=true
HOOKS_LUACHECK_ENABLED=true
HOOKS_TESTS_ENABLED=false
HOOKS_QUALITY_ENABLED=true
HOOKS_VERBOSITY=2
EOF

# Set up StyLua config
cat > .stylua.toml << 'EOF'
column_width = 120
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
EOF

# Set up Luacheck config
cat > .luacheckrc << 'EOF'
-- Global objects
globals = {
  "vim",
}

-- Don't report unused self arguments of methods
self = false

-- Max line length
max_line_length = 120
EOF

# Install the hooks
bash .hooks-util/install.sh

# Try to commit with issues
echo "Attempting to commit with issues (this should trigger hooks):"
if git commit -m "Add LSP configuration"; then
  echo "FAIL: Commit succeeded but should have failed due to issues"
  exit 1
else
  echo "PASS: Commit correctly failed due to hooks"
fi

# Fix the issues manually for testing
cat > lua/plugins/lsp.lua << 'EOF'
-- LSP configuration
local lsp_installed = false
local diagnostic_enabled = true

-- Configure LSP servers
local function setup_lsp()
  local lspconfig = require("lspconfig")
  local _unused_var = "test"

  -- Set up lua-ls
  lspconfig.lua_ls.setup({
    settings = {
      Lua = {
        diagnostics = {
          globals = { "vim" },
        },
      },
    },
  })

  lsp_installed = true
  return true
end

return {
  "neovim/nvim-lspconfig",
  config = setup_lsp,
}
EOF

git add lua/plugins/lsp.lua

# Try to commit again
echo "Attempting to commit with fixed issues:"
if git commit -m "Add LSP configuration"; then
  echo "PASS: Commit succeeded after fixing issues"
else
  echo "FAIL: Commit failed even after fixing issues"
  exit 1
fi

echo "All tests passed!"
exit 0