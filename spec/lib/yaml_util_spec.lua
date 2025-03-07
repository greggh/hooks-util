-- hooks-util/spec/lib/yaml_util_spec.lua
-- Tests for the YAML utilities module

local lust = require("hooks-util.lust-next")
local describe, it, expect = lust.describe, lust.it, lust.expect
local mock = require("lust-mock")

-- Mock dependencies
local yaml_mock = mock.new()
yaml_mock.load = function(yaml_str)
  -- Simple YAML parser mock for testing
  if yaml_str:match("name: CI") then
    return {
      name = "CI",
      on = {
        push = {
          branches = {"main"}
        }
      },
      jobs = {
        test = {
          steps = {
            {name = "First step"}
          }
        }
      }
    }
  elseif yaml_str:match("jobs:") then
    return {
      jobs = {
        test = {
          steps = {
            {name = "Extension step"}
          }
        }
      }
    }
  end
  
  return {}
end

yaml_mock.dump = function(data)
  -- Simple YAML dumper mock
  if data.name and data.name == "CI" then
    return "name: CI\non:\n  push:\n    branches: [main]\njobs:\n  test:\n    steps:\n    - name: First step\n"
  end
  
  return "# Empty YAML"
end

mock.register("yaml", yaml_mock)

-- Mock file system
local io_mock = mock.new()
io_mock.open = function(path, mode)
  if path:match("base.yml$") then
    return {
      read = function() return "name: CI\non:\n  push:\n    branches: [main]\njobs:\n  test:\n    steps:\n    - name: First step\n" end,
      write = function() return true end,
      close = function() end
    }
  elseif path:match("extension.yml$") then
    return {
      read = function() return "jobs:\n  test:\n    steps:\n    - name: Extension step\n" end,
      write = function() return true end,
      close = function() end
    }
  elseif path:match("output.yml$") or mode == "w" then
    return {
      read = function() return "" end,
      write = function() return true end,
      close = function() end
    }
  end
  
  return nil
end
mock.register("io", io_mock)

-- Load yaml_util using actual path
local yaml_util = dofile("/home/gregg/Projects/lua-library/hooks-util/lib/yaml_util.lua")

describe("yaml_util", function()
  describe("read", function()
    it("should read and parse YAML file", function()
      local result = yaml_util.read("/mock/base.yml")
      expect(result).to.be.a("table")
      expect(result.name).to.be("CI")
      expect(result.on).to.be.a("table")
      expect(result.jobs).to.be.a("table")
      expect(result.jobs.test).to.be.a("table")
      expect(result.jobs.test.steps).to.be.a("table")
      expect(result.jobs.test.steps[1].name).to.be("First step")
    end)
    
    it("should return nil for non-existent file", function()
      local result = yaml_util.read("/mock/nonexistent.yml")
      expect(result).to.be(nil)
    end)
  end)
  
  describe("write", function()
    it("should write YAML data to file", function()
      local data = {
        name = "CI",
        on = {
          push = {
            branches = {"main"}
          }
        },
        jobs = {
          test = {
            steps = {
              {name = "First step"}
            }
          }
        }
      }
      
      local result = yaml_util.write(data, "/mock/output.yml")
      expect(result).to.be(true)
    end)
  end)
  
  describe("merge", function()
    it("should merge base and extension YAML data", function()
      local base = {
        name = "Base",
        on = {
          push = {
            branches = {"main"}
          }
        },
        jobs = {
          test = {
            name = "Test Job",
            runs_on = "ubuntu-latest",
            steps = {
              {name = "First step"}
            }
          }
        }
      }
      
      local extension = {
        jobs = {
          test = {
            strategy = {
              matrix = {
                lua_version = {"5.1", "5.2"}
              }
            },
            steps = {
              {name = "Extension step"}
            }
          },
          lint = {
            name = "Lint Job"
          }
        }
      }
      
      local result = yaml_util.merge(base, extension)
      
      expect(result.name).to.be("Base") -- Preserved from base
      expect(result.on.push.branches[1]).to.be("main") -- Preserved from base
      expect(result.jobs.test.name).to.be("Test Job") -- Preserved from base
      expect(result.jobs.test.strategy.matrix.lua_version[1]).to.be("5.1") -- Added from extension
      expect(result.jobs.lint.name).to.be("Lint Job") -- Added from extension
      
      -- In a real implementation, the steps would be properly merged
      -- This simplified test doesn't check that
    end)
    
    it("should handle nil values", function()
      local base = nil
      local extension = {name = "Extension"}
      
      local result = yaml_util.merge(base, extension)
      expect(result.name).to.be("Extension")
      
      result = yaml_util.merge(extension, nil)
      expect(result.name).to.be("Extension")
      
      result = yaml_util.merge(nil, nil)
      expect(result).to.be(nil)
    end)
  end)
  
  describe("merge_files", function()
    it("should merge two YAML files", function()
      local result = yaml_util.merge_files("/mock/base.yml", "/mock/extension.yml", "/mock/output.yml")
      expect(result).to.be(true)
    end)
  end)
end)