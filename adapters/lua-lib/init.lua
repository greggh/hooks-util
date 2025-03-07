-- hooks-util/adapters/lua-lib/init.lua
-- Adapter for general Lua libraries
local adapter = require("hooks-util.core.adapter")
local lfs = require("lfs")

-- Create the Lua Library adapter
local lua_lib_adapter = adapter.create({
  name = "lua-lib",
  description = "Adapter for general Lua libraries and modules",
  version = "0.2.0", -- Version updated to reflect new functionality
  
  -- Check if this adapter is compatible with the project
  is_compatible = function(self, project_root)
    -- Check for common Lua library markers
    local markers = {
      "rockspec",          -- LuaRocks spec file
      "*.rockspec",        -- LuaRocks spec wildcard
      "spec",              -- Test directory
      "lib/lua",           -- Common library path
      "lua/",              -- Lua source directory
      "Makefile",          -- Build file
      "CMakeLists.txt",    -- CMake build file
    }
    
    -- Check if any marker exists
    for _, marker in ipairs(markers) do
      -- Handle wildcards by using glob
      if marker:find("*") then
        local result = vim.fn.globpath(project_root, marker, true)
        if result and result ~= "" then
          return true
        end
      else
        -- Standard file check
        local path = project_root .. "/" .. marker
        if vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1 then
          return true
        end
      end
    end
    
    -- If we have Lua files but it's not a Neovim plugin or config
    local has_lua_files = false
    local lua_files = vim.fn.globpath(project_root, "**/*.lua", true)
    has_lua_files = lua_files and lua_files ~= ""
    
    -- Check if project has nvim-specific patterns
    local neovim_markers = {
      "init.lua",            -- Main Neovim file
      "lua/*/init.lua",      -- Neovim plugin structure
      "plugin/*.lua",        -- Plugin loader file
      "after/plugin/*.lua",  -- After plugins
      "lua/plugins",         -- Plugins directory
      "lua/lsp",             -- LSP config
    }
    
    local is_neovim_project = false
    for _, marker in ipairs(neovim_markers) do
      local result = vim.fn.globpath(project_root, marker, true)
      if result and result ~= "" then
        is_neovim_project = true
        break
      end
    end
    
    -- If it has Lua files but isn't a Neovim project, it's likely a general Lua library
    return has_lua_files and not is_neovim_project
  end,
  
  -- Get linter configuration for Lua libraries
  get_linter_config = function(self, project_root)
    return {
      stylua = {
        enabled = true,
        config_file = ".stylua.toml",
        -- Default config for Lua libraries
        default_config = [[
column_width = 100
line_endings = "Unix"
indent_type = "Spaces"
indent_width = 2
quote_style = "AutoPreferSingle"
call_parentheses = "Always"
]]
      },
      luacheck = {
        enabled = true,
        config_file = ".luacheckrc",
        -- Default config for Lua libraries
        default_config = [[
-- vim: ft=lua tw=80

std = "lua51"

-- Add third-party modules that are commonly used
files["spec/**/*.lua"].std = "+busted"

-- Global objects defined by the project
globals = {
  -- Add your project's global variables here
}

-- Excludes
exclude_files = {
  "test/fixtures/**/*.lua",
  ".luarocks/**/*.lua",
  "lua_modules/**/*.lua",
}

ignore = {
  "212/_.*", -- Unused argument, for callbacks
  "631", -- Line is too long
}
]]
      },
      shellcheck = {
        enabled = true,
      },
    }
  end,
  
  -- Get test configuration for Lua libraries
  get_test_config = function(self, project_root)
    -- Check for common test frameworks in Lua libraries
    
    -- Busted is a common test framework for Lua
    local has_busted = false
    local busted_spec = project_root .. "/spec"
    if vim.fn.isdirectory(busted_spec) == 1 then
      has_busted = true
    end
    
    -- lust-next typically uses a spec directory too
    local has_lust_next = false
    if vim.fn.isdirectory(busted_spec) == 1 then
      local runner_path = busted_spec .. "/runner.lua"
      has_lust_next = vim.fn.filereadable(runner_path) == 1
    end
    
    -- Check for LuaUnit (usually used with a test directory)
    local has_luaunit = false
    local test_dir = project_root .. "/test"
    if vim.fn.isdirectory(test_dir) == 1 then
      -- Look for test files that might use LuaUnit
      local test_files = vim.fn.globpath(test_dir, "**/*.lua", true)
      if test_files and test_files ~= "" then
        -- Read some test files to check for LuaUnit patterns
        for file in test_files:gmatch("[^\n]+") do
          local f = io.open(file, "r")
          if f then
            local content = f:read("*a")
            f:close()
            if content and (content:match("luaunit") or content:match("assertTrue") or content:match("assertEquals")) then
              has_luaunit = true
              break
            end
          end
        end
      end
    end
    
    -- Determine test command based on the framework
    local test_command
    local framework
    
    if has_lust_next then
      test_command = "lua spec/runner.lua"
      framework = "lust-next"
    elseif has_busted then
      test_command = "busted ."
      framework = "busted"
    elseif has_luaunit then
      test_command = "lua test/run_tests.lua"
      framework = "luaunit"
    else
      -- Check for a Makefile with a test target
      local makefile_path = project_root .. "/Makefile"
      local has_makefile_test = false
      
      if vim.fn.filereadable(makefile_path) == 1 then
        local f = io.open(makefile_path, "r")
        if f then
          local content = f:read("*a")
          f:close()
          if content and content:match("test:") then
            has_makefile_test = true
          end
        end
      end
      
      if has_makefile_test then
        test_command = "make test"
        framework = "make"
      else
        -- Default to a more general command if no specific framework was detected
        if vim.fn.isdirectory(project_root .. "/spec") == 1 then
          test_command = "cd spec && lua *.lua"
          framework = "generic"
        elseif vim.fn.isdirectory(project_root .. "/test") == 1 then
          test_command = "cd test && lua *.lua"
          framework = "generic"
        else
          test_command = "echo 'No tests found'"
          framework = nil
          return {
            enabled = false,
            framework = nil,
            test_command = nil,
            timeout = 60000,
          }
        end
      end
    end
    
    return {
      enabled = true,
      framework = framework,
      test_command = test_command,
      timeout = 60000, -- 60 seconds
    }
  end,
  
  -- Get CI workflow templates for Lua libraries
  get_ci_templates = function(self, project_root, platform)
    -- Return platform-specific template paths
    if platform == "github" then
      return {
        "/home/gregg/Projects/hooks-util/ci/github/lua-lib-ci.yml",
        "/home/gregg/Projects/hooks-util/ci/github/lua-lib-docs.yml",
        "/home/gregg/Projects/hooks-util/ci/github/lua-lib-release.yml",
      }
    elseif platform == "gitlab" then
      return {
        "/home/gregg/Projects/hooks-util/ci/gitlab/lua-lib-ci.yml",
      }
    elseif platform == "azure" then
      return {
        "/home/gregg/Projects/hooks-util/ci/azure/lua-lib-ci.yml",
      }
    end
    
    return {}
  end,
  
  -- Generate a configuration file for Lua libraries
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
    
    -- Generate rockspec file if requested and doesn't exist
    if options.create_rockspec and not vim.fn.globpath(project_root, "*.rockspec", true) then
      local project_name = vim.fn.fnamemodify(project_root, ":t")
      local rockspec_path = project_root .. "/" .. project_name .. "-dev-1.rockspec"
      
      local rockspec_file = io.open(rockspec_path, "w")
      if rockspec_file then
        rockspec_file:write(string.format([=[
package = "%s"
version = "dev-1"

source = {
  url = "git://github.com/username/%s",
  tag = "dev"
}

description = {
  summary = "A Lua library for...",
  detailed = [[
    A detailed description of the library.
  ]],
  homepage = "https://github.com/username/%s",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1"
}

build = {
  type = "builtin",
  modules = {
    ["%s"] = "lua/%s/init.lua",
    ["%s.utils"] = "lua/%s/utils.lua",
    -- Add more modules as needed
  }
}
]=], 
          project_name, -- package name
          project_name, -- source url
          project_name, -- homepage
          project_name, -- modules name
          project_name, -- modules file
          project_name, -- modules.utils name 
          project_name  -- modules.utils file
        ))
        rockspec_file:close()
      end
    end
    
    -- Generate lust-next test setup if requested and no tests exist
    if options.setup_tests and options.test_framework == "lust-next" then
      local spec_dir = project_root .. "/spec"
      if vim.fn.isdirectory(spec_dir) ~= 1 then
        vim.fn.mkdir(spec_dir, "p")
        
        -- Create a runner file
        local runner_path = spec_dir .. "/runner.lua"
        local runner_file = io.open(runner_path, "w")
        if runner_file then
          runner_file:write([[
-- Test runner for lust-next
local project_root = require("lust-next").find_project_root()
local results = require("lust-next").run_tests({
  paths = { "spec" },        -- Run all tests in spec directory
  filter = nil,              -- Run all tests (no filter)
  verbose = true,           -- Detailed output
  stop_on_first_failure = false
})

-- Exit with appropriate status code
os.exit(results.failures > 0 and 1 or 0)
]])
          runner_file:close()
        end
        
        -- Create a basic test file
        local test_path = spec_dir .. "/basic_test.lua"
        local test_file = io.open(test_path, "w")
        if test_file then
          local project_name = vim.fn.fnamemodify(project_root, ":t")
          test_file:write(string.format([[
-- Basic tests for %s
describe("%s", function()
  -- Add setup code here if needed
  
  it("can be required", function()
    -- Try to require the main module
    local ok, module = pcall(require, "%s")
    assert(ok, "Module should be requireable")
    assert(module, "Module should not be nil")
  end)
  
  -- Add more tests here
end)
]], project_name, project_name, project_name))
          test_file:close()
        end
      end
    end
    
    return true, "Configuration files generated for Lua library"
  end,
  
  -- Hook into pre-commit process for Lua libraries
  pre_commit_hook = function(self, project_root, files)
    -- Version check
    local version_config = self:get_version_config(project_root)
    if version_config and version_config.enabled then
      -- TODO: Implement version check
    end
    
    -- Additional Lua library-specific checks
    
    -- Check if rockspec was modified
    local rockspec_modified = false
    for _, file in ipairs(files or {}) do
      if file:match("%.rockspec$") then
        rockspec_modified = true
        break
      end
    end
    
    if rockspec_modified then
      -- Validate rockspec format
      local rockspec_files = vim.fn.globpath(project_root, "*.rockspec", true)
      if rockspec_files and rockspec_files ~= "" then
        for rockspec_file in rockspec_files:gmatch("[^\n]+") do
          if vim.fn.filereadable(rockspec_file) == 1 then
            -- Execute luarocks to verify rockspec
            local result = os.execute("luarocks lint " .. rockspec_file .. " > /dev/null 2>&1")
            if result ~= 0 then
              print("Warning: Rockspec validation failed. Please run 'luarocks lint " .. vim.fn.fnamemodify(rockspec_file, ":t") .. "' to check for errors.")
            end
          end
        end
      end
    end
    
    return true -- Continue with commit
  end,
  
  -- Get version verification configuration for Lua libraries
  get_version_config = function(self, project_root)
    -- Common version file locations for Lua libraries
    local version_file_locations = {
      "lua/version.lua",
      "src/version.lua",
      "lua/%s/version.lua", -- Project name will be inserted
    }
    
    -- Try to detect project name from rockspec or directory name
    local project_name = vim.fn.fnamemodify(project_root, ":t")
    local rockspec_files = vim.fn.globpath(project_root, "*.rockspec", true)
    if rockspec_files and rockspec_files ~= "" then
      local first_rockspec = rockspec_files:match("([^\n]+)")
      if first_rockspec then
        local base_name = vim.fn.fnamemodify(first_rockspec, ":t")
        project_name = base_name:match("^([^-]+)") or project_name
      end
    end
    
    -- Insert project name into template paths
    for i, location in ipairs(version_file_locations) do
      if location:find("%%s") then
        version_file_locations[i] = string.format(location, project_name)
      end
    end
    
    -- Find first existing version file
    local version_file = nil
    for _, location in ipairs(version_file_locations) do
      local full_path = project_root .. "/" .. location
      if vim.fn.filereadable(full_path) == 1 then
        version_file = location
        break
      end
    end
    
    -- If no version file found, use default location
    if not version_file then
      version_file = "lua/version.lua"
    end
    
    -- Build version patterns to check
    local patterns = {
      -- Files that should contain version references
      {
        path = "README.md", 
        pattern = "Version: v?(%d+%.%d+%.%d+)"
      },
      {
        path = "CHANGELOG.md",
        pattern = "## %[?v?(%d+%.%d+%.%d+)%]?"
      }
    }
    
    -- Add rockspec pattern if rockspec exists
    if rockspec_files and rockspec_files ~= "" then
      table.insert(patterns, {
        path = "*.rockspec",
        pattern = 'version = "(%d+%.%d+%.%d+)"'
      })
    end
    
    return {
      enabled = true,
      version_file = version_file,
      patterns = patterns
    }
  end,
  
  -- NEW FUNCTIONS BELOW
  
  -- Enhanced coverage tracking
  setup_coverage = function(self, project_root, options)
    local coverage_config = {
      enabled = true,
      tool = "luacov",
      threshold = 75, -- Minimum coverage percentage
      excludes = {
        "spec/*",
        "tests/*",
        ".*_spec%.lua$"
      },
      report_format = "default" -- Can be "default", "html", "coveralls"
    }
    
    -- Merge with provided options
    if options then
      for k, v in pairs(options) do
        if type(v) == "table" and type(coverage_config[k]) == "table" then
          for k2, v2 in pairs(v) do
            coverage_config[k][k2] = v2
          end
        else
          coverage_config[k] = v
        end
      end
    end
    
    -- Create luacov configuration file if needed
    if coverage_config.enabled then
      local luacov_path = project_root .. "/.luacov"
      local luacov_file = io.open(luacov_path, "w")
      if luacov_file then
        -- Write luacov configuration
        luacov_file:write("return {\n")
        luacov_file:write("  statsfile = 'luacov.stats.out',\n")
        luacov_file:write("  reportfile = 'luacov.report.out',\n")
        luacov_file:write("  exclude = {\n")
        
        for _, pattern in ipairs(coverage_config.excludes) do
          luacov_file:write(string.format('    "%s",\n', pattern))
        end
        
        luacov_file:write("  },\n")
        luacov_file:write("  includeuntestedfiles = true,\n")
        
        if coverage_config.threshold then
          luacov_file:write(string.format("  threshold = %d,\n", coverage_config.threshold))
        end
        
        luacov_file:write("}\n")
        luacov_file:close()
      end
    end
    
    return coverage_config
  end,
  
  -- LuaRocks validation
  validate_rockspec = function(self, project_root)
    local errors = {}
    local warnings = {}
    
    -- Find rockspec file
    local rockspec_pattern = project_root .. "/*.rockspec"
    local rockspec_files = {}
    for file in lfs.dir(project_root) do
      if file:match("%.rockspec$") then
        table.insert(rockspec_files, project_root .. "/" .. file)
      end
    end
    
    -- Check if rockspec file exists
    if #rockspec_files == 0 then
      table.insert(errors, "No rockspec file found. Lua libraries should have a rockspec file for LuaRocks.")
      return false, errors, warnings
    end
    
    -- If multiple rockspec files, warn about it
    if #rockspec_files > 1 then
      table.insert(warnings, "Multiple rockspec files found. This could cause confusion.")
    end
    
    -- Validate content of the first rockspec
    local rockspec_file = io.open(rockspec_files[1], "r")
    if rockspec_file then
      local content = rockspec_file:read("*all")
      rockspec_file:close()
      
      -- Check for required fields
      if not content:match("package%s*=") then
        table.insert(errors, "Rockspec missing 'package' field")
      end
      
      if not content:match("version%s*=") then
        table.insert(errors, "Rockspec missing 'version' field")
      end
      
      if not content:match("source%s*=") then
        table.insert(errors, "Rockspec missing 'source' field")
      end
      
      -- Check for description, which is recommended
      if not content:match("description%s*=") then
        table.insert(warnings, "Rockspec missing 'description' field")
      end
      
      -- Check for dependencies
      if not content:match("dependencies%s*=") then
        table.insert(warnings, "Rockspec missing 'dependencies' field")
      end
      
      -- Check for build section
      if not content:match("build%s*=") then
        table.insert(warnings, "Rockspec missing 'build' field")
      end
    end
    
    return #errors == 0, errors, warnings
  end,
  
  -- Setup multi-version testing
  setup_multi_version_testing = function(self, project_root, versions)
    local versions_to_test = versions or {"5.1", "5.2", "5.3", "5.4", "luajit"}
    local test_config = {
      enabled = true,
      versions = versions_to_test,
      test_command = "lua spec/runner.lua" -- Default test command
    }
    
    -- Create multi-version test script
    local script_path = project_root .. "/scripts/test_all_versions.sh"
    local script_dir = project_root .. "/scripts"
    
    -- Ensure scripts directory exists
    if lfs.attributes(script_dir, "mode") ~= "directory" then
      lfs.mkdir(script_dir)
    end
    
    -- Create the script
    local script_file = io.open(script_path, "w")
    if script_file then
      script_file:write("#!/bin/bash\n\n")
      script_file:write("# Test against multiple Lua versions\n")
      script_file:write("# Generated by hooks-util\n\n")
      
      script_file:write("set -e\n\n")
      
      for _, version in ipairs(versions_to_test) do
        script_file:write(string.format("echo \"Testing with Lua %s...\"\n", version))
        -- Handle LuaJIT as special case
        if version == "luajit" then
          script_file:write("if command -v luajit &> /dev/null; then\n")
          script_file:write("  luajit spec/runner.lua\n")
          script_file:write("else\n")
          script_file:write("  echo \"LuaJIT not available, skipping\"\n")
          script_file:write("fi\n\n")
        else
          script_file:write(string.format("if command -v lua%s &> /dev/null; then\n", version))
          script_file:write(string.format("  lua%s spec/runner.lua\n", version))
          script_file:write("else\n")
          script_file:write(string.format("  echo \"Lua %s not available, skipping\"\n", version))
          script_file:write("fi\n\n")
        end
      end
      
      script_file:write("echo \"All tests completed!\"\n")
      script_file:close()
      
      -- Make the script executable
      os.execute("chmod +x " .. script_path)
    end
    
    return test_config
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
      "release.yml",
      "dependency-updates.yml"
    }
  end
})

return lua_lib_adapter