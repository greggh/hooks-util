-- hooks-util/adapters/nvim-plugin/init.lua
-- Adapter for Neovim plugins
local adapter = require("hooks-util.core.adapter")

-- Create the Neovim plugin adapter
local nvim_plugin_adapter = adapter.create({
  name = "nvim-plugin",
  description = "Adapter for Neovim plugins",
  version = "0.1.0",
  
  -- Check if this adapter is compatible with the project
  is_compatible = function(self, project_root)
    -- Check for Neovim plugin-specific markers
    local markers = {
      "lua/*/init.lua", -- Standard plugin structure
      "plugin/*.lua",    -- Plugin loader file
      "lua/**/plugin.lua", -- Plugin module
      "doc/*.txt",       -- Vim documentation
    }
    
    -- Check if any markers exist
    for _, marker in ipairs(markers) do
      local result = vim.fn.globpath(project_root, marker, true)
      if result and result ~= "" then
        return true
      end
    end
    
    -- Check if it has a plugin name structure in lua directory
    local lua_dir = project_root .. "/lua"
    if vim.fn.isdirectory(lua_dir) == 1 then
      local entries = vim.fn.readdir(lua_dir)
      for _, entry in ipairs(entries) do
        if entry ~= "." and entry ~= ".." and vim.fn.isdirectory(lua_dir .. "/" .. entry) == 1 then
          -- Found a subdirectory in lua/ - likely a plugin namespace
          return true
        end
      end
    end
    
    return false
  end,
  
  -- Get linter configuration for Neovim plugins
  get_linter_config = function(self, project_root)
    return {
      stylua = {
        enabled = true,
        config_file = ".stylua.toml",
        -- Default config for Neovim plugins
        default_config = [[
column_width = 120
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
]]
      },
      luacheck = {
        enabled = true,
        config_file = ".luacheckrc",
        -- Default config for Neovim plugins
        default_config = [[
-- vim: ft=lua tw=80

stds.nvim = {
  globals = {
    "vim",
    "describe",
    "it",
    "before_each",
    "after_each",
    "teardown",
    "pending",
    os = { fields = { "execute" } },
  },
  read_globals = {
    "jit",
    "require",
  },
}

std = "lua51+nvim"

files["test/*_spec.lua"] = {
  std = "+busted",
}

files["lua/**/health.lua"] = {
  globals = { "vim" },
}

max_line_length = 120
ignore = {
  "212/_.*", -- Unused argument, for callbacks
  "631",     -- Line is too long
}
]]
      },
      shellcheck = {
        enabled = true,
      },
    }
  end,
  
  -- Get test configuration for Neovim plugins
  get_test_config = function(self, project_root)
    -- Check if the project uses plenary.nvim for testing
    local uses_plenary = false
    local test_directory = project_root .. "/test"
    if vim.fn.isdirectory(test_directory) == 1 then
      local entries = vim.fn.readdir(test_directory)
      for _, entry in ipairs(entries) do
        if entry:match("_spec%.lua$") then
          -- Found spec file, assume plenary.nvim
          uses_plenary = true
          break
        end
      end
    end
    
    -- Check if the project uses lust-next for testing
    local uses_lust_next = false
    local spec_directory = project_root .. "/spec"
    if vim.fn.isdirectory(spec_directory) == 1 then
      local entries = vim.fn.readdir(spec_directory)
      for _, entry in ipairs(entries) do
        if entry:match("%.lua$") then
          -- Found lua test file in spec/, assume lust-next
          uses_lust_next = true
          break
        end
      end
    end
    
    -- Determine test command
    local test_command
    if uses_plenary then
      test_command = "nvim --headless -c 'lua require(\"plenary.test_harness\").test_directory(\"test\", { minimal_init = \"test/minimal_init.lua\" })'"
    elseif uses_lust_next then
      test_command = "lua spec/runner.lua"
    else
      -- Default to lust-next (our preferred test framework)
      test_command = "lua spec/runner.lua"
    end
    
    return {
      enabled = true,
      framework = uses_plenary and "plenary" or "lust-next",
      test_command = test_command,
      timeout = 60000, -- 60 seconds
    }
  end,
  
  -- Get CI workflow templates for Neovim plugins
  get_ci_templates = function(self, project_root, platform)
    -- Return platform-specific template paths
    if platform == "github" then
      return {
        "/home/gregg/Projects/hooks-util/ci/github/neovim-plugin-ci.yml",
        "/home/gregg/Projects/hooks-util/ci/github/neovim-plugin-docs.yml",
        "/home/gregg/Projects/hooks-util/ci/github/neovim-plugin-release.yml",
      }
    elseif platform == "gitlab" then
      return {
        "/home/gregg/Projects/hooks-util/ci/gitlab/neovim-plugin-ci.yml",
      }
    elseif platform == "azure" then
      return {
        "/home/gregg/Projects/hooks-util/ci/azure/neovim-plugin-ci.yml",
      }
    end
    
    return {}
  end,
  
  -- Generate a configuration file for Neovim plugins
  generate_config = function(self, project_root, options)
    options = options or {}
    
    -- Generate stylua.toml if it doesn't exist
    local stylua_path = project_root .. "/.stylua.toml"
    if not vim.fn.filereadable(stylua_path) == 1 then
      local stylua_config = self:get_linter_config(project_root).stylua.default_config
      local stylua_file = io.open(stylua_path, "w")
      if stylua_file then
        stylua_file:write(stylua_config)
        stylua_file:close()
      end
    end
    
    -- Generate luacheckrc if it doesn't exist
    local luacheckrc_path = project_root .. "/.luacheckrc"
    if not vim.fn.filereadable(luacheckrc_path) == 1 then
      local luacheckrc_config = self:get_linter_config(project_root).luacheck.default_config
      local luacheckrc_file = io.open(luacheckrc_path, "w")
      if luacheckrc_file then
        luacheckrc_file:write(luacheckrc_config)
        luacheckrc_file:close()
      end
    end
    
    -- Setup test directory structure if requested
    if options.setup_tests and options.test_framework then
      if options.test_framework == "lust-next" then
        -- Create spec directory if it doesn't exist
        local spec_dir = project_root .. "/spec"
        if vim.fn.isdirectory(spec_dir) ~= 1 then
          vim.fn.mkdir(spec_dir, "p")
        end
        
        -- Create a basic spec file if none exists
        local spec_files = vim.fn.globpath(spec_dir, "*.lua", true)
        if spec_files == "" then
          local spec_file_path = spec_dir .. "/basic_spec.lua"
          local spec_file = io.open(spec_file_path, "w")
          if spec_file then
            spec_file:write([[
-- Basic test for the plugin
local plugin_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")

describe(plugin_name, function()
  it("can be required", function()
    -- Attempt to require the main module
    local ok, module = pcall(require, plugin_name)
    assert(ok, "Module should be requireable")
    assert(module, "Module should not be nil")
  end)
  
  it("has a setup function", function()
    local module = require(plugin_name)
    assert(type(module.setup) == "function", "Module should have a setup function")
  end)
end)
]])
            spec_file:close()
          end
        end
      end
    end
    
    return true, "Configuration files generated for Neovim plugin"
  end,
  
  -- Hook into pre-commit process for Neovim plugins
  pre_commit_hook = function(self, project_root, files)
    -- Check version consistency
    local version_config = self:get_version_config(project_root)
    if version_config and version_config.enabled then
      -- TODO: Implement version check
    end
    
    -- Additional Neovim plugin-specific checks
    
    -- 1. Check for proper Neovim plugin structure
    local has_lua_dir = vim.fn.isdirectory(project_root .. "/lua") == 1
    local has_plugin_dir = vim.fn.isdirectory(project_root .. "/plugin") == 1
    
    if not (has_lua_dir or has_plugin_dir) then
      print("Warning: Neovim plugin should have either a 'lua' or 'plugin' directory")
    end
    
    -- 2. Check doc directory if relevant files were changed
    local has_doc_changes = false
    for _, file in ipairs(files or {}) do
      if file:match("^lua/") or file:match("^plugin/") then
        has_doc_changes = true
        break
      end
    end
    
    local has_doc_dir = vim.fn.isdirectory(project_root .. "/doc") == 1
    if has_doc_changes and not has_doc_dir then
      print("Warning: Changes to plugin functionality detected, but no 'doc' directory found")
    end
    
    return true -- Continue with commit
  end,
  
  -- Get version verification configuration for Neovim plugins
  get_version_config = function(self, project_root)
    -- Check for plugin structure to determine where version would be defined
    local version_file = "lua/version.lua"
    local plugin_name = nil
    
    -- Try to detect plugin name from lua directory
    local lua_dir = project_root .. "/lua"
    if vim.fn.isdirectory(lua_dir) == 1 then
      local entries = vim.fn.readdir(lua_dir)
      for _, entry in ipairs(entries) do
        if entry ~= "." and entry ~= ".." and vim.fn.isdirectory(lua_dir .. "/" .. entry) == 1 then
          -- Found a subdirectory in lua/ - likely the plugin namespace
          plugin_name = entry
          break
        end
      end
    end
    
    if plugin_name then
      -- Check for version in plugin namespace
      local namespace_version = "lua/" .. plugin_name .. "/version.lua"
      if vim.fn.filereadable(project_root .. "/" .. namespace_version) == 1 then
        version_file = namespace_version
      end
    end
    
    -- Return version configuration
    return {
      enabled = true,
      version_file = version_file,
      patterns = {
        -- Files that should contain version references
        {
          path = "README.md", 
          pattern = "Version: v(%d+%.%d+%.%d+)"
        },
        {
          path = "CHANGELOG.md",
          pattern = "## %[(%d+%.%d+%.%d+)%]"
        },
        {
          path = "doc/*.txt",
          pattern = "v(%d+%.%d+%.%d+)"
        }
      }
    }
  end
})

return nvim_plugin_adapter