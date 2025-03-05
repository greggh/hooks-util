-- hooks-util/adapters/utils.lua
-- Utility functions for adapters

local M = {}

-- Detect the type of project
function M.detect_project_type(project_path)
  -- Use the core adapter module's detection function
  local adapter = require("hooks-util.core.adapter")
  return adapter.utils.detect_project_type(project_path)
end

-- Get linting command for a file type
function M.get_lint_command(file_type)
  local commands = {
    lua = "luacheck",
    vim = "vint",
    sh = "shellcheck",   -- For shell scripts in hooks
    md = "markdownlint"  -- For documentation
  }
  
  return commands[file_type] or "echo 'No linter for " .. file_type .. "'"
end

-- Get formatting command for a file type
function M.get_format_command(file_type)
  local commands = {
    lua = "stylua",
    vim = "vim-format",
    sh = "shfmt",       -- For shell scripts in hooks
    md = "prettier"     -- For documentation
  }
  
  return commands[file_type] or "echo 'No formatter for " .. file_type .. "'"
end

-- Get test command for a project type
function M.get_test_command(project_type)
  local commands = {
    ["neovim-plugin"] = "lua ./spec/runner.lua",
    ["neovim-config"] = "lua ./spec/runner.lua",
    ["lua-lib"] = "lua ./spec/runner.lua",
    ["lua-project"] = "lua ./spec/runner.lua"
  }
  
  return commands[project_type] or "echo 'No test command for " .. project_type .. "'"
end

return M