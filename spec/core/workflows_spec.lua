-- hooks-util/spec/core/workflows_spec.lua
-- Tests for the workflow management system

local lust = require("hooks-util.lust-next")
local describe, it, expect = lust.describe, lust.it, lust.expect
local mock = require("lust-mock")

-- Mock dependencies
local yaml_util_mock = mock.new()
yaml_util_mock.read = function(file_path)
  if file_path:match("ci.yml$") then
    -- Base workflow mock
    return {
      name = "CI",
      on = {
        push = {
          branches = {"main"}
        },
        pull_request = {
          branches = {"main"}
        }
      },
      jobs = {
        test = {
          name = "Run Tests",
          ["runs-on"] = "ubuntu-latest",
          steps = {
            {
              name = "Checkout code",
              uses = "actions/checkout@v3"
            },
            {
              name = "Run tests",
              run = "echo 'Running tests'"
            }
          }
        }
      }
    }
  elseif file_path:match("ci.config.yml$") then
    -- Adapter config mock
    return {
      jobs = {
        test = {
          strategy = {
            matrix = {
              ["lua-version"] = {"5.1", "5.2", "5.3"}
            }
          },
          steps = {
            {
              name = "Additional step",
              run = "echo 'Additional step'"
            }
          }
        }
      }
    }
  end
  
  return nil
end

yaml_util_mock.write = function(data, file_path)
  return true
end

yaml_util_mock.merge = function(base, extension)
  if not base or not extension then
    return base or extension
  end
  
  -- Simple recursive merge for testing
  local result = {}
  
  -- Copy base
  for k, v in pairs(base) do
    result[k] = v
  end
  
  -- Merge extension
  for k, v in pairs(extension) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = yaml_util_mock.merge(result[k], v)
    else
      result[k] = v
    end
  end
  
  return result
end

local lib_mock = mock.new()
lib_mock["yaml_util.lua"] = yaml_util_mock
mock.register("../lib", lib_mock, function(path)
  return path:match("([^/]+)$")
end)

-- Mock file system for workflow installation
local io_mock = mock.new()
io_mock.open = function(path, mode)
  return {
    read = function() return "" end,
    write = function() return true end,
    close = function() end
  }
end
mock.register("io", io_mock)

local os_mock = mock.new()
os_mock.execute = function(cmd)
  return 0 -- Success
end
mock.register("os", os_mock)

-- Load the workflows module
local dofile_original = _G.dofile
_G.dofile = function(path)
  if path:match("yaml_util.lua$") then
    return yaml_util_mock
  end
  return dofile_original(path)
end

local workflows = require("hooks-util.core.workflows")

describe("workflows management", function()

  -- Create a mock project
  local target_dir = "/mock/project"
  local adapter_name = "lua-lib"
  
  describe("get_base_workflow_path", function()
    it("should return the base workflow path", function()
      local path = workflows.get_base_workflow_path("ci.yml")
      expect(path).to.match("workflows/ci.yml$")
    end)
  end)
  
  describe("get_adapter_config_path", function()
    it("should return the adapter config path", function()
      local path = workflows.get_adapter_config_path("lua-lib", "ci.yml")
      expect(path).to.match("configs/lua%-lib/ci.config.yml$")
    end)
  end)
  
  describe("merge_workflow", function()
    it("should merge base and adapter workflows", function()
      local base_workflow = "../ci/github/workflows/ci.yml"
      local adapter_config = "../ci/github/configs/lua-lib/ci.config.yml"
      
      local result = workflows.merge_workflow(base_workflow, adapter_config)
      
      expect(result).to.be.a("table")
      -- Verify base elements exist
      expect(result.name).to.be("CI")
      expect(result.on).to.be.a("table")
      expect(result.jobs).to.be.a("table")
      expect(result.jobs.test).to.be.a("table")
      
      -- Verify adapter extensions are merged
      expect(result.jobs.test.strategy).to.be.a("table")
      expect(result.jobs.test.strategy.matrix).to.be.a("table")
      expect(result.jobs.test.strategy.matrix["lua-version"]).to.be.a("table")
    end)
  end)
  
  describe("install_workflow", function()
    it("should install a workflow", function()
      local success = workflows.install_workflow("ci.yml", target_dir, adapter_name)
      expect(success).to.be(true)
    end)
  end)
  
  describe("install_workflows", function()
    it("should install all applicable workflows", function()
      -- Configure workflows
      workflows.setup({
        workflows = {
          ci = true,
          markdown_lint = true,
          yaml_lint = true
        }
      })
      
      local success = workflows.install_workflows(target_dir, adapter_name)
      expect(success).to.be(true)
    end)
  end)
end)

-- Restore original dofile
_G.dofile = dofile_original