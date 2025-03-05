# Lua Integration and Adapter System

## Project Type Adapter System

Hooks-util uses an adapter-based architecture to support different types of Lua projects. The adapter system automatically detects the type of project based on its structure, and then applies the appropriate configuration, hooks, and linting rules.

### Project Types

Hooks-util supports the following project types:

| Project Type | Description | Detection Criteria |
|--------------|-------------|-------------------|
| `neovim-config` | Neovim configuration directory | `init.lua` + patterns like `plugin/`, `after/`, `lazy-lock.json`, etc. |
| `neovim-plugin` | Neovim plugin project | `plugin/init.vim` or `lua/*/init.lua` structure |
| `lua-lib` | Lua library or module | Presence of `.rockspec` files or certain directory structures |
| `lua-project` | Generic Lua project | When no other specific type is detected |

### Adapter Interface

Each adapter provides:

1. **Detection Logic**: Determines if a project matches this type
2. **Hook Configuration**: Default hooks for this project type
3. **Linter Settings**: Appropriate linter configurations for the project type
4. **Testing Framework**: Recommended test frameworks for the project type

### Overriding Project Type

You can override the automatic detection by setting the `project_type` in `.hooks-util.lua`:

```lua
-- .hooks-util.lua
return {
  -- Project type configuration
  -- Valid values:
  --   "auto"           - Automatically detect project type (default)
  --   "neovim-plugin"  - Neovim plugin project
  --   "neovim-config"  - Neovim configuration directory
  --   "lua-lib"        - Lua library
  --   "lua-project"    - Generic Lua project
  project_type = "neovim-plugin",  -- Override auto-detection with specific type
  
  -- Other configuration options...
}
```

Setting `project_type = "auto"` (the default) will use the automatic detection system.

## Lua Configuration

Hooks-util supports Lua-based configuration with the following file:

```lua
-- .hooks-util.lua
return {
  -- Project type (auto or specific type)
  project_type = "auto",
  
  -- Configure which hooks should be run on pre-commit
  hooks = {
    pre_commit = {
      lint = true,       -- Run linting (luacheck, etc.)
      format = true,     -- Run formatting (stylua, etc.)
      test = true,       -- Run tests
      version = true,    -- Verify version consistency
    }
  },
  
  -- Configure linting options
  lint = {
    -- Specific linter configuration
    luacheck = {
      enabled = true,
      config_file = ".luacheckrc",        -- Path to luacheckrc file
      args = "--no-color",                -- Additional luacheck arguments
    },
    
    stylua = {
      enabled = true,
      config_file = "stylua.toml",        -- Path to stylua config
      check_only = false,                 -- Only check formatting without modifying files
    }
  },
  
  -- Configure testing options
  test = {
    -- Test configuration
    framework = "lust-next",             -- Test framework to use
    runner = "spec/runner.lua",          -- Path to test runner
    pattern = "**/*_spec.lua",           -- Pattern to discover test files
    args = "",                           -- Additional arguments for the test runner
    timeout = 60000,                     -- Test timeout in milliseconds
  },
  
  -- Configure CI workflow options
  ci = {
    platform = "github",                 -- github, gitlab, or azure
    workflow_dir = ".github/workflows",  -- Directory for workflow files
    matrix = {
      lua = {"5.1", "luajit"},           -- Lua versions to test against
      os = {"ubuntu-latest"},            -- OS platforms to test on
    }
  }
}
```

## Lust-Next Integration

The Lust-Next testing framework is integrated into hooks-util to provide a consistent testing experience across projects.

### Key Components

1. **Integration Module**: `lua/hooks-util/lust-next.lua` - Central integration point
2. **Test Runner**: `spec/runner.lua` - Discovers and runs tests
3. **Test Helper**: `spec/spec_helper.lua` - Provides utility functions for tests
4. **Test Setup**: `lust_next.setup_project()` - Sets up the test environment

### Integration API

```lua
local lust_next = require("hooks-util.lust-next")

-- Set up a project with lust-next testing
lust_next.setup_project("/path/to/project")

-- Generate CI workflow for the project
lust_next.generate_workflow("/path/to/project", "github")  -- github, gitlab, azure

-- Add lust-next as a dependency to the project
lust_next.add_as_dependency("/path/to/project", {
  method = "git",  -- "git" or "rockspec"
  path = "deps/lust-next"
})

-- Run tests
lust_next.run_tests("/path/to/project", {
  filter = "module_name",  -- Only run tests containing this pattern
  tags = "unit",           -- Only run tests with this tag
})
```

### Testing Structure

Lust-next tests are organized in a BDD-style with descriptive blocks:

```lua
describe("component", function()
  before_each(function()
    -- Set up test environment
  end)
  
  after_each(function()
    -- Clean up after tests
  end)
  
  it("does something specific", function()
    -- Test assertions
    assert(true, "This should pass")
  end)
  
  -- Use tags to organize tests
  it("does something async", function()
    -- Asynchronous test
  end, "async")
end)
```

## Core Modules API

### Adapter Module

```lua
local adapter = require("hooks-util.core.adapter")

-- Create a new adapter
local my_adapter = adapter.create_adapter("my-project-type", {
  description = "My custom project type"
})

-- Define validation logic
function my_adapter:validate(project)
  -- Return true if project matches this type
  return path.is_file(project.root .. "/my-specific-file")
end

-- Define hook configuration
function my_adapter:get_hooks()
  return {
    { name = "lint", command = "my-linter" },
    { name = "test", command = "my-test-runner" }
  }
end

-- Register the adapter
local registry = require("hooks-util.core.registry")
registry.register(my_adapter)
```

### Config Module

```lua
local config = require("hooks-util.core.config")

-- Load configuration from file
config.load("/path/to/.hooks-util.lua")

-- Get configuration values
local project_type = config.get("project_type")
local lint_enabled = config.get("hooks.pre_commit.lint")

-- Set configuration values
config.set("test.timeout", 30000)

-- Save configuration to file
config.save_config("/path/to/.hooks-util.lua")
```

### Registry Module

```lua
local registry = require("hooks-util.core.registry")

-- Register an adapter
registry.register(adapter)

-- Get a specific adapter
local nvim_plugin = registry.get_adapter("nvim-plugin")

-- Get all registered adapters
local all_adapters = registry.get_adapters()

-- Detect the appropriate adapter for a project
local detected = registry.detect_adapter("/path/to/project")
```