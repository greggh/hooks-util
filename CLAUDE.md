# Hooks-Util Framework

## Configuration Overrides

The hooks-util framework uses an intelligent project type detection system to automatically identify different types of Lua projects:

- **neovim-config**: Neovim configuration directories with init.lua and specific Neovim directories/files
- **neovim-plugin**: Neovim plugin project with plugin/init.vim or lua/*/init.lua structure
- **lua-lib**: Lua library with rockspec files or certain directory structures
- **lua-project**: Generic Lua project not fitting other categories

By default, hooks-util will automatically detect your project type. If the detection doesn't correctly identify your project, you can override it by creating a `.hooks-util.lua` file in the root of your project:

```lua
-- hooks-util configuration file
return {
  -- Project type configuration
  -- Valid values:
  --   "auto"           - Automatically detect project type (default)
  --   "neovim-plugin"  - Neovim plugin project
  --   "neovim-config"  - Neovim configuration directory
  --   "lua-lib"        - Lua library
  --   "lua-project"    - Generic Lua project
  project_type = "neovim-plugin", -- Change from "auto" only if detection is incorrect
  
  -- Additional configuration options...
  hooks = {
    pre_commit = {
      lint = true,       -- Run linting
      format = true,     -- Run formatting
      test = true,       -- Run tests
    }
  }
}
```

You only need to change the `project_type` from "auto" if the automatic detection is incorrectly identifying your project.

## Useful Commands

### Installation Commands
- `git -C /path/to/project submodule add https://github.com/greggh/hooks-util.git .githooks/hooks-util` - Add as submodule
- `cd /path/to/project && .githooks/hooks-util/install.sh` - Install hooks in a project

### Git Commands
- `git -C /home/gregg/Projects/hooks-util status` - Check current status
- `git -C /home/gregg/Projects/hooks-util add .` - Stage all changes
- `git -C /home/gregg/Projects/hooks-util commit -m "message"` - Commit changes
- `git -C /home/gregg/Projects/hooks-util push` - Push changes

### Development Commands
- `stylua lua/ -c` - Check Lua formatting
- `stylua lua/` - Format Lua code
- `luacheck lua/` - Run Lua linter
- `/home/gregg/Projects/hooks-util/spec/runner.lua` - Run all tests with lust-next
- `/home/gregg/Projects/hooks-util/spec/runner.lua "core"` - Run core tests only
- `/home/gregg/Projects/hooks-util/spec/runner.lua "" "unit"` - Run tests with "unit" tag

## Testing Framework Integration

The hooks-util framework uses lust-next as its testing framework. The integration is implemented in `lua/hooks-util/lust-next.lua` and provides:

- Automatic test discovery and execution
- Project setup and configuration
- Test filtering and tagging support
- CI workflow generation for GitHub and GitLab
- Mocking and assertion utilities

### Test Structure
- `spec/` - Main test directory
- `spec/core/` - Tests for core modules
- `spec/adapters/` - Tests for adapter modules  
- `spec/spec_helper.lua` - Testing utilities and helpers
- `spec/runner.lua` - Main test runner using lust-next
- `spec/minimal_spec.lua` - Basic test to verify integration

### Testing Commands
- `/home/gregg/Projects/hooks-util/spec/runner.lua` - Run all tests with lust-next
- `/home/gregg/Projects/hooks-util/spec/runner.lua "core"` - Run core tests only
- `/home/gregg/Projects/hooks-util/spec/runner.lua "" "unit"` - Run tests with "unit" tag

### Test Implementation
Tests use the lust-next BDD-style syntax:
```lua
describe("component", function()
  it("should do something", function()
    -- Test code here
    assert(something, "message")
  end)
end)
```

Mocks and spies are available through the lust-next API, which is automatically exposed to test files by the runner.

### Lust-Next Integration Implementation
The integration of lust-next into hooks-util consists of several key components:

1. **Integration Module**: `lua/hooks-util/lust-next.lua` provides functions for:
   - Setting up lust-next in a project
   - Generating CI workflows for different platforms
   - Running tests with filtering and tagging
   - Adding lust-next as a dependency

2. **Runner Script**: `spec/runner.lua` handles:
   - Loading lust-next and setting up paths
   - Exposing lust-next functions as globals
   - Finding and running test files
   - Parsing command-line arguments for filtering

3. **Helper Module**: `spec/spec_helper.lua` provides:
   - Test setup and environment configuration
   - Mock object creation for testing
   - Module loading utilities
   - Path resolution that avoids hardcoded paths

4. **Core Tests**: Tests for core modules like:
   - `spec/core/registry_spec.lua` - Tests the adapter registry
   - `spec/core/config_spec.lua` - Tests the configuration system
   - `spec/adapters/adapter_spec.lua` - Tests the adapter system

## Architecture

The hooks-util framework uses an adapter-based architecture:

```
hooks-util/
├── core/              # Core functionality
│   ├── adapter.lua    # Adapter interface and utilities
│   ├── config.lua     # Configuration management
│   └── registry.lua   # Adapter registry
├── adapters/          # Project type adapters
│   ├── nvim-plugin/   # Neovim plugin adapter
│   ├── nvim-config/   # Neovim config adapter
│   └── lua-lib/       # Generic Lua library adapter
└── ci/                # CI platform implementations
    ├── github/        # GitHub Actions workflows
    ├── gitlab/        # GitLab CI configurations
    └── azure/         # Azure DevOps pipelines
```

### Features
- Lust-Next integration for standardized testing
- Linting configuration per project type
- Pre-commit hooks for version validation
- Multi-platform CI workflow templates
- Project type adapters for specific configurations
- Test quality validation (planned):
  - Test coverage threshold enforcement
  - Quality level verification (5 levels)
  - Configurable strictness per project type

### Project Structure
- `core/` - Core functionality shared across all project types
- `adapters/` - Project-specific adapters
- `ci/` - CI platform implementations
- `install.sh` - Main installation script
- `README.md` - Framework documentation
- `deps/lust-next/` - Lust-next testing framework as a submodule