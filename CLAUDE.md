
# Project: hooks-util

## Overview

Hooks-Util is a comprehensive Git hooks framework for pre-commit validation across Neovim ecosystem projects. It features an adapter-based architecture to support different project types with specialized configurations, intelligent project type detection, and integration with lust-next for test quality validation. The framework now includes comprehensive documentation linting tools and a workflow management system with a base+adapter architecture.

## Essential Commands

- Install Hooks: `env -C /path/to/project /home/gregg/Projects/lua-library/hooks-util/install.sh`
- Run Tests: `env -C /home/gregg/Projects/lua-library/hooks-util ./spec/runner.lua`
- Run Core Tests: `env -C /home/gregg/Projects/lua-library/hooks-util ./spec/runner.lua "core"`
- Run Adapter Tests: `env -C /home/gregg/Projects/lua-library/hooks-util ./spec/runner.lua "adapters"`
- Run Tests With Tag: `env -C /home/gregg/Projects/lua-library/hooks-util ./spec/runner.lua "" "unit"`
- Check Formatting: `env -C /home/gregg/Projects/lua-library/hooks-util stylua lua/ -c`
- Run Linter: `env -C /home/gregg/Projects/lua-library/hooks-util luacheck lua/`

## Project Structure

- `/core`: Core functionality (adapter.lua, config.lua, registry.lua, markdown.lua, yaml.lua, json.lua, toml.lua, workflows.lua)
- `/adapters`: Project type adapters (nvim-plugin, nvim-config, lua-lib, docs)
- `/ci`: CI platform implementations including base workflow templates and adapter configurations
- `/templates`: Configuration templates for linting tools
- `/scripts`: Utility scripts including markdown fixing tools
- `/spec`: Test files using lust-next integration
- `/deps`: Dependencies (lust-next as submodule)
- `/lib`: Shared utilities including yaml_util.lua for workflow merging
- `install.sh`: Enhanced installation script with documentation tool and workflow support

## Current Focus

- Completing comprehensive testing with all testbed projects to validate every adapter type:
  - Test lua-lib adapter with hooks-util-testbed-lua-lib
  - Test nvim-plugin adapter with hooks-util-testbed-nvim-plugin
  - Test nvim-config adapter with hooks-util-testbed-nvim-config
- Verifying all adapter-specific validations and workflows
- Testing edge cases in the submodule update mechanism
- Only after thorough testing, updating base-project-repo with the enhanced hooks-util
- Preparing comprehensive integration tests for production environments

## Documentation Links

- Tasks: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/tasks/hooks-util-tasks.md`
- Architecture: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/plans/hooks-util-architecture.md`
- Adapter Specification: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/specs/adapter-architecture.md`
- Test Quality Levels: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/specs/test-quality-levels.md`
