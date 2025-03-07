-- hooks-util/adapters/nvim-config/init.lua
-- Adapter for Neovim configurations
local adapter = require("hooks-util.core.adapter")
local lfs = require("lfs")

-- Create the Neovim config adapter
local nvim_config_adapter = adapter.create({
  name = "nvim-config",
  description = "Adapter for Neovim configuration directories",
  version = "0.2.0", -- Version updated to reflect new functionality
  
  -- Check if this adapter is compatible with the project
  is_compatible = function(self, project_root)
    -- Check for Neovim configuration-specific markers
    local markers = {
      "init.lua",          -- Main init file
      "init.vim",          -- Legacy init file
      "lua/plugins.lua",   -- Common plugins file
      "lua/plugins/init.lua", -- Organized plugins directory
      "after/plugin",      -- After-plugin directory
      "lua/config",        -- Common config directory
    }
    
    -- Check if any markers exist
    for _, marker in ipairs(markers) do
      local path = project_root .. "/" .. marker
      local f = io.open(path, "r")
      if f then
        f:close()
        
        -- For init.lua/init.vim, do additional check to confirm it's a Neovim config
        if marker == "init.lua" or marker == "init.vim" then
          -- Open the file and check first few lines for Neovim-specific content
          f = io.open(path, "r")
          if f then
            local content = f:read(500)  -- Read first 500 bytes
            f:close()
            
            -- Look for common Neovim config patterns
            if content and (content:match("nvim") or content:match("vim") or 
                           content:match("plugins") or content:match("options") or
                           content:match("keymap")) then
              return true
            end
          end
        else
          -- Other markers are specific enough
          return true
        end
      end
    end
    
    -- Check for specific directories common in Neovim configs
    local dirs = {
      "lua/plugins",
      "lua/config",
      "lua/lsp",
      "plugin",
      "ftplugin",
      "colors",
    }
    
    for _, dir in ipairs(dirs) do
      local path = project_root .. "/" .. dir
      local info = vim.loop.fs_stat(path)
      if info and info.type == "directory" then
        return true
      end
    end
    
    return false
  end,
  
  -- Get linter configuration for Neovim configs
  get_linter_config = function(self, project_root)
    return {
      stylua = {
        enabled = true,
        config_file = ".stylua.toml",
        -- Default config for Neovim configs
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
        -- Default config for Neovim configs
        default_config = [[
-- vim: ft=lua tw=80

stds.nvim = {
  globals = {
    "vim",
    os = { fields = { "execute" } },
  },
  read_globals = {
    "jit",
    "require",
  },
}

std = "lua51+nvim"

globals = {
  "use", -- For packer
  "vim",
}

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
  
  -- Get test configuration for Neovim configs
  get_test_config = function(self, project_root)
    -- Neovim configs rarely have tests, but we can check for any test directories
    local test_directory = project_root .. "/tests"
    local has_tests = vim.fn.isdirectory(test_directory) == 1
    
    -- Check for other test directories
    if not has_tests then
      test_directory = project_root .. "/test"
      has_tests = vim.fn.isdirectory(test_directory) == 1
    end
    
    -- Check for spec directory
    if not has_tests then
      test_directory = project_root .. "/spec"
      has_tests = vim.fn.isdirectory(test_directory) == 1
    end
    
    -- If no tests are found, disable testing
    if not has_tests then
      return {
        enabled = false,
        framework = nil,
        test_command = nil,
        timeout = 60000, -- 60 seconds
      }
    end
    
    -- Otherwise, try to determine the test framework
    local test_files = vim.fn.globpath(test_directory, "**/*.lua", true)
    local has_plenary = test_files:match("_spec%.lua$") ~= nil
    local has_lust_next = vim.fn.isdirectory(project_root .. "/spec") == 1
    
    local test_command
    if has_plenary then
      test_command = "nvim --headless -c 'lua require(\"plenary.test_harness\").test_directory(\"tests\")'"
    elseif has_lust_next then
      test_command = "lua spec/runner.lua"
    else
      -- Use a safe default command
      test_command = "echo 'No test framework detected; skipping tests'"
    end
    
    return {
      enabled = has_tests,
      framework = has_plenary and "plenary" or (has_lust_next and "lust-next" or "unknown"),
      test_command = test_command,
      timeout = 60000, -- 60 seconds
    }
  end,
  
  -- Get CI workflow templates for Neovim configs
  get_ci_templates = function(self, project_root, platform)
    -- Return platform-specific template paths
    if platform == "github" then
      return {
        "/home/gregg/Projects/hooks-util/ci/github/nvim-config-ci.yml",
        "/home/gregg/Projects/hooks-util/ci/github/nvim-config-docs.yml",
      }
    elseif platform == "gitlab" then
      return {
        "/home/gregg/Projects/hooks-util/ci/gitlab/nvim-config-ci.yml",
      }
    elseif platform == "azure" then
      return {
        "/home/gregg/Projects/hooks-util/ci/azure/nvim-config-ci.yml",
      }
    end
    
    return {}
  end,
  
  -- Generate a configuration file for Neovim configs
  generate_config = function(self, project_root, options)
    options = options or {}
    
    -- Generate stylua.toml if it doesn't exist
    local stylua_path = project_root .. "/.stylua.toml"
    if vim.fn.filereadable(stylua_path) ~= 1 then
      local stylua_config = self:get_linter_config(project_root).stylua.default_config
      local stylua_file = io.open(stylua_path, "w")
      if stylua_file then
        stylua_file:write(stylua_config)
        stylua_file:close()
      end
    end
    
    -- Generate luacheckrc if it doesn't exist
    local luacheckrc_path = project_root .. "/.luacheckrc"
    if vim.fn.filereadable(luacheckrc_path) ~= 1 then
      local luacheckrc_config = self:get_linter_config(project_root).luacheck.default_config
      local luacheckrc_file = io.open(luacheckrc_path, "w")
      if luacheckrc_file then
        luacheckrc_file:write(luacheckrc_config)
        luacheckrc_file:close()
      end
    end
    
    -- Generate minimal test setup if requested and no tests exist
    if options.setup_tests and options.test_framework then
      local test_dir
      if options.test_framework == "plenary" then
        test_dir = project_root .. "/tests"
      elseif options.test_framework == "lust-next" then
        test_dir = project_root .. "/spec"
      end
      
      if test_dir and vim.fn.isdirectory(test_dir) ~= 1 then
        vim.fn.mkdir(test_dir, "p")
        
        -- Create a basic test file
        local test_file_path
        if options.test_framework == "plenary" then
          test_file_path = test_dir .. "/config_spec.lua"
        else
          test_file_path = test_dir .. "/config_test.lua"
        end
        
        local test_file = io.open(test_file_path, "w")
        if test_file then
          if options.test_framework == "plenary" then
            test_file:write([[
-- Basic test for Neovim configuration
local assert = require("luassert")

describe("Neovim configuration", function()
  it("can load init.lua without errors", function()
    -- This test assumes we're running in the minimal init environment
    -- Simply reaching this point means init.lua loaded successfully
    assert.truthy(true)
  end)
end)
]])
          else
            test_file:write([[
-- Basic test for Neovim configuration
describe("Neovim configuration", function()
  it("can be loaded without errors", function()
    -- This test is just a placeholder
    -- Real tests would validate configuration behavior
    assert(true, "Configuration loaded successfully")
  end)
end)
]])
          end
          test_file:close()
        end
      end
    end
    
    return true, "Configuration files generated for Neovim configuration"
  end,
  
  -- Hook into pre-commit process for Neovim configs
  pre_commit_hook = function(self, project_root, files)
    -- Additional Neovim config-specific checks
    
    -- Check if any plugin specifications were changed (for lazy.nvim or packer)
    local plugin_changes = false
    for _, file in ipairs(files or {}) do
      if file:match("^lua/plugins") or file:match("plugins%.lua$") then
        plugin_changes = true
        break
      end
    end
    
    if plugin_changes then
      -- Recommend running Neovim to verify plugins load correctly
      print("Warning: Changes to plugin specifications detected.")
      print("Remember to test with 'nvim --headless +\"lua print('All plugins loaded')\" +qa' before committing.")
    end
    
    return true -- Continue with commit
  end,
  
  -- Get version verification configuration for Neovim configs
  get_version_config = function(self, project_root)
    -- Neovim configs typically don't have versions, but we can check for a version file
    local version_file = "lua/config/version.lua"
    
    -- Check if version.lua exists
    if vim.fn.filereadable(project_root .. "/" .. version_file) ~= 1 then
      -- Try alternative locations
      local alt_locations = {
        "lua/version.lua",
        "version.lua", 
      }
      
      for _, location in ipairs(alt_locations) do
        if vim.fn.filereadable(project_root .. "/" .. location) == 1 then
          version_file = location
          break
        end
      end
    end
    
    -- If no version file was found, version checking is not applicable
    local has_version = vim.fn.filereadable(project_root .. "/" .. version_file) == 1
    
    -- Return version configuration (disabled if no version file found)
    return {
      enabled = has_version,
      version_file = version_file,
      patterns = has_version and {
        -- Files that should contain version references
        {
          path = "README.md", 
          pattern = "Version: v(%d+%.%d+%.%d+)"
        },
      } or {}
    }
  end,
  
  -- NEW FUNCTIONS BELOW
  
  -- Setup mock Neovim environment for testing
  setup_mock_neovim = function(self, project_root)
    local minimal_init_dir = project_root .. "/tests"
    local minimal_init_path = minimal_init_dir .. "/minimal_init.lua"
    
    -- Create tests directory if it doesn't exist
    if lfs.attributes(minimal_init_dir, "mode") ~= "directory" then
      lfs.mkdir(minimal_init_dir)
    end
    
    -- Create minimal_init.lua if it doesn't exist
    local file = io.open(minimal_init_path, "r")
    if not file then
      file = io.open(minimal_init_path, "w")
      if file then
        file:write([[
-- Minimal init.lua for testing Neovim configuration
-- Generated by hooks-util

-- Set runtimepath to include this configuration
local config_path = vim.fn.expand('<sfile>:p:h:h')
vim.opt.runtimepath:prepend(config_path)

-- Prevent loading plugins for faster testing
vim.g.loaded_remote_plugins = 1

-- Disable built-in plugins
local disabled_built_ins = {
  'gzip', 'zip', 'zipPlugin', 'tar', 'tarPlugin',
  'getscript', 'getscriptPlugin', 'vimball', 'vimballPlugin',
  'matchit', 'matchparen', 'logiPat', 'rrhelper', 'netrw',
  'netrwPlugin', 'netrwSettings', 'netrwFileHandlers',
}

for _, plugin in ipairs(disabled_built_ins) do
  vim.g['loaded_' .. plugin] = 1
end

-- Minimal plugin loader mock
_G.mock_plugins = {}
_G.register_plugin = function(name, config)
  _G.mock_plugins[name] = config
end

-- Mock keymap functions
_G.keymap_calls = {}
local original_keymap = vim.keymap.set
vim.keymap.set = function(mode, lhs, rhs, opts)
  table.insert(_G.keymap_calls, {mode = mode, lhs = lhs, rhs = rhs, opts = opts})
  return original_keymap(mode, lhs, rhs, opts)
end

-- Setup global test helpers
_G.test_helpers = {
  verify_plugin_loaded = function(plugin_name)
    return _G.mock_plugins[plugin_name] ~= nil
  end,
  
  verify_keymap = function(mode, lhs)
    for _, keymap in ipairs(_G.keymap_calls) do
      if keymap.mode == mode and keymap.lhs == lhs then
        return true
      end
    end
    return false
  end,
  
  reset = function()
    _G.mock_plugins = {}
    _G.keymap_calls = {}
  end
}

-- Setup basic autocmds for testing
vim.api.nvim_create_augroup('test_config', {clear = true})

-- Print confirmation
print('Minimal Neovim test environment loaded')
]])
        file:close()
        
        -- Make the file executable
        os.execute("chmod +x " .. minimal_init_path)
      end
    else
      file:close()
    end
    
    -- Create test script
    local test_script_path = minimal_init_dir .. "/test_config.lua"
    file = io.open(test_script_path, "r")
    if not file then
      file = io.open(test_script_path, "w")
      if file then
        file:write([[
-- Basic tests for Neovim configuration
-- Generated by hooks-util

-- Load minimal init environment
require('minimal_init')

-- Tests for basic configuration loading
local function test_basic_setup()
  -- Check if basic setup works without errors
  require('config')
  print('Basic configuration loaded successfully')
  return true
end

-- Tests for plugin loading
local function test_plugins_load()
  -- Attempt to load plugins
  local ok, _ = pcall(require, 'plugins')
  if not ok then
    print('WARNING: Could not load plugins module')
    return false
  end
  
  -- Check if some plugins were registered
  local plugin_count = 0
  for _ in pairs(_G.mock_plugins) do
    plugin_count = plugin_count + 1
  end
  
  print('Loaded ' .. plugin_count .. ' plugins')
  return plugin_count > 0
end

-- Run the tests
local results = {
  basic_setup = test_basic_setup(),
  plugins_load = test_plugins_load()
}

-- Print results
print('\nTest Results:')
for test_name, result in pairs(results) do
  print(test_name .. ': ' .. (result and 'PASS' or 'FAIL'))
end
]])
        file:close()
      end
    else
      file:close()
    end
    
    return {
      minimal_init = minimal_init_path,
      test_script = test_script_path
    }
  end,
  
  -- Validate Neovim configuration
  validate_config = function(self, project_root)
    local errors = {}
    local warnings = {}
    
    -- Check for common configuration issues
    
    -- Check init.lua exists
    local init_lua = project_root .. "/init.lua"
    local init_vim = project_root .. "/init.vim"
    
    local has_init = false
    if io.open(init_lua, "r") then
      has_init = true
    elseif io.open(init_vim, "r") then
      has_init = true
      table.insert(warnings, "Using init.vim instead of init.lua. Consider migrating to Lua for better maintainability.")
    end
    
    if not has_init then
      table.insert(errors, "Missing init.lua or init.vim file. Neovim config requires a main entry point.")
    end
    
    -- Check for config organization structure
    local has_lua_dir = lfs.attributes(project_root .. "/lua", "mode") == "directory"
    if not has_lua_dir then
      table.insert(warnings, "Missing lua directory. Consider organizing configuration in Lua modules.")
    else
      -- Check for common structure patterns
      local common_modules = {
        "options.lua", "keymaps.lua", "plugins.lua", "autocmds.lua", "config", "plugins"
      }
      
      local found_modules = 0
      for _, module in ipairs(common_modules) do
        local path = project_root .. "/lua/" .. module
        if io.open(path, "r") or lfs.attributes(path, "mode") == "directory" then
          found_modules = found_modules + 1
        end
      end
      
      if found_modules < 2 then
        table.insert(warnings, "Config doesn't follow common module structure. Consider organizing with separate modules.")
      end
    end
    
    -- Check for plugin manager
    local plugin_managers = {
      "packer_compiled.lua", -- Packer
      "lazy-lock.json",      -- Lazy.nvim
      "dein.toml",           -- Dein
      "plug.vim"             -- vim-plug
    }
    
    local has_plugin_manager = false
    for _, manager in ipairs(plugin_managers) do
      if io.open(project_root .. "/" .. manager, "r") or 
         io.open(project_root .. "/plugin/" .. manager, "r") or
         io.open(project_root .. "/.config/" .. manager, "r") then
        has_plugin_manager = true
        break
      end
    end
    
    if not has_plugin_manager then
      table.insert(warnings, "No recognized plugin manager found. Consider using a plugin manager like lazy.nvim.")
    end
    
    -- Check for README
    if not io.open(project_root .. "/README.md", "r") then
      table.insert(warnings, "Missing README.md. Add documentation for your Neovim configuration.")
    end
    
    return #errors == 0, errors, warnings
  end,
  
  -- Verify plugin loading
  verify_plugin_loading = function(self, project_root)
    local errors = {}
    local warnings = {}
    
    -- Setup mock Neovim environment if not already present
    local minimal_init = project_root .. "/tests/minimal_init.lua"
    if not io.open(minimal_init, "r") then
      self:setup_mock_neovim(project_root)
    end
    
    -- Check for plugins module
    local plugins_path = nil
    local plugins_candidates = {
      project_root .. "/lua/plugins.lua",
      project_root .. "/lua/plugins/init.lua"
    }
    
    for _, path in ipairs(plugins_candidates) do
      if io.open(path, "r") then
        plugins_path = path
        break
      end
    end
    
    if not plugins_path then
      table.insert(warnings, "Could not find plugins module. If you're using plugins, consider organizing them in lua/plugins.lua.")
    else
      -- Check plugin module content
      local file = io.open(plugins_path, "r")
      if file then
        local content = file:read("*all")
        file:close()
        
        -- Look for plugin manager patterns
        local has_plugin_setup = false
        
        if content:match("packer") then
          -- Packer pattern
          has_plugin_setup = true
        elseif content:match("lazy") then
          -- Lazy.nvim pattern
          has_plugin_setup = true
        elseif content:match("use") and content:match("plugin") then
          -- Generic plugin manager pattern
          has_plugin_setup = true
        end
        
        if not has_plugin_setup then
          table.insert(warnings, "Plugins file doesn't appear to use a standard plugin manager.")
        end
      end
    end
    
    -- Check lazy-load patterns
    if plugins_path then
      local file = io.open(plugins_path, "r")
      if file then
        local content = file:read("*all")
        file:close()
        
        -- Check for proper lazy-loading
        local has_lazy_load = content:match("event") or content:match("ft") or 
                             content:match("cmd") or content:match("keys")
        
        if not has_lazy_load then
          table.insert(warnings, "No lazy-loading patterns found. Consider lazy-loading plugins for better startup time.")
        end
      end
    end
    
    return #errors == 0, errors, warnings
  end,
  
  -- Get workflow configurations for this adapter
  get_workflow_configs = function(self)
    return {
      "ci.config.yml",
      "release.config.yml",
      "docs.config.yml"
    }
  end,
  
  -- Get base workflows that apply to this adapter
  get_applicable_workflows = function(self)
    return {
      "ci.yml",
      "markdown-lint.yml",
      "yaml-lint.yml",
      "scripts-lint.yml",
      "docs.yml",
      "release.yml"
    }
  end
})

return nvim_config_adapter