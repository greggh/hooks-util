-- hooks-util/adapters/nvim-config/init.lua
-- Adapter for Neovim configurations
local adapter = require("hooks-util.core.adapter")

-- Create the Neovim config adapter
local nvim_config_adapter = adapter.create({
  name = "nvim-config",
  description = "Adapter for Neovim configuration directories",
  version = "0.1.0",
  
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
  end
})

return nvim_config_adapter