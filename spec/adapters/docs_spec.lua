-- hooks-util/spec/adapters/docs_spec.lua
-- Tests for the docs adapter

local lust = require("hooks-util.lust-next")
local describe, it, expect = lust.describe, lust.it, lust.expect
local mock = require("lust-mock")

-- Mock the file system functions
local lfs_mock = mock.new()
mock.register("lfs", lfs_mock)

-- Mock io.open function
local io_mock = mock.new()
io_mock.open = function(path, mode)
  if path:match("/mkdocs.yml$") then
    return {
      read = function() 
        return [[
site_name: Documentation Project
theme: material
]]
      end,
      close = function() end
    }
  elseif path:match("/docs/index.md$") then
    return {
      read = function() return "# Documentation Project" end,
      close = function() end
    }
  elseif path:match("/README.md$") then
    return {
      read = function() return "# Documentation Project" end,
      close = function() end
    }
  end
  
  return nil
end
mock.register("io", io_mock)

-- Load the adapter
local adapter = require("hooks-util.adapters.docs")

describe("docs adapter", function()
  
  -- Create a mock project root for testing
  local project_root = "/mock/docs_project"
  
  -- Mock necessary functions/components
  lfs_mock.attributes = function(path, attr)
    if path == project_root .. "/docs" and attr == "mode" then
      return "directory"
    end
    
    return nil
  end
  
  lfs_mock.dir = function(path)
    if path == project_root then
      local i = 0
      local items = {".", "..", "mkdocs.yml", "docs", "README.md"}
      return function()
        i = i + 1
        return items[i]
      end
    elseif path == project_root .. "/docs" then
      local i = 0
      local items = {".", "..", "index.md", "guide.md", "api.md"}
      return function()
        i = i + 1
        return items[i]
      end
    end
    
    return function() return nil end
  end
  
  describe("detect", function()
    it("should detect documentation projects", function()
      local result = adapter:detect(project_root)
      expect(result).to.be(true)
    end)
  end)
  
  describe("setup_config", function()
    it("should set up documentation project configuration", function()
      local config = adapter:setup_config({})
      expect(config).to.be.a("table")
      expect(config.markdown).to.be.a("table")
      expect(config.markdown.enabled).to.be(true)
      expect(config.yaml).to.be.a("table")
      expect(config.yaml.enabled).to.be(true)
    end)
  end)
  
  describe("validate_docs_structure", function()
    it("should validate documentation structure", function()
      local success, errors = adapter:validate_docs_structure(project_root)
      expect(success).to.be(true)
      expect(errors).to.be.a("table")
      expect(#errors).to.be(0)
    end)
  end)
  
  describe("validate_cross_references", function()
    it("should validate cross-references", function()
      local success, errors = adapter:validate_cross_references(project_root)
      expect(success).to.be(true)
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
  
  describe("get_linter_config", function()
    it("should return linter configuration including stylua and luacheck", function()
      local config = adapter:get_linter_config(project_root)
      expect(config).to.be.a("table")
      expect(config.stylua).to.be.a("table")
      expect(config.stylua.enabled).to.be(true)
      expect(config.luacheck).to.be.a("table")
      expect(config.luacheck.enabled).to.be(true)
    end)
  end)
  
  describe("generate_config", function()
    it("should generate configuration files", function()
      local success, messages = adapter:generate_config(project_root)
      expect(success).to.be(true)
      expect(messages).to.be.a("table")
      expect(#messages).to.be.at_least(1)
    end)
  end)
end)