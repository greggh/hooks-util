-- hooks-util/spec/adapters/nvim_config_spec.lua
-- Tests for the Neovim configuration adapter

local lust = require("hooks-util.lust-next")
local describe, it, expect = lust.describe, lust.it, lust.expect
local mock = require("lust-mock")

-- Mock the file system functions
local lfs_mock = mock.new()
mock.register("lfs", lfs_mock)

-- Mock io.open function
local io_mock = mock.new()
io_mock.open = function(path, mode)
  if path:match("/init.lua$") then
    return {
      read = function() 
        return [[
-- Neovim configuration
require('config.options')
require('config.plugins')
require('config.keymaps')
]]
      end,
      close = function() end
    }
  elseif path:match("/lua/plugins.lua$") then
    return {
      read = function() 
        return [[
return {
  -- Package manager
  { 'folke/lazy.nvim' },
  
  -- Colorscheme
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme('catppuccin-mocha')
    end
  },
  
  -- LSP
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'mason.nvim',
      'mason-lspconfig.nvim',
    },
    config = function()
      require('config.lsp')
    end
  }
}
]]
      end,
      close = function() end
    }
  elseif path:match("/README.md$") then
    return {
      read = function() return "# Neovim Configuration" end,
      close = function() end
    }
  elseif path:match("/tests/minimal_init.lua$") then
    return {
      read = function() return "-- Minimal init file" end,
      close = function() end
    }
  elseif path:match("/tests/test_config.lua$") then
    return {
      read = function() return "-- Test file" end,
      close = function() end
    }
  elseif mode == "w" then
    -- For files being written
    return {
      write = function() return true end,
      close = function() end
    }
  end
  
  return nil
end
mock.register("io", io_mock)

-- Mock os.execute
local os_mock = mock.new()
os_mock.execute = function(cmd)
  return 0 -- Success
end
mock.register("os", os_mock)

-- Load the adapter
local adapter = require("hooks-util.adapters.nvim-config")

describe("nvim-config adapter", function()
  
  -- Create a mock project root for testing
  local project_root = "/mock/nvim_config"
  
  -- Mock necessary functions/components
  lfs_mock.attributes = function(path, attr)
    if path == project_root .. "/lua" and attr == "mode" then
      return "directory"
    elseif path == project_root .. "/tests" and attr == "mode" then
      return "directory"
    elseif path == project_root .. "/lua/config" and attr == "mode" then
      return "directory"
    elseif path == project_root .. "/lua/plugins" and attr == "mode" then
      return "directory"
    end
    
    return nil
  end
  
  lfs_mock.dir = function(path)
    if path == project_root .. "/lua" then
      local i = 0
      local items = {".", "..", "config", "plugins", "plugins.lua", "options.lua", "keymaps.lua"}
      return function()
        i = i + 1
        return items[i]
      end
    end
    
    return function() return nil end
  end
  
  lfs_mock.mkdir = function(path)
    return true
  end
  
  describe("setup_mock_neovim", function()
    it("should set up mock Neovim environment", function()
      local result = adapter:setup_mock_neovim(project_root)
      expect(result).to.be.a("table")
      expect(result.minimal_init).to.match("minimal_init.lua$")
      expect(result.test_script).to.match("test_config.lua$")
    end)
  end)
  
  describe("validate_config", function()
    it("should validate Neovim configuration", function()
      local success, errors, warnings = adapter:validate_config(project_root)
      expect(success).to.be(true)
      expect(#errors).to.be(0)
    end)
  end)
  
  describe("verify_plugin_loading", function()
    it("should verify plugin loading", function()
      local success, errors, warnings = adapter:verify_plugin_loading(project_root)
      expect(success).to.be(true)
      expect(#errors).to.be(0)
    end)
  end)
  
  describe("get_workflow_configs", function()
    it("should return workflow configurations", function()
      local configs = adapter:get_workflow_configs()
      expect(#configs).to.be.at_least(1)
    end)
  end)
  
  describe("get_applicable_workflows", function()
    it("should return applicable workflows", function()
      local workflows = adapter:get_applicable_workflows()
      expect(#workflows).to.be.at_least(3)
    end)
  end)
end)